import { execAsync, createSubprocess } from 'ags/process';
import { timeout } from 'ags/time';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import GLib from 'gi://GLib';
import Gio from 'gi://Gio';
import { ClipboardItem, entryPath, cacheDir, videoExts, binaryData } from './clipboardItem';
import { openCompress, tmpDir } from './compress';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';
import { streamingMode } from '../notifications/notifications';

const list = new Gtk.ListBox();
const hide = () => app.get_window('clipboard')?.hide();
const items = new Map<string, { mime: string, path: string | null, child: Gtk.Widget }>();

list.connect('row-activated', (_, row) => {
    hide();

    const id = row.child.name;
    const type = items.get(id)?.mime ?? 'text/plain';
    execAsync(['bash', '-c', `cliphist decode ${id} | wl-copy -t ${type} 2>/dev/null`]);
});

list.set_sort_func((a, b) => {
    const row1id = Number(a.child.name);
    const row2id = Number(b.child.name);

    return row2id - row1id;
});

streamingMode.subscribe(() => {
    list.remove_all(); // rebuild
    items.clear();
    refreshItems();
});

let inFlight: Promise<void> = Promise.resolve();
const refreshItems = () => inFlight = inFlight.then(async () => {
    const entries = (await execAsync('cliphist list')).split('\n')
        .map((entry) => {
            const [id, content] = entry.split('\t');
            return { id, content };
        })
        .filter((entry) => entry.id && entry.content);

    entries.forEach(({ id, content }) => {
        if (items.has(id)) return;

        const image = content.match(binaryData);
        const path = entryPath(id, content);
        const child = ClipboardItem(id, content, path) as Gtk.Widget;
        list.append(child);

        items.set(id, { path, child, mime:
            image ? `image/${image[1]}`
            : content.trim().startsWith('file://') ? 'text/uri-list' // paste the ACTUAL file
            : 'text/plain' });
    });

    const current = new Set(entries.map((entry) => entry.id));
    const stale = [...items].filter(([id]) => !current.has(id));

    stale.forEach(([id, { child }]) => {
        list.remove(child.get_parent() as Gtk.Widget); // ListBoxRow parent
        items.delete(id);
    });

    // Their decodes and thumbnails are dead weight now
    if (stale.length) execAsync(['bash', '-c',
        'rm -f ' + stale.map(([id]) => `${cacheDir}/${id}.*`).join(' ')]);
}).catch(() => {});
refreshItems();

// build on copy
createSubprocess('', ['wl-paste', '--watch', 'echo', 'copied'])
    .subscribe(() => timeout(200, refreshItems));

const focusTop = () => {
    const first = list.get_row_at_index(0);

    list.select_row(first);
    first?.grab_focus();
};

const selectedId = () => (list.get_selected_row() ?? list.get_row_at_index(0))?.child.name ?? '';

const selectedFile = () => {
    const file = items.get(selectedId())?.path;

    return (file && GLib.file_test(file, GLib.FileTest.EXISTS)) ? file : null;
};

const handleKeys = (_ctrl: any, key: number) => {
    const file = selectedFile();

    switch (key) {
    case 65293: // Enter
        (list.get_selected_row() ?? list.get_row_at_index(0))?.activate();
        break;
    case 99: // C - copy 2nd recent entry
        list.get_row_at_index(1)?.activate()
        break;
    case 101: // E - edit image with swappy
        if (!file || videoExts.test(file)) break;
        hide();
        execAsync(['swappy', '-f', file]);
        break;
    case 103: // G - open in gthumb
        if (!file) break;
        hide();
        execAsync(['gthumb', file]);
        break;
    case 109: // M - compress video to a size limit
        if (!file || !videoExts.test(file)) break;
        hide();
        openCompress(file, selectedId());
        break;
    case 110: // N - open in nemo
        if (!file) break;
        hide();
        Gio.DBus.session.call(
            'org.freedesktop.FileManager1',
            '/org/freedesktop/FileManager1',
            'org.freedesktop.FileManager1',
            'ShowItems',
            new GLib.Variant('(ass)', [[GLib.filename_to_uri(file, null)], '']),
            null, Gio.DBusCallFlags.NONE, -1, null, null);
        break;
    case 119: // W - wipe clipboard history
        execAsync(['bash', '-c', `cliphist wipe && rm -rf ${tmpDir}/* && mkdir -p ${cacheDir}`]);
        hide();
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
    () => {
        focusTop();
        refreshItems().then(focusTop);
    },
    undefined,
    handleKeys);
