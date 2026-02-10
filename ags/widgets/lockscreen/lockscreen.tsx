import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Auth from 'gi://AstalAuth';
import { createPoll } from 'ags/time';
import GLib from 'gi://GLib';

const time = createPoll('', 1000, () => GLib.DateTime.new_now_local().format('%H\n%M'))

const authenticate = (entry: Gtk.Entry) => {
    const password = entry.get_text();
    entry.set_text('');
    entry.set_sensitive(false);

    Auth.Pam.authenticate(password, (_, task) => {
        try {
            Auth.Pam.authenticate_finish(task);
            app.get_window('lockscreen')?.hide();
        } catch (e) {
            entry.set_sensitive(true);
            entry.grab_focus();
        }
    });
};

export default () =>
    <window
        name="lockscreen"
        application={app}
        layer={Astal.Layer.OVERLAY}
        exclusivity={Astal.Exclusivity.IGNORE}
        keymode={Astal.Keymode.EXCLUSIVE}
        anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
        visible={false} // todo remove after finishing
    >
        <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} orientation={Gtk.Orientation.VERTICAL}>
            <label label={time((time) => time!.toString())} />
            <entry
                visibility={false}
                invisibleChar={0} // No character
                onActivate={(self) => authenticate(self)}
                $={(self) => {
                    app.connect('window-toggled', (_, window) =>
                        (window.name === 'lockscreen' && window.visible)
                        && self.grab_focus()
                )}}
            />
        </box>
    </window>
