import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Auth from 'gi://AstalAuth';
import SessionLock from 'gi://Gtk4SessionLock';
import GLib from 'gi://GLib';
import Gdk from 'gi://Gdk';
import { createPoll, timeout } from 'ags/time';
import { execAsync } from 'ags/process';
import { createState, createRoot } from 'ags';
import { playlistName } from '../../lib/mediaPlayer';

const [ isAuthenticating, setIsAuthenticating ] = createState(false);
const time = createPoll('', 1000, () => GLib.DateTime.new_now_local().format('%H\n%M'));

let lock: SessionLock.Instance | null = null;

const hiddenCursor = Gdk.Cursor.new_from_texture( // no cursor
    Gdk.MemoryTexture.new(1, 1, Gdk.MemoryFormat.R8G8B8A8, GLib.Bytes.new(new Uint8Array([0, 0, 0, 0])), 4),
    0, 0, null,
);

playlistName.subscribe(() => app.apply_css(`#lockscreen entry { background-image: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.5)), url("file:///home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg"); }`))

const checkLogin = (entry: Gtk.Entry) => {
    const password = entry.get_text();
    entry.set_text('');
    entry.set_sensitive(false);
    setIsAuthenticating(true);

    Auth.Pam.authenticate(password, (_, task) => {
        try {
            Auth.Pam.authenticate_finish(task);
            unlockScreen();
        } catch { // Wrong password
            GLib.idle_add(GLib.PRIORITY_DEFAULT, () => (entry.grab_focus(), GLib.SOURCE_REMOVE));
        };
        entry.set_sensitive(true);
        setIsAuthenticating(false);
    });
};

const assignLockWindow = (monitor: Gdk.Monitor) =>
    createRoot((dispose) => {
        const win = new Gtk.Window({ name: 'lockscreen', cursor: hiddenCursor });
        win.connect('destroy', dispose);
        win.set_child(
            <overlay>
                <label
                    halign={Gtk.Align.CENTER}
                    valign={Gtk.Align.CENTER}
                    useMarkup={true}
                    label={time((t) =>  `<span line_height="0.75">${t}</span>`)}
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
                    $={(self) => self.connect('map', () => self.grab_focus())}
                />
                <box
                    hexpand
                    vexpand
                    $type="overlay"
                    $={(self) => self.set_cursor(hiddenCursor)}
                />
            </overlay> as Gtk.Widget
        );
        lock!.assign_window_to_monitor(win, monitor);
    });

export const lockScreen = () => {
    if (lock) return; // Already locked?

    lock = SessionLock.Instance.new();
    lock.connect('failed', () => lock = null);
    lock.connect('unlocked', () => lock = null);

    lock.connect('monitor', (_, monitor: Gdk.Monitor) => assignLockWindow(monitor));

    if (!lock.lock()) return void (lock = null);

    // move cursor up a pixel so that it updates and disappears
    timeout(120, () => execAsync('swaymsg -- seat - cursor move 1 1, seat - cursor move -1 -1').catch(() => {}));
};

export const unlockScreen = () => {
    lock?.unlock();
    lock = null;
};
