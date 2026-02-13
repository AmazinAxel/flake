import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Auth from 'gi://AstalAuth';
import { createPoll } from 'ags/time';
import GLib from 'gi://GLib';
import { createState } from 'ags';

const [ isAuthenticating, setIsAuthenticating ] = createState(false);
const time = createPoll('', 1000, () => GLib.DateTime.new_now_local().format('%H\n%M'));

const checkLogin = (entry: Gtk.Entry) => {
    const password = entry.get_text();
    entry.set_text('');
    entry.set_sensitive(false);
    setIsAuthenticating(true);

    Auth.Pam.authenticate(password, (_, task) => {
        try {
            Auth.Pam.authenticate_finish(task);
            app.get_window('lockscreen')?.hide();
        } catch { // Wrong password
            GLib.idle_add(GLib.PRIORITY_DEFAULT, () => {
                entry.grab_focus(); // Refocus
                return GLib.SOURCE_REMOVE;
            });
        };
        entry.set_sensitive(true);
        setIsAuthenticating(false);
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
        visible={true}
    >
        <overlay>
            <label
                halign={Gtk.Align.CENTER}
                valign={Gtk.Align.CENTER}
                label={time((time) => time!.toString())}
                css_classes={isAuthenticating((v) => v ? ['timeout'] : [])}
                canTarget={false}
                $type="overlay"
            />
            <entry
                hexpand
                vexpand
                visibility={false}
                invisibleChar={0}
                onActivate={checkLogin}
                $={(self) => {
                    app.connect('window-toggled', (_, window) =>
                        (window.name === 'lockscreen' && window.visible)
                        && self.grab_focus()
                    )}}
            />
        </overlay>
    </window>
