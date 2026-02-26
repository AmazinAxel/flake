import { createPoll } from 'ags/time';
import GLib from 'gi://GLib';
import { Gtk } from 'ags/gtk4';

const getDateTime = () => GLib.DateTime.new_now_local();
const month = createPoll('', 3600000, () => getDateTime().format("%m")!);
const day = createPoll('', 3600000, () => getDateTime().format("%d")!);
const dayName = createPoll('', 3600000, () => getDateTime().format("%a")!);
const time = createPoll('', 1000, () => getDateTime().format('%H\n%M')!);

export const Time = () =>
  <box orientation={Gtk.Orientation.VERTICAL} hexpand>
    <label cssClasses={['date']} label={month}/>
    <label cssClasses={['date', 'bottom']} label={day}/>
    <label cssClasses={['time']} label={time} />
    <label cssClasses={['day']} label={dayName}/>
  </box>
