import { App, Astal, Gtk, Gdk } from 'astal/gtk3';
import Notifd from 'gi://AstalNotifd';
import { notificationItem } from './notificationitem';
import { type Subscribable } from 'astal/binding';
import { Variable, bind } from 'astal';
const { TOP, RIGHT } = Astal.WindowAnchor;
export const DND = Variable(false);

export class NotifiationMap implements Subscribable {
    private map: Map<number, Gtk.Widget> = new Map();
    private var: Variable<Array<Gtk.Widget>> = new Variable([]);

    private notifiy = () => {
        if (!DND.get())
           this.var.set([...this.map.values()].reverse());
    }
    constructor() {
        const notifd = Notifd.get_default();

        notifd.connect("notified", (_, id) =>
            this.set(id, notificationItem(notifd.get_notification(id)!))
        );

        notifd.connect("resolved", (_, id) =>
            this.delete(id)
        );
    };

    // TODO figure out why notifications w/ different keys are being disposed & replaced
    private set(key: number, value: Gtk.Widget) {
        //this.map.get(key)?.destroy(); // If same ID then replace
        this.map.set(key, value);
        this.notifiy();
    };

    private delete(key: number) {
        this.map.get(key)?.destroy();
        this.map.delete(key);
        this.notifiy();
    };

    public clearNewestNotification() {
        const newestNotif = [...this.map][0][0];
        this.delete(newestNotif);
    };

    get = () => this.var.get();
    
    subscribe = (callback: (list: Array<Gtk.Widget>) => void) => 
        this.var.subscribe(callback);
};

export const notifications = (gdkmonitor: Gdk.Monitor, allNotifications: Subscribable) =>
    <window
        className="Notifications"
        gdkmonitor={gdkmonitor}
        anchor={TOP | RIGHT}
        application={App}
    >
        <box vertical>
            {bind(allNotifications)}
        </box>
    </window>
