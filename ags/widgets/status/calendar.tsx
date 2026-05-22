import { Gtk } from 'ags/gtk4';
import GLib from 'gi://GLib';
import { currentAsideWindow } from '../../lib/asideStatusWindow';

export default () =>
    <Gtk.Calendar $={(self) => {
        currentAsideWindow.subscribe(() => {
            if (currentAsideWindow.peek() !== 'calendar') return;
            self.select_day(GLib.DateTime.new_now_local());

            // very hacky workaround to focus first calendar child
            // todo better way to do it?
            let w: Gtk.Widget | null = self.get_first_child();
            while (w && !(w instanceof Gtk.Button)) w = w.get_first_child();
            w?.grab_focus();
        });
    }}/>
