import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"

import { Time } from './modules/time';
import { Workspaces } from './modules/workspaces';
import { Status } from './modules/statusMenu';
import { Mpris } from './modules/mpris';
import { Media } from '../../services/mediaPlayer';
import { RecordingIndicator } from '../record/record';
const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor;

export default (monitor: number) =>
  <window
    name="bar"
    monitor={monitor}
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    anchor={TOP | BOTTOM | LEFT}
    application={app}
    visible
  >
    <box orientation={Gtk.Orientation.VERTICAL}>
      <Workspaces/>

      <box vexpand/>

      <box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.CENTER} cssClasses={['barElement']} name={'media'}>
        <Media/>
        <Mpris/>
      </box>

      <box vexpand/>

      <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['barElement']}>
        <RecordingIndicator/>
        <Time/>
        <Status/>
      </box>
    </box>
  </window>
