import { Gtk } from 'ags/gtk4';
import Auth from 'gi://AstalAuth';
import SessionLock from 'gi://Gtk4SessionLock';
import GLib from 'gi://GLib';
import Gdk from 'gi://Gdk';
import { createPoll, timeout } from 'ags/time';
import { execAsync } from 'ags/process';
import { createState, createRoot } from 'ags';
import { wallpaperTexture } from '../../lib/mediaPlayer';

const [ authFailed, setAuthFailed ] = createState(false);
const time = createPoll('', 1000, () => GLib.DateTime.new_now_local().format('%H\n%M'));

let lock: SessionLock.Instance | null = null;
let lockWindows: Gtk.Window[] = [];
const destroyLockWindows = () => { const wins = lockWindows; lockWindows = []; timeout(100, () => wins.forEach((w) => w.destroy())); };

const hiddenCursor = Gdk.Cursor.new_from_texture( // no cursor
    Gdk.MemoryTexture.new(1, 1, Gdk.MemoryFormat.R8G8B8A8, GLib.Bytes.new(new Uint8Array([0, 0, 0, 0])), 4),
    0, 0, null,
);

let busy = false;
let failures = 0;

const checkLogin = (entry: Gtk.Entry) => {
    if (busy) return;
    busy = true;
    const password = entry.get_text();
    entry.set_text('');

    Auth.Pam.authenticate(password, (_, task) => {
        try {
            Auth.Pam.authenticate_finish(task);
            busy = false;
            failures = 0;
            unlockScreen();
        } catch { // Wrong password
            setAuthFailed(true);
            if (++failures >= 5) return void execAsync('systemctl reboot');
            timeout(2000, () => { setAuthFailed(false); busy = false; });
        };
    });
};

const handleKeys = (entry: Gtk.Entry, key: number, state: Gdk.ModifierType) => {
    if (key == 65379) return true; // Insert
    if (!(state & Gdk.ModifierType.CONTROL_MASK)) return busy;

    switch (Gdk.keyval_to_lower(key)) {
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
        case 118: // V - no paste from clipboard!
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
        lockWindows.push(win);

        let entry: Gtk.Entry;
        win.set_child(
            <overlay>
                <Gtk.EventControllerKey
                    propagationPhase={Gtk.PropagationPhase.CAPTURE}
                    onKeyPressed={(_ctrl, key, _keycode, state) => handleKeys(entry, key, state)}
                />
                <Gtk.Picture paintable={wallpaperTexture} contentFit={Gtk.ContentFit.COVER} />
                <entry
                    hexpand
                    vexpand
                    visibility={false}
                    invisibleChar={0}
                    onActivate={checkLogin}
                    $type="overlay"
                    $={(self) => (entry = self, self.connect('map', () => self.grab_focus()))}
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
    lock.connect('failed', () => { lock = null; destroyLockWindows(); });
    lock.connect('unlocked', () => { lock = null; destroyLockWindows(); });

    lock.connect('monitor', (_, monitor: Gdk.Monitor) => assignLockWindow(monitor));

    if (!lock.lock()) return void (lock = null);

    // move cursor up a pixel so that it updates and disappears
    timeout(120, () => execAsync('swaymsg -- seat - cursor move 1 1, seat - cursor move -1 -1').catch(() => {}));
};

export const unlockScreen = () => {
    lock?.unlock();
    destroyLockWindows();
    lock = null;
};
