import Wp from 'gi://AstalWp';
import { createBinding, createComputed, createState, For } from "ags"
import { Gtk } from 'ags/gtk4';
import Gdk from "gi://Gdk"
import { exec, execAsync } from 'ags/process';
import { timeout } from 'ags/time';

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

const ports = (name: string, dir: 'monitor' | 'playback') =>
    [ `${name}:${dir}_FL`, `${name}:${dir}_FR` ];

const linkedSinks = (): string[] => {
    let out = '';
    try {
        out = exec([ 'pw-link', '-l' ]);
    } catch { return []; }

    const found = new Set<string>();
    let onMonitor = false;
    for (const line of out.split('\n')) {
        if (!/^\s/.test(line)) { // a port header, not a link line
            onMonitor = line.startsWith(`${COMBINED}:monitor_`);
            continue;
        }
        if (!onMonitor) continue;
        const peer = line.replace(/^\s*\|->\s*/, '').trim();
        if (!peer.includes(':')) continue;
        const node = peer.slice(0, peer.lastIndexOf(':'));
        if (node != COMBINED && audio.speakers.some(s => nodeName(s) == node))
            found.add(node);
    }
    return [...found];
};

const link = (target: string, connect: boolean) => {
    const args = connect ? [] : [ '-d' ];
    ports(COMBINED, 'monitor').forEach((src, i) =>
        execAsync([ 'pw-link', ...args, src, ports(target, 'playback')[i] ])
            .catch(() => {})
    );
};

const applySelection = (names: string[]) => {
    const byName = (n: string) => audio.speakers.find(s => nodeName(s) == n);

    names = [...new Set(names.filter(byName))];
    if (names.length == 0) { // fallback
        const fallback = audio.speakers.find(s => !isCombined(s));
        if (!fallback) return;
        names = [ nodeName(fallback) ];
    }

    const live = linkedSinks();
    if (names.length == 1) { // no comb
        for (const t of live) link(t, false);
        byName(names[0])!.isDefault = true;
    } else {
        if (!audio.speakers.some(isCombined)) return;
        for (const t of live) if (!names.includes(t)) link(t, false);
        for (const n of names) if (!live.includes(n)) link(n, true);
        audio.speakers.find(isCombined)!.isDefault = true;
    }
    setSelection(names.length > 1 ? names : []);
};

const [ selection, setSelection ] = createState<string[]>([]);

const reconcile = () => {
    const def = audio.defaultSpeaker;
    const live = linkedSinks();
    setSelection(live.length > 1 ? live : []);

    if (!def || !isCombined(def)) return;
    if (live.length > 0) return;

    const wired = audio.speakers.find(s =>
        !isCombined(s) && !nodeName(s).startsWith('bluez_'));
    const real = wired ?? audio.speakers.find(s => !isCombined(s));
    if (real) real.isDefault = true;
};

speakersBind.subscribe(reconcile);
defaultSpeaker.subscribe(reconcile);

timeout(1500, reconcile);

const selected = createComputed((track) => {
    const ours = track(selection);
    if (ours.length > 0) return ours;

    const def = track(defaultSpeaker);
    return def && !isCombined(def) ? [ nodeName(def) ] : [];
});

const toggleSink = (sink: Wp.Endpoint) => {
    const current = selected.get();
    const name = nodeName(sink);
    if (!current.includes(name)) return applySelection([ ...current, name ]);
    if (current.length > 1) applySelection(current.filter(n => n != name));
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
				>
                    <Gtk.EventControllerKey onKeyPressed={(_, key, __, mod) => {
                        if ((key == 65293 || key == 65421) && (mod & Gdk.ModifierType.SHIFT_MASK)) { // Add it
                            toggleSink(speaker);
                            return true;
                        }
                        return false;
                    }}/>
                    <box>
                        <image visible={isSelected} iconName="emblem-default-symbolic" marginEnd={7}/>
                        <label halign={Gtk.Align.START} hexpand label={nameSubstitute(speaker.description)}/>
                    </box>
                </button>
            }}
        </For>
    </box>
