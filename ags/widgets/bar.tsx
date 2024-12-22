// @ts-nocheck TODO fix types

import { Tray, trayVisible } from "./Tray";
import Time from "./Time";
import Media from "./Media";

import { App, Astal } from "astal/gtk3";
import { bind, execAsync } from "astal";

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
        1
        {/* TODO sway integration
        <box className="container">
          
        </box>*/}


        <box vertical vexpand hexpand />
        2

        {/* <box className="Container">
          <Media />
        </box> */}

        <box className="Container">
        3
          {/*<button
            className={"VerticalButton"}
            onClick={() => {
              execAsync("ags request 'pane datemenu'");
            }}
          >
            <Time />
          </button>*/}
        </box>

        <box className="Container">
        4aa
          {/* control center:
          battery power, bluetooth, sound, DND */}
        </box>
      </box>
    </window>
  );
}