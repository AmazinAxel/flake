import { createPoll } from 'ags/time';
import GLib from 'gi://GLib';
import { Gdk, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
const curr = GLib.DateTime.new_now_local();
const month = curr.format('%m')!;
const day = curr.format('%d')!;
const dayName = curr.format('%a')!;
const time = createPoll('', 1000, () => GLib.DateTime.new_now_local().format('%H\n%M'))

export const Time = () =>
  <button
    onClicked={() => {
      app.get_window("quickSettings")?.hide();
      app.toggle_window("calendar");
    }}
    cssClasses={['time', 'timeBtn']}
    cursor={Gdk.Cursor.new_from_name('pointer', null)}
  >
    <box orientation={Gtk.Orientation.VERTICAL} hexpand>
      <label cssClasses={['date']} label={month}/>
      <label cssClasses={['date', 'bottom']} label={day}/>

      <label cssClasses={['time']} label={time((time) => time!.toString())} />

      <label cssClasses={['day']} label={dayName}/>
    </box>
  </button>
