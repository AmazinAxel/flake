import { createState } from 'ags';
import GLib from 'gi://GLib';
import { Gtk } from 'ags/gtk4';

const [ now, setNow ] = createState(GLib.DateTime.new_now_local());

const scheduleMinuteTick = () => {
  const t = GLib.DateTime.new_now_local();
  const msToNextMinute = (60 - t.get_second()) * 1000 - Math.floor(t.get_microsecond() / 1000);
  GLib.timeout_add(GLib.PRIORITY_DEFAULT, Math.max(1, msToNextMinute), () => {
    setNow(GLib.DateTime.new_now_local());
    scheduleMinuteTick();
    return GLib.SOURCE_REMOVE;
  });
};
scheduleMinuteTick();

const fmt = (f: string) => now((d) => d.format(f)!);

export const Time = () =>
  <box orientation={Gtk.Orientation.VERTICAL} hexpand cssClasses={['time', 'timeSection']}>
    <label cssClasses={['date']} label={fmt('%m')}/>
    <label cssClasses={['date', 'bottom']} label={fmt('%d')}/>
    <label cssClasses={['time']} label={fmt('%H\n%M')}/>
    <label cssClasses={['day']} label={fmt('%a')}/>
  </box>
