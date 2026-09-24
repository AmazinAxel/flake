import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import Notifd from 'gi://AstalNotifd';
import { notificationItem, invokeFirstAction } from './notificationItem';
import { createState, For, This, onCleanup } from 'ags';
import { monitors } from '../../lib/monitors';

const { TOP, RIGHT } = Astal.WindowAnchor;
export const [ streamingMode, setStreamingMode ] = createState(false);

const notifd = Notifd.get_default();
const map: Map<number, Notifd.Notification> = new Map();
export const [ notificationlist, setNotificationList ] = createState(new Array<Notifd.Notification>())

const notify = () => setNotificationList([...map.values()].reverse());

const hidden = (n: Notifd.Notification) =>
    (streamingMode.peek() && n.appName != 'batsignal')
    || n.body.startsWith('Failed to connect to server'); // Hide annoying message

notifd.connect("notified", (_, id) => {
    const n = notifd.get_notification(id);
    if (!n) return;
    if (hidden(n)) return n.dismiss();
    map.set(id, n);
    notify();
});
notifd.connect("resolved", (_, id) => map.delete(id) && notify());

export const notifications = () =>
    <For each={monitors}>
        {(monitor) => <This this={app}>
            <window
                name="notifications"
                anchor={TOP | RIGHT}
                application={app}
                layer={Astal.Layer.TOP}
                gdkmonitor={monitor}
                $={(self) => onCleanup(() => self.destroy())}

                // This prop gives broken accounting warning but fixes allocation size
                visible={notificationlist.as(n => n.length != 0)}
            >
                <box orientation={Gtk.Orientation.VERTICAL} widthRequest={200}>
                    <For each={notificationlist}>
                        {(item) => notificationItem(item)}
                    </For>
                </box>
            </window>
        </This>}
    </For>

export const clearOldestNotification = () =>
    map.values().next().value?.dismiss();

export const invokeOldestNotification = () => {
    const oldest = map.values().next().value;
    oldest && invokeFirstAction(oldest);
};
