import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { Time } from './modules/time';
import { Status } from './modules/statusMenu';
import { Mpris } from './modules/mpris';
import { Media } from '../../lib/mediaPlayer';
import { RecordingIndicator } from '../record/record';
import Wp from "gi://AstalWp";

const { BOTTOM, LEFT } = Astal.WindowAnchor;
const speaker = Wp.get_default()?.audio.defaultSpeaker!;

export default () =>
  <window
    name="bar"
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    anchor={BOTTOM | LEFT}
    layer={Astal.Layer.OVERLAY}
    application={app}
  >
    <box orientation={Gtk.Orientation.VERTICAL}>
      <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} cssClasses={['barElement']} name={'media'}>
        <Media/>
        <Mpris/>
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['barElement', 'infoCenter']}>
        <Gtk.EventControllerScroll
          flags={Gtk.EventControllerScrollFlags.VERTICAL}
          onScroll={(_, __, y) => { speaker.volume = (y < 0) ? speaker.volume + 0.05 : speaker.volume - 0.05 }}
        />
        <RecordingIndicator/>
        <Time/>
        <Status/>
      </box>
    </box>
  </window>
