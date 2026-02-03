import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
import { Time } from './modules/time';
import { Workspaces } from './modules/workspaces';
import { Status } from './modules/statusMenu';
import { Mpris } from './modules/mpris';
import { Media } from '../../lib/mediaPlayer';
import { RecordingIndicator } from '../record/record';
import { createBinding, For, onCleanup, This } from "ags";
const { TOP, BOTTOM, LEFT } = Astal.WindowAnchor;
const monitors = createBinding(app, "monitors");

export default () =>
  <For each={monitors}>
    {(monitor) => <This this={app}>
      <window
        name="bar"
        gdkmonitor={monitor}
        exclusivity={Astal.Exclusivity.EXCLUSIVE}
        anchor={TOP | BOTTOM | LEFT}
        $={(self) => onCleanup(() => self.destroy())}
        application={app}
        visible//={barVisibility}
      >
        <box orientation={Gtk.Orientation.VERTICAL}>
          <Workspaces/>

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
    </This>}
  </For>;