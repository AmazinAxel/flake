import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import Notifd from 'gi://AstalNotifd';
import { notificationItem, invokeFirstAction } from './notificationItem';
import { createState, For, This } from 'ags';
import { monitors } from '../../lib/monitors';

const { TOP, RIGHT } = Astal.WindowAnchor;
export const [ streamingMode, setStreamingMode ] = createState(false);

const map: Map<number, Notifd.Notification> = new Map();
export const [ notificationlist, setNotificationList ] = createState(new Array<Notifd.Notification>())

const notify = () => setNotificationList([...map.values()].reverse());

const setKey = (key: number, value: Notifd.Notification) =>
    !streamingMode.peek() && (map.set(key, value), notify());

const deleteKey = (key: number) => (map.delete(key), notify());

export const notifications = () =>
    <For each={monitors}>
        {(monitor) => <This this={app}>
            <window
                name="notifications"
                anchor={TOP | RIGHT}
                application={app}
                layer={Astal.Layer.TOP}
                gdkmonitor={monitor}

                // This prop gives broken accounting warning but fixes allocation size
                visible={notificationlist.as(n => (n.length != 0) ? true : false)}
                $={() => {
                    const notifd = Notifd.get_default();
                    notifd.connect("notified", (_, id) => {
                        const notif = notifd.get_notification(id)!;
                				if (!notif.body.startsWith('Failed to connect to server')) // Hide annoying message
                            setKey(id, notif)
                    });
                    notifd.connect("resolved", (_, id) => deleteKey(id));
                }}
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
	deleteKey([...map][0][0]);

export const invokeOldestNotification = () => {
    const oldest = [...map.values()][0];
    oldest && invokeFirstAction(oldest);
};
