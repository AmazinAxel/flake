// @ts-nocheck TODO fix types
import { Variable, GLib } from "astal";
import { Gtk } from "astal/gtk3"

const date = GLib.DateTime.new_now_local().format("%m/%d")!;
const time = Variable<string>("").poll(1000,
  () => GLib.DateTime.new_now_local().format("%H\n%M")!
);
  
export const Time = () => {
  const onClicked = () => {
    console.log("TODO open calendar");
  };

  return (
    <button onClicked={onClicked} className="time" cursor="pointer">
      <box vertical>
        <label className="date" label={date}/>
        <label className="time" label={time()} />
      </box>
    </button>
  );
};
  