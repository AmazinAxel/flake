import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import GLib from 'gi://GLib';
import asideStatusWindow from '../../lib/asideStatusWindow';

export default () => asideStatusWindow('calendar', () =>
    <Gtk.Calendar $={(self) => {
        app.connect('window-toggled', () => {
            if (!app.get_window('calendar')?.visible) return;
            self.select_day(GLib.DateTime.new_now_local());

            // very hacky workaround to focus first calendar child
            let w: Gtk.Widget | null = self.get_first_child();
            while (w && !(w instanceof Gtk.Button)) w = w.get_first_child();
            w?.grab_focus();
        });
    }}/>
);
