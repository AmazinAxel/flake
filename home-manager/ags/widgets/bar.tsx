import { App, Astal, Gdk } from 'astal/gtk3';
import { Time } from './modules/time';
import { Workspaces } from './modules/workspaces'
import { Status } from './modules/statusmenu'
import { Media } from './modules/media'
import { RecordingIndicator } from '../services/screen';
import { BatteryWidget } from './modules/battery';
export default function bar(gdkmonitor: Gdk.Monitor) {
    return (
    <window
      className="bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.BOTTOM}
      application={App}
    >
      <box vertical hexpand>
        <Workspaces/>

        <box vertical vexpand hexpand/>

        <Media/>

        <box vertical vexpand hexpand/>

        <RecordingIndicator/>
        <BatteryWidget/>
        <Time/>
        <Status/>
      </box>
    </window>
  );
}
