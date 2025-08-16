import GLib from "gi://GLib";
import { Gtk, Gdk } from 'ags/gtk4';

import Notifd from 'gi://AstalNotifd';
import Pango from 'gi://Pango';
const { START, CENTER, END } = Gtk.Align
const notifd = Notifd.get_default();

const time = (time: number) => GLib.DateTime.new_from_unix_local(time).format("%H:%M")!;

export const notificationItem = (n: Notifd.Notification) =>
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['notification']}>
        <box cssClasses={['header']}>
            {(n.desktopEntry || n.image) && <image
                cssClasses={['app-icon']}
                iconName={n.desktopEntry || n.image}
            />}
            <label
                cssClasses={['app-name']}
                halign={START}
                ellipsize={Pango.EllipsizeMode.END}
                label={n.appName || 'Unknown'}
            />
            <label
                cssClasses={['time']}
                hexpand
                halign={END}
                label={time(n.time)}
            />
        </box>
        <box cssClasses={['content']}>
            <box orientation={Gtk.Orientation.VERTICAL}>
                <label
                    cssClasses={['summary']}
                    halign={START}
                    wrap
                    xalign={0}
                    label={n.summary}
                    maxWidthChars={10}
                />
                {n.get_hint('internal-image-path') && <image
                    file={n.get_hint('internal-image-path')?.get_string()[0]}
                    heightRequest={100}
                    widthRequest={100}
                />}
                {n.body && <label
                    wrap
                    xalign={0}
                    label={n.body}
                    maxWidthChars={10}
                />}
                {n.get_actions().length > 0 && <box cssClasses={['actions']} spacing={5}>
                    {n.get_actions().map(({ label, id }) =>
                        <button
                            hexpand
                            cursor={Gdk.Cursor.new_from_name('pointer', null)}
                            onClicked={() => {
                                n.invoke(id);
                                setTimeout(() =>
                                    (notifd.get_notification(n.id)) && n.dismiss()
                                , 100)
                             }}
                        >
                            <label label={label.replace('Activate', 'Open')} halign={CENTER}/>
                        </button>
                    )}
                </box>}
            </box>
        </box>
    </box>
