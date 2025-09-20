import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import Notifd from 'gi://AstalNotifd';
import { notificationItem } from './notificationItem';
import { createState, For } from 'ags';

const { TOP, RIGHT } = Astal.WindowAnchor;
export const [ DND, setDND] = createState(false);

const map: Map<number, Notifd.Notification> = new Map();
export const [ notificationlist, setNotificationList] = createState(
    new Array<Notifd.Notification>()
)

const notifiy = () =>
	setNotificationList([...map.values()].reverse());

const setKey = (key: number, value: Notifd.Notification) => {
	if (!DND.get()) {
		map.set(key, value);
		notifiy();
	}
};

const deleteKey = (key: number) => {
	map.delete(key);
	notifiy();
};

export const notifications = () =>
	<window
		name="notifications"
		anchor={TOP | RIGHT}
		application={app}

		// This prop gives broken accounting warning but fixes allocation size
		visible={notificationlist.as(n => (n.length != 0) ? true : false)}
		$={() => {
			const notifd = Notifd.get_default();
			notifd.connect("notified", (_, id) => {
				const notif = notifd.get_notification(id);
				if (!notif.body.startsWith('Failed to connect to server')) // Hide annoying message
					setKey(id, notif)
			});
			notifd.connect("resolved", (_, id) =>
				deleteKey(id)
			);
		}}
	>
		<box orientation={Gtk.Orientation.VERTICAL} widthRequest={200}>
			<For each={notificationlist}>
				{(item) => notificationItem(item)}
			</For>
		</box>
	</window>

export const clearOldestNotification = () =>
	deleteKey([...map][0][0]);
