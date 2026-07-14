import { execAsync } from 'ags/process';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import GLib from 'gi://GLib';
import { ClipboardItem } from './clipboardItem';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';
import { streamingMode } from '../notifications/notifications';

const list = new Gtk.ListBox();

list.connect('row-activated', async (_, row) => {
    app.get_window('clipboard')?.set_visible(false);

    const id = row.child.name;
    await execAsync(`bash -c 'cliphist decode ${id} | wl-copy'`);
});

list.set_sort_func((a, b) => {
    const row1id = Number(a.child.name);
    const row2id = Number(b.child.name);

    return row2id - row1id;
});

streamingMode.subscribe(() => refreshItems());

const refreshItems = async () => {
    const entries = await execAsync('cliphist list')
    .then((str) => str.split('\n')
        .map((entry) => {
            const [id, content] = entry.split('\t');
            return { id: id, content: content };
        })
    ).catch(() => []);

    list.remove_all();

    if (entries[0]?.content) // has entries
        entries.forEach((entry) =>
            list.append(ClipboardItem(entry.id, entry.content) as Gtk.Widget)
        );
};
refreshItems();

const handleKeys = (_ctrl: any, key: number) => {
    switch (key) {
    case 65293: // Enter
        (list.get_selected_row() === null)
        ? list.get_first_child()?.activate()
        : list.get_selected_row()?.activate();
        break;
    case 99: // C - copy 2nd recent entry
        list.get_row_at_index(1)?.activate()
        break;
    case 101: // E - edit image with swappy
        const id = list.get_selected_row()?.child.name ?? list.get_row_at_index(0)?.child.name;

        const path = `/tmp/ags/cliphist/${id}.png`; // .png extension is assumed here
        if (!GLib.file_test(path, GLib.FileTest.EXISTS)) break;

        app.get_window('clipboard')?.hide()
        execAsync('swappy -f ' + path);
        break;
    case 119: // W - wipe clipboard history
        execAsync('cliphist wipe');
        app.get_window('clipboard')?.hide()
        break;
    };
};

export default () => inputControl('clipboard', () =>
    <BackgroundSection
        width={500}
        header={<label $type="overlay" label="Clipboard"/>}
        content={
        <Gtk.ScrolledWindow
            cssClasses={['clipboardScroll']}
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            vscrollbarPolicy={Gtk.PolicyType.AUTOMATIC}
            overlayScrolling
            maxContentHeight={500}
            propagateNaturalHeight
        >
            {list}
        </Gtk.ScrolledWindow>}
    />,
    async () => {
        await refreshItems();
        list.get_first_child()?.grab_focus();
    },
    undefined,
    handleKeys);
