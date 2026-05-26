import Wp from 'gi://AstalWp';
import { createBinding, For } from "ags"
import { Gtk } from 'ags/gtk4';
import Gdk from "gi://Gdk"

const speaker = Wp.get_default()?.audio.defaultSpeaker!;
const audio = Wp.get_default()?.audio!;

const speakerIconBind = createBinding(speaker, 'volumeIcon');
const speakerVolumeBind = createBinding(speaker, 'volume');

export const VolumeSlider = () =>
    <box>
        <image iconName={speakerIconBind}/>
        <slider
            hexpand
            focusable={false}
            onChangeValue={({ value }) => {
                speaker.volume = value;
                speaker.mute = false;
            }}
            value={speakerVolumeBind}
        />
    </box>

const nameSubstitute = (name: string) => {
	if (!name) return '';
	if (name.includes('HD Audio Controller')) {
		return String(name.split(' ').pop()); // returns 'Speaker' or 'Headphones'
	} else if (name.includes('HDMI')) {
		return "Monitor"; // Monitor has a speaker
	} else if (name == 'K38') {
		return 'Bluetooth Speaker';
	} else if (name == 'S80A') {
		return 'Bluetooth Earbuds';
	};
	return name;
};

const speakersBind = createBinding(audio, 'speakers');

export const SinkSelector = () =>
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['sinkSelector']}
        $={(self) => { self.connect('map', () => self.get_first_child()?.grab_focus()); }}
    >
        <For each={speakersBind}>
            {(speaker) => {
                const isDefault = createBinding(speaker, 'isDefault');
                return <button
					onClicked={() => { speaker.isDefault = true; }}
					cursor={Gdk.Cursor.new_from_name('pointer', null)}
                    cssClasses={isDefault(v => v ? ['active'] : [])}
				>
                    <box>
                        <image visible={isDefault} iconName="emblem-default-symbolic" marginEnd={7}/>
                        <label halign={Gtk.Align.START} label={nameSubstitute(speaker.description)}/>
                    </box>
                </button>
            }}
        </For>
    </box>
