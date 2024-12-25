// @ts-nocheck TODO fix types
import { Variable, GLib } from "astal";
import { Gtk } from "astal/gtk3"
import Bluetooth from "gi://AstalBluetooth";

const bluetooth = Bluetooth.get_default()

const date = GLib.DateTime.new_now_local().format("%m/%d")!;
const btIsPowered = Variable<string>("").poll(1000,
  () => bluetooth.get_is_powered()
);

const btIsConnected = Variable<string>("").poll(1000,
    () => bluetooth.get_is_connected()
  );
  
export const Time = () => {
  const onClicked = () => {
    console.log("TODO open quicksettings");
  };

  return (
    <button onClicked={onClicked} className="time" cursor="pointer">
      <box vertical>
        <label className="date" label={date}/>
        <label className="time" label={time()}/>
      </box>
    </button>
  );
};
  