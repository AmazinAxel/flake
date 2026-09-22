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
    if (name.includes('HD Audio Controller')) return name.split(' ').pop()!; // 'Speaker' or 'Headphones'
    if (name.includes('HDMI')) return 'Monitor'; // monitor has a speaker
    return name;
};

const speakersBind = createBinding(audio, 'speakers');

const COMBINED = 'combined-bt-sink';
const isCombined = (s: Wp.Endpoint) => nodeName(s) == COMBINED;

const nodeName = (s: Wp.Endpoint) =>
    s.get_pw_property('node.name') ?? String(s.serial);

const isBluetooth = (s: Wp.Endpoint) => nodeName(s).startsWith('bluez_');
let linked: string[] = [];

const link = (target: string, connect: boolean) => {
    try {
        exec([ 'pw-link', ...(connect ? [] : [ '-d' ]), COMBINED, target ]);
    } catch { /* sink vanished mid-switch; wire() prunes it */ }
};

const [ selected, setSelected ] = createState<string[]>([]);

const resolve = (names: string[]) => {
    const byName = new Map(audio.speakers.map(s => [ nodeName(s), s ]));
    return [ ...new Set(names) ].flatMap(n => byName.get(n) ?? []);
};

const applySelection = (names: string[]) => {
    const sinks = resolve(names);
    if (!sinks.length) return reconcileNow();

    const combined = audio.speakers.find(isCombined);
    const want = sinks.length > 1 && combined ? sinks.map(nodeName) : [];

    for (const t of linked) if (!want.includes(t)) link(t, false);
    for (const n of want) if (!linked.includes(n)) link(n, true);
    linked = want;

    const target = want.length ? combined! : sinks[0];
    target.isDefault = true;
    setSelected(want.length ? want : [ nodeName(sinks[0]) ]);
};

const reconcileNow = () => {
    if (linked.length > 1) return setSelected(linked);

    const def = audio.defaultSpeaker;
    if (def && !isCombined(def)) return setSelected([ nodeName(def) ]);

    const real = audio.speakers.find(s => !isCombined(s) && !isBluetooth(s))
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

const watched = new Map<string, [ Wp.Endpoint, number ]>();
let firstWire = true;
const wire = () => {
    const wasFirst = firstWire;
    const present = new Set(audio.speakers.map(nodeName));

    for (const [ name, [ sink, id ] ] of watched)
        if (!present.has(name)) {
            sink.disconnect(id);
            watched.delete(name);
        }

    let fresh: Wp.Endpoint | null = null;
    for (const s of audio.speakers) {
        const name = nodeName(s);
        if (watched.has(name)) continue;
        watched.set(name, [ s, s.connect('notify::is-default', reconcile) ]);
        if (isBluetooth(s)) fresh = s;
    }

    const survivors = linked.filter(n => present.has(n));
    const collapsed = survivors.length != linked.length;
    if (collapsed) {
        linked = [];
        for (const n of survivors) link(n, false);
    }
    firstWire = false;
    if (collapsed && survivors.length) return applySelection(survivors);

    if (fresh && !wasFirst && linked.length < 2) applySelection([ nodeName(fresh) ]);
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

const shiftEnter = (fn: () => void) => (self: Gtk.Widget) => {
    const key = new Gtk.EventControllerKey();
    key.propagation_phase = Gtk.PropagationPhase.CAPTURE;
    key.connect('key-pressed', (_, keyval, __, mod) => {
        const enter = keyval == Gdk.KEY_Return || keyval == Gdk.KEY_KP_Enter;
        if (!enter || !(mod & Gdk.ModifierType.SHIFT_MASK)) return false;
        fn();
        return true;
    });
    self.add_controller(key);
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
					$={shiftEnter(() => toggleSink(speaker))}
				>
                    <box>
                        <image visible={isSelected} iconName="emblem-default-symbolic" marginEnd={7}/>
                        <label halign={Gtk.Align.START} hexpand label={nameSubstitute(speaker.description)}/>
                    </box>
                </button>
            }}
        </For>
    </box>
