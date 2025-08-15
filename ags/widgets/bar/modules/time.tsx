//import { Variable } from 'astal'; // todo
import GLib from 'gi://GLib';
import { Gdk, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
const curr = GLib.DateTime.new_now_local();
const date = curr.format('%m/%d')!;
const day = curr.format('%a')!;
const time = Variable<string>('').poll(1000,
  () => GLib.DateTime.new_now_local().format('%H\n%M')!
);

export const Time = () =>
  <button
    onActivate={() => {
      app.get_window("quickSettings")?.hide();
      app.toggle_window("calendar");
    }}
    cssClasses={['time', 'timeBtn']}
    cursor={Gdk.Cursor.new_from_name('pointer', null)}
  >
    <box orientation={Gtk.Orientation.VERTICAL} hexpand>
      <label cssClasses={['date']} label={date}/>
      <label cssClasses={['time']} label={time()}/>
      <label cssClasses={['day']} label={day}/>
    </box>
  </button>
