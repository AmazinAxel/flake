import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { Time } from './modules/time';
import { Status } from './modules/statusMenu';
import { Mpris } from './modules/mpris';
import { Media } from '../../lib/mediaPlayer';
import { RecordingIndicator } from '../record/record';
const { BOTTOM, LEFT } = Astal.WindowAnchor;

export default () =>
  <window
    name="bar"
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    anchor={BOTTOM | LEFT}
    layer={Astal.Layer.OVERLAY}
    application={app}
  >
    <box orientation={Gtk.Orientation.VERTICAL}>
      <box vexpand/>
      <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} cssClasses={['barElement']} name={'media'}>
        <Media/>
        <Mpris/>
      </box>

      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['barElement']}>
        <RecordingIndicator/>
        <Time/>
        <Status/>
      </box>
    </box>
  </window>
