import Wp from 'gi://AstalWp';
import app from 'ags/gtk4/app';
import { createBinding, With } from "ags"
import GLib from "gi://GLib"
import Gio from "gi://Gio"
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
		return String(name.split(' ').pop()); // Returns 'Speaker' or 'Headphones'
	} else if (name.includes('HDMI')) {
		return "Monitor"; // Monitor has a speaker
	} else if (name == 'K38') {
		return 'Bluetooth Speaker';
	};
	return name;
};

const speakersBind = createBinding(audio, 'speakers');
const selectedSpeakerBind = createBinding(speaker, 'description').as(nameSubstitute)

export const SinkSelector = () =>
	<box>
		<With value={speakersBind}>
			{(speakers) => {
				const menu = new Gio.Menu();
				speakers.forEach((speaker) => {
					const radioItem = new Gio.MenuItem();
					radioItem.set_label(nameSubstitute(speaker.description));
					radioItem.set_action_and_target_value('speakers.radio', GLib.Variant.new_string(speaker.description));
					menu.append_item(radioItem);
				})

				const radioAction = Gio.SimpleAction.new_stateful('radio', new GLib.VariantType('s'), GLib.Variant.new_string('speakers'))
				radioAction.activate(GLib.Variant.new_string(String(audio.get_default_speaker()?.description)))
				radioAction.connect("notify::state", (action: Gio.Action) =>
					speakers.forEach((speaker) =>
						(action.get_state()?.unpack() == speaker.description) && speaker.set_is_default(true)
					)
				);

				speaker.connect('notify', (source) =>
					(source.description) && (source.isDefault) && radioAction.set_state(GLib.Variant.new_string(source.description)
				));
				const button = <menubutton
					menuModel={menu}
					label={selectedSpeakerBind}
					cursor={Gdk.Cursor.new_from_name('pointer', null)}
					hexpand
				/>;

				const actionGroup = new Gio.SimpleActionGroup();
				actionGroup.add_action(radioAction);
				app.get_window('quickSettings')?.insert_action_group('speakers', actionGroup);

				return button;
			}}
		</With>
	</box>
