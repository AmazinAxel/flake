import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import Notifd from 'gi://AstalNotifd';
import { notificationItem } from './notificationItem';
import { createState, For, type Accessor } from 'ags';

const { TOP, RIGHT } = Astal.WindowAnchor;
export const [ streamingMode, setStreamingMode ] = createState(false);

const map: Map<number, Notifd.Notification> = new Map();
const reveals: Map<number, { reveal: Accessor<boolean>, setReveal: (v: boolean) => void }> = new Map();
export const [ notificationlist, setNotificationList] = createState(
    new Array<Notifd.Notification>()
)

const notify = () =>
	setNotificationList([...map.values()].reverse());

const setKey = (key: number, value: Notifd.Notification) => {
	if (!streamingMode.peek()) {
		map.set(key, value);
		if (!reveals.has(key)) {
			const [reveal, setReveal] = createState(true);
			reveals.set(key, { reveal, setReveal });
		}
		notify();
	}
};

const deleteKey = (key: number) => {
	map.delete(key);
	reveals.delete(key);
	notify();
};

const startHide = (key: number) => {
	const r = reveals.get(key);
	if (r) r.setReveal(false);
	else deleteKey(key);
};

export const notifications = () =>
	<window
		name="notifications"
		anchor={TOP | RIGHT}
		application={app}
		layer={Astal.Layer.TOP}
		defaultHeight={1} // gtk layer shell glitch workaround
        defaultWidth={1}

		// This prop gives broken accounting warning but fixes allocation size
		visible={notificationlist.as(n => (n.length != 0) ? true : false)}
		$={() => {
			const notifd = Notifd.get_default();
			notifd.connect("notified", (_, id) => {
				const notif = notifd.get_notification(id)!;
				if (!notif.body.startsWith('Failed to connect to server')) // Hide annoying message
					setKey(id, notif)
			});
			notifd.connect("resolved", (_, id) =>
				startHide(id)
			);
		}}
	>
		<box orientation={Gtk.Orientation.VERTICAL} halign={Gtk.Align.END}>
			<For each={notificationlist}>
				{(item) => notificationItem(item, reveals.get(item.id)!.reveal, () => deleteKey(item.id))}
			</For>
		</box>
	</window>

export const clearOldestNotification = () =>
	startHide([...map][0][0]);
