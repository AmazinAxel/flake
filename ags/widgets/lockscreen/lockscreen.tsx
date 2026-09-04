import { Gtk } from 'ags/gtk4';
import Auth from 'gi://AstalAuth';
import SessionLock from 'gi://Gtk4SessionLock';
import GLib from 'gi://GLib';
import Gdk from 'gi://Gdk';
import { createPoll, timeout } from 'ags/time';
import { execAsync } from 'ags/process';
import { createState, createRoot } from 'ags';
import { playlistName } from '../../lib/mediaPlayer';

const [ authFailed, setAuthFailed ] = createState(false);
const time = createPoll('', 1000, () => GLib.DateTime.new_now_local().format('%H\n%M'));

let lock: SessionLock.Instance | null = null;

const hiddenCursor = Gdk.Cursor.new_from_texture( // no cursor
    Gdk.MemoryTexture.new(1, 1, Gdk.MemoryFormat.R8G8B8A8, GLib.Bytes.new(new Uint8Array([0, 0, 0, 0])), 4),
    0, 0, null,
);

const lockCss = new Gtk.CssProvider();
Gtk.StyleContext.add_provider_for_display(
    Gdk.Display.get_default()!, lockCss, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
playlistName.subscribe(() => lockCss.load_from_string(`#lockscreen entry { background-image: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.5)), url("file:///home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg"); }`))

const checkLogin = (entry: Gtk.Entry) => {
    const password = entry.get_text();
    entry.set_text('');
    entry.set_sensitive(false);

    Auth.Pam.authenticate(password, (_, task) => {
        try {
            Auth.Pam.authenticate_finish(task);
            unlockScreen();
        } catch { // Wrong password
            setAuthFailed(true);
            GLib.idle_add(GLib.PRIORITY_DEFAULT, () => (entry.grab_focus(), GLib.SOURCE_REMOVE));
        };
        entry.set_sensitive(true);
    });
};

const handleKeys = (entry: Gtk.Entry, key: number, state: Gdk.ModifierType) => {
    if (key == 65379) return true; // Insert
    if (!(state & Gdk.ModifierType.CONTROL_MASK)) return false;

    switch (key) {
        case 115: // S - sleep
            execAsync('systemctl suspend');
            break;
        case 104: // H - hibernate
            execAsync('systemctl hibernate');
            break;
        case 113: // Q - power off
            execAsync('systemctl poweroff');
            break;
        case 99: // C - clear input
            break;
        case 86: // V - do not paste from clipboard
        case 118:
            return true;
        default: return false;
    };

    entry.set_text(''); // wipe anything typed
    return true;
};

const assignLockWindow = (monitor: Gdk.Monitor) =>
    createRoot((dispose) => {
        const win = new Gtk.Window({ name: 'lockscreen', cursor: hiddenCursor });
        win.connect('destroy', dispose);

        let entry: Gtk.Entry;
        win.set_child(
            <overlay>
                <Gtk.EventControllerKey
                    propagationPhase={Gtk.PropagationPhase.CAPTURE}
                    onKeyPressed={(_ctrl, key, _keycode, state) => handleKeys(entry, key, state)}
                />
                <label
                    halign={Gtk.Align.CENTER}
                    valign={Gtk.Align.CENTER}
                    useMarkup={true}
                    label={time((t) =>  `<span line_height="0.75">${t}</span>`)}
                    css_classes={authFailed((v) => v ? ['failed'] : [])}
                    canTarget={false}
                    $type="overlay"
                />
                <entry
                    hexpand
                    vexpand
                    visibility={false}
                    invisibleChar={0}
                    onActivate={checkLogin}
                    onNotifyText={(self) => self.get_text() && setAuthFailed(false)} // typing clear error
                    $={(self) => (entry = self, self.connect('map', () => self.grab_focus()))}
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
