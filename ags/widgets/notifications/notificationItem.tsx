import GLib from "gi://GLib";
import { Gtk, Gdk } from 'ags/gtk4';
import Notifd from 'gi://AstalNotifd';
import Pango from 'gi://Pango';
import { execAsync } from 'ags/process';
const { START, CENTER, END } = Gtk.Align;
const notifd = Notifd.get_default();

const time = (time: number) => GLib.DateTime.new_from_unix_local(time).format("%H:%M")!;

const capitalizeFirstLetter = (s: string) => s.charAt(0).toUpperCase() + s.slice(1);

export const invokeFirstAction = (n: Notifd.Notification) => {
    const action = n.get_actions()[0];
    if (!action) return;
    n.invoke(action.id);
    n.desktopEntry && execAsync(['swaymsg', `[app_id="${n.desktopEntry}"] focus`]);
    setTimeout(() => notifd.get_notification(n.id) && n.dismiss(), 100);
};

export const notificationItem = (n: Notifd.Notification) =>
    <box orientation={Gtk.Orientation.VERTICAL} cssClasses={['notification']}>
        <box cssClasses={['header']}>
            <label
                cssClasses={['appName']}
                halign={START}
                ellipsize={Pango.EllipsizeMode.END}
                label={capitalizeFirstLetter(n.appName ?? 'Unknown')}
            />
            <label hexpand halign={END} label={time(n.time)}/>
        </box>
        <box cssClasses={['content']}>
            <box orientation={Gtk.Orientation.VERTICAL}>
                {n.summary?.trim() && <label
                    cssClasses={['summary']}
                    halign={START}
                    wrap
                    xalign={0}
                    label={n.summary}
                    maxWidthChars={30}
                />}
                {n.body?.trim() && <label
                    wrap
                    xalign={0}
                    label={n.body}
                    maxWidthChars={30}
                />}
                {n.get_actions().length > 0 && <box cssClasses={['actions']} spacing={5}>
                    {n.get_actions().map(({ label, id }) =>
                        <button
                            hexpand
                            cursor={Gdk.Cursor.new_from_name('pointer', null)}
                            onClicked={() => {
                                n.invoke(id);
                                n.desktopEntry && execAsync(['swaymsg', `[app_id="${n.desktopEntry}"] focus`]);
                                setTimeout(() => notifd.get_notification(n.id) && n.dismiss(), 100);
                            }}>
                            <label label={label.replace('Activate', 'Open') ?? ''} halign={CENTER}/>
                        </button>
                    )}
                </box>}
            </box>
        </box>
    </box>