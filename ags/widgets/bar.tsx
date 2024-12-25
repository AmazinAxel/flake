// @ts-nocheck TODO fix types

import { Tray, trayVisible } from "./Tray";
import { Workspaces } from "./workspaces";
import { App, Astal } from "astal/gtk3";
import { bind, execAsync } from "astal";
import { Time } from "./modules/time";

export default function bar(gdkmonitor: Gdk.Monitor) {
    return (
    <window
      className="bar"
      gdkmonitor={gdkmonitor}
      exclusivity={Astal.Exclusivity.EXCLUSIVE}
      anchor={
        Astal.WindowAnchor.LEFT |
        Astal.WindowAnchor.TOP |
        Astal.WindowAnchor.BOTTOM
      }
      application={App}
    >
      <box vertical hexpand>
        <box className="container">
          <Workspaces/>
        </box>


        <box vertical vexpand hexpand />
        

        {/* <box className="Container">
          <Media />
        </box> */}

        <box className="Container">
        
          <Time/>
        </box>

        <box className="Container">
        
          {/* control center:
          battery power, bluetooth, sound, DND */}
        </box>
      </box>
    </window>
  );
}