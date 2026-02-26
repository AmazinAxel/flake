import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Auth from 'gi://AstalAuth';
import { createPoll } from 'ags/time';
import GLib from 'gi://GLib';
import { createBinding, createState, For, This } from 'ags';
import { playlistName } from '../../lib/mediaPlayer';
const monitors = createBinding(app, "monitors");

export const [ isLocked, setIsLocked ] = createState(true);

const [ isAuthenticating, setIsAuthenticating ] = createState(false);
const time = createPoll('', 1000, () => GLib.DateTime.new_now_local().format('%H\n%M'));

playlistName.subscribe(() => app.apply_css(`#lockscreen entry { background-image: linear-gradient(rgba(0, 0, 0, 0.5), rgba(0, 0, 0, 0.5)), url("file:///home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg"); }`))

const checkLogin = (entry: Gtk.Entry) => {
    const password = entry.get_text();
    entry.set_text('');
    entry.set_sensitive(false);
    setIsAuthenticating(true);

    Auth.Pam.authenticate(password, (_, task) => {
        try {
            Auth.Pam.authenticate_finish(task);
            setIsLocked(false);
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
    <For each={monitors}>
        {(monitor) => <This this={app}>
            <window
                name="lockscreen"
                application={app}
                gdkmonitor={monitor}
                layer={Astal.Layer.OVERLAY}
                exclusivity={Astal.Exclusivity.IGNORE}
                keymode={Astal.Keymode.EXCLUSIVE}
                anchor={Astal.WindowAnchor.TOP | Astal.WindowAnchor.BOTTOM | Astal.WindowAnchor.LEFT | Astal.WindowAnchor.RIGHT}
                visible={isLocked}
            >
                <overlay>
                    <label
                        halign={Gtk.Align.CENTER}
                        valign={Gtk.Align.CENTER}
                        useMarkup={true}
                        label={time((t) => '<span line_height="0.75">' + t + '</span>')}
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
                            self.connect('map', () => self.grab_focus());
                            app.connect('window-toggled', (_, window) =>
                                (window.name === 'lockscreen' && window.visible)
                                && self.grab_focus()
                            )}}
                    />
                </overlay>
            </window>
        </This>}
    </For>;