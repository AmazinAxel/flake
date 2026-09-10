import Wp from 'gi://AstalWp';
import { createBinding, createComputed, createState, For } from "ags"
import { Gtk } from 'ags/gtk4';
import Gdk from "gi://Gdk"
import { subprocess } from 'ags/process';

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

const COMBINED = 'Bluetooth combined output';
const isCombined = (s: Wp.Endpoint) => s.description == COMBINED || s.name == COMBINED;
const [ extras, setExtras ] = createState<string[]>([]);
const loopbacks = new Map<string, ReturnType<typeof subprocess>>();

const startLoopback = (sink: Wp.Endpoint, combinedSerial: number) => {
    const key = sink.description;
    if (loopbacks.has(key)) return;

    const vol = Number(sink.volume);
    const proc = subprocess([
        'pw-loopback',
        '-C', String(combinedSerial),
        '-P', String(sink.serial),
        '--capture-props=' + JSON.stringify({
            'stream.capture.sink': true,
            'node.passive': true
        }),
        '--playback-props=' + JSON.stringify({
            'channelVolumes': [ vol, vol ],
            'resample.quality': 10 // better quality!
        })
    ], () => {});

    proc.connect('exit', () => { // device dropped!!!
        if (loopbacks.get(key) != proc) return; // superseded by stopLoopback
        loopbacks.delete(key);

        // if the other sink is available use that!
        const survivors = [...loopbacks.keys()];
        if (survivors.length > 0) return applySelection(survivors);

        // otherwise fall back to some other output like the speakers
        const fallback = audio.speakers.find(s => !isCombined(s));
        if (fallback) applySelection([ fallback.description ]);
    });
    loopbacks.set(key, proc);
};

const stopLoopback = (key: string) => {
    const proc = loopbacks.get(key);
    if (!proc) return;
    loopbacks.delete(key);
    proc.kill(); // dont need it anymore
};

const applySelection = (names: string[]) => {
    if (names.length == 0) return;

    const sinkFor = (n: string) => audio.speakers.find((s: Wp.Endpoint) => s.description == n);

    if (names.length == 1) { // don't use a combined sink, just a normal one works!
        const only = sinkFor(names[0]);
        if (!only) return; // tear nothing down if the target disappears
        for (const key of [...loopbacks.keys()]) stopLoopback(key);
        only.isDefault = true;
        setExtras([]);
    } else {
        const combined = audio.speakers.find(isCombined);
        if (!combined) return;

        for (const key of [...loopbacks.keys()])
            if (!names.includes(key)) stopLoopback(key);

        for (const name of names) {
            const sink = sinkFor(name);
            if (sink) startLoopback(sink, combined.serial);
        }
        if (loopbacks.size == 0) return;

        combined.isDefault = true;
        setExtras([...loopbacks.keys()]);
    }
};

// bind
const selected = createComputed((track) => {
    const mixed = track(extras);
    if (mixed.length > 0) return mixed;

    track(speakersBind);
    const def = track(defaultSpeaker);
    if (!def) return [];
    const description = track(createBinding(def, 'description'));
    return description && !isCombined(def) ? [ description ] : [];
});

// shift+enter / enter
const toggleSink = (sink: Wp.Endpoint) => {
    const current = selected.get();
    if (!current.includes(sink.description)) return applySelection([...current, sink.description]);
    if (current.length > 1) applySelection(current.filter(n => n != sink.description));
};

export const SinkSelector = () =>
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['sinkSelector']}
        $={(self) => { self.connect('map', () => self.get_first_child()?.grab_focus()); }}
    >
        <For each={speakersBind(all => all.filter(s => !isCombined(s)))}>
            {(speaker) => {
                const isSelected = selected(names => names.includes(speaker.description));
                return <button
					onClicked={() => applySelection([ speaker.description ])}
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
