import { createPoll } from 'ags/time';
import GLib from 'gi://GLib';
import { Gdk, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'

const getDateTime = () => GLib.DateTime.new_now_local();
const month = createPoll('', 3600000, () => getDateTime().format("%m")!);
const day = createPoll('', 3600000, () => getDateTime().format("%d")!);
const dayName = createPoll('', 3600000, () => getDateTime().format("%a")!);
const time = createPoll('', 1000, () => getDateTime().format('%H\n%M'))

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
