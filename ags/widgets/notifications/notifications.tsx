import { Astal } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import Notifd from 'gi://AstalNotifd';
import GLib from 'gi://GLib';
import { notificationItem } from './notificationItem';
import { createState, createRoot, type Accessor } from 'ags';
import { monitors } from '../../lib/monitors';

const { TOP, RIGHT } = Astal.WindowAnchor;
export const [ streamingMode, setStreamingMode ] = createState(false);

const notificationlist: Map<number, Entry> = new Map();

type Entry = {
    setReveal: (v: boolean) => void;
    reveal: Accessor<boolean>;
    height: number;
    windows: Astal.Window[];
    dispose: () => void;
};

const orderedlist = () => [...notificationlist.keys()].sort((a, b) => b - a);

const calcHeight = () => { // otherwise they will overlap
    let topMarginTotal = 0;
    for (const id of orderedlist()) {
        const notification = notificationlist.get(id)!;
        for (const win of notification.windows) win.marginTop = topMarginTotal; // applies to all monitors
        topMarginTotal += notification.height;
    };
};

const removeEntry = (id: number) => {
    const e = notificationlist.get(id);
    if (!e) return; // spams with warnings for some reason?
    notificationlist.delete(id);
    for (const win of e.windows) win.destroy(); // for all monitors
    e.dispose(); // tear down the reactive scope / subscriptions
    calcHeight();
};

const startHide = (id: number) => notificationlist.get(id)?.setReveal(false);

const createNotificationWindow = (notif: Notifd.Notification) => {
    const [ reveal, setReveal ] = createState(true);
    const id = notif.id;

    createRoot((dispose) => { // wrapped to fix dispose error
        const entry: Entry = { reveal, setReveal, height: 0, windows: [], dispose };

        // for all monitors
        notificationlist.set(id, entry);
        entry.windows = monitors.peek().map((monitor) => <window
            name={'notification-' + id}
            anchor={TOP | RIGHT}
            application={app}
            gdkmonitor={monitor}
            layer={Astal.Layer.TOP}
            defaultHeight={1} // needed or else it will glitch
            defaultWidth={1}
            visible
            $={(self) => self.add_tick_callback(() => {
                const h = self.get_height();
                if (h <= 1) return GLib.SOURCE_CONTINUE; // wait, but this is not very performant
                const entry = notificationlist.get(id);
                entry!.height = h;
                calcHeight();
                return GLib.SOURCE_REMOVE; // stops the loop
            })}
        >
            {notificationItem(notif, reveal, () => removeEntry(id))}
        </window> as Astal.Window);
        return entry.windows;
    });
};

export const notifications = () => {
    const notifd = Notifd.get_default();
    notifd.connect("notified", (_, id) => {
        if (streamingMode.peek()) return;
        if (notificationlist.has(id)) return;
        createNotificationWindow(notifd.get_notification(id)!);
    });
    notifd.connect("resolved", (_, id) => startHide(id));
};

export const clearOldestNotification = () => {
    const ids = orderedlist();
    if (ids.length > 0) startHide(ids[ids.length - 1]);
};
