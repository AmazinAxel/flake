import { monitorFile } from 'ags/file';
import { execAsync } from 'ags/process';
import { Gtk, Astal } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import Gio from 'gi://Gio'
import GLib from 'gi://GLib';
import { ClipboardItem } from './clipboardItem';

const list = new Gtk.ListBox;

list.connect('row-activated', async (_, row) => {
    app.get_window('clipboard')?.set_visible(false);

    const id = row.child.name;
    await execAsync(`bash -c 'cliphist decode ${id} | wl-copy'`);
});

list.set_sort_func((a, b) => {
    const row1id = Number(a.name);
    const row2id = Number(b.name);

    return row2id - row1id;
});

monitorFile(`/home/alec/.cache/cliphist/db`, (_, event) =>
    (event == Gio.FileMonitorEvent.CHANGES_DONE_HINT) && refreshItems()
);

const refreshItems = async () => {
    const entries = await execAsync('cliphist list')
        .then((str) => str.split('\n')
            .map((entry) => {
                const [id, content] = entry.split('\t');
                return { id: id, content: content };
            })
        ).catch(() => []);

        list.remove_all();

        if (entries[0].content) // Only remap if there is clipboard history to show
            entries.forEach((entry) =>
                list.append(ClipboardItem(entry.id, entry.content) as Gtk.Widget)
            );
};

let window: Gtk.Window;
export default () => <window
    name="clipboard"
    namespace="clipboard" // For hyprland noscreenshare windowrule identification
    keymode={Astal.Keymode.ON_DEMAND}
    $={(self) => { refreshItems(); window = self; }}
    onShow={() => list.get_first_child()?.grab_focus()}
    application={app}
    >
        <Gtk.EventControllerKey
            onKeyPressed={(_, key) => {
                switch (key) {
                case 65293: // Enter - pass event to selection
                    (list.get_selected_row() === null)
                    ? list.get_first_child()?.activate()
                    : list.get_selected_row()?.activate();
                    break;
                case 99: // C - copy 2nd recent entry
                    list.get_row_at_index(1)?.activate()
                    break;
                case 101: // E - edit image with Swappy
                    const id = list.get_selected_row()?.child.name ?? list.get_row_at_index(0)?.child.name;

                    const path = `/tmp/ags/cliphist/${id}.png`; // .png extension is assumed here
                    if (!GLib.file_test(path, GLib.FileTest.EXISTS)) break;

                    window.hide();
                    execAsync('swappy -f ' + path);
                    break;
                case 119: // W - wipe clipboard history
                    execAsync('cliphist wipe');
                    window.hide();
                    break;
                default:
                    window.hide()
            };
        }}/>
        <Gtk.ScrolledWindow
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
            heightRequest={500}
            widthRequest={400}
        >
            {list}
        </Gtk.ScrolledWindow>
    </window>