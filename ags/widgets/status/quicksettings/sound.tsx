import Wp from 'gi://AstalWp';
import { createBinding, createComputed, createState, For } from "ags"
import { Gtk } from 'ags/gtk4';
import Gdk from "gi://Gdk"
import { exec } from 'ags/process';
import { timeout } from 'ags/time';
import GLib from 'gi://GLib';

const audio = Wp.get_default()?.audio!;

const defaultSpeaker = createBinding(audio, 'defaultSpeaker');

const trackSpeaker = <K extends 'volume' | 'volumeIcon'>(prop: K, fallback: Wp.Endpoint[K]) =>
    createComputed((track) => {
        const speaker = track(defaultSpeaker);
        return speaker ? track(createBinding(speaker, prop)) : fallback;
    });

export const VolumeSlider = () =>
    <box>
        <image iconName={trackSpeaker('volumeIcon', 'audio-volume-muted-symbolic')}/>
        <slider
            hexpand
            focusable={false}
            onChangeValue={({ value }) => {
                const speaker = audio.defaultSpeaker;
                if (!speaker) return;
                speaker.volume = value;
                speaker.mute = false;
            }}
            value={trackSpeaker('volume', 0)}
        />
    </box>

const nameSubstitute = (name: string) => {
	if (!name) return '';
	if (name.includes('HD Audio Controller')) {
		return String(name.split(' ').pop()); // returns 'Speaker' or 'Headphones'
	} else if (name.includes('HDMI')) {
		return "Monitor"; // Monitor has a speaker
	};
	return name;
};

const speakersBind = createBinding(audio, 'speakers');

const COMBINED = 'combined-bt-sink';
const isCombined = (s: Wp.Endpoint) => nodeName(s) == COMBINED;

const nodeName = (s: Wp.Endpoint) =>
    s.get_pw_property('node.name') ?? String(s.serial);

const linkedSinks = (): string[] | null => {
    let out = '';
    try {
        out = exec([ 'pw-link', '-l', `${COMBINED}:monitor_FL` ]);
    } catch { return null; }

    const names = new Set(audio.speakers.map(nodeName));
    return out.split('\n')
        .filter(l => l.includes('|->'))
        .map(l => l.slice(l.indexOf('|->') + 3, l.lastIndexOf(':')).trim())
        .filter(n => names.has(n));
};

const link = (target: string, connect: boolean): boolean => {
    try {
        exec([ 'pw-link', ...(connect ? [] : [ '-d' ]), COMBINED, target ]);
        return true;
    } catch { return false; }
};

const applySelection = (names: string[]) => {
    const byName = (n: string) => audio.speakers.find(s => nodeName(s) == n);
    const combined = audio.speakers.find(isCombined);

    names = [...new Set(names.filter(byName))];
    if (names.length > 1 && !combined) names = names.slice(0, 1);
    const want = names.length > 1 ? names : [];

    const live = linkedSinks();
    if (live != null) {
        let ok = true;
        for (const t of live) if (!want.includes(t)) ok = link(t, false) && ok;
        for (const n of want) if (!live.includes(n)) ok = link(n, true) && ok;
        const target = want.length ? combined! : byName(names[0]);
        if (ok && target) target.isDefault = true;
    }
    reconcileNow();
};

const [ selected, setSelected ] = createState<string[]>([]);

const reconcileNow = () => {
    const live = linkedSinks();
    if (live == null) return;
    if (live.length > 0) return setSelected(live);

    const def = audio.defaultSpeaker;
    if (def && !isCombined(def)) return setSelected([ nodeName(def) ]);

    const real = audio.speakers.find(s =>
            !isCombined(s) && !nodeName(s).startsWith('bluez_'))
        ?? audio.speakers.find(s => !isCombined(s));
    if (real) real.isDefault = true;
    else setSelected([]);
};

let queued = false;
const reconcile = () => {
    if (queued) return;
    queued = true;
    GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
        queued = false;
        reconcileNow();
        return GLib.SOURCE_REMOVE;
    });
};

defaultSpeaker.subscribe(reconcile);

const watched = new Set<string>();
const wire = () => {
    for (const s of audio.speakers)
        if (!watched.has(nodeName(s))) {
            watched.add(nodeName(s));
            s.connect('notify::is-default', reconcile);
        }
    reconcile();
};
speakersBind.subscribe(wire);

wire();
timeout(1500, wire);

const toggleSink = (sink: Wp.Endpoint) => {
    const current = selected.get();
    const name = nodeName(sink);
    applySelection(current.includes(name)
        ? current.filter(n => n != name)
        : [ ...current, name ]);
};

export const SinkSelector = () =>
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['sinkSelector']}
        $={(self) => { self.connect('map', () => self.get_first_child()?.grab_focus()); }}
    >
        <For each={speakersBind(all => all.filter(s => !isCombined(s)))}>
            {(speaker) => {
                const isSelected = selected(names => names.includes(nodeName(speaker)));
                return <button
					onClicked={() => applySelection([ nodeName(speaker) ])}
					cssClasses={isSelected(v => v ? ['active'] : [])}
					$={(self) => {
					    const key = new Gtk.EventControllerKey();
					    key.propagation_phase = Gtk.PropagationPhase.CAPTURE;
					    key.connect('key-pressed', (_, keyval, __, mod) => {
					        if ((keyval == Gdk.KEY_Return || keyval == Gdk.KEY_KP_Enter)
					            && (mod & Gdk.ModifierType.SHIFT_MASK)) {
					            toggleSink(speaker);
					            return true;
					        }
					        return false;
					    });
					    self.add_controller(key);
					}}
				>
                    <box>
                        <image visible={isSelected} iconName="emblem-default-symbolic" marginEnd={7}/>
                        <label halign={Gtk.Align.START} hexpand label={nameSubstitute(speaker.description)}/>
                    </box>
                </button>
            }}
        </For>
    </box>
