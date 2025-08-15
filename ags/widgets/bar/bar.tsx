import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"

import { Time } from './modules/time';
import { Workspaces } from './modules/workspaces';
import { Status } from './modules/statusMenu';
import { Mpris } from './modules/mpris';
import { Media } from '../../services/mediaPlayer';
import { RecordingIndicator } from '../../services/screenRecord';
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

      <Media/>
      <Mpris/>

      <box vexpand/>

      <RecordingIndicator/>
      <Time/>
      <Status/>
    </box>
  </window>
