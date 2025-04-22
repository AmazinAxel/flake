import { GLib, exec } from 'astal';
import { App, Gtk } from 'astal/gtk4';

export const ClipboardItem = (id: string, content: string): Gtk.Widget => {
    const matches = content.match(/\[\[ binary data (\d+) (B|KiB|MiB) (\w+) (\d+)x(\d+) \]\]/);
    if (matches) { // Image item
        const extension = matches[3];
        const width = Number(matches[4]);
        const height = Number(matches[5]);

        const path = `/tmp/ags/cliphist/${id}.${extension}`;
        if (!GLib.file_test(path, GLib.FileTest.EXISTS)) {
            exec('mkdir -p /tmp/ags/cliphist/');
            exec(`bash -c 'cliphist decode ${id} > ${path}'`);
        };
        const adjustedWidth = (width / height) * 150;
        const maxContainerWidth = 400;
        let maxHeight, maxWidth;

        if (adjustedWidth > maxContainerWidth) { // Long horizontal image
            maxHeight = (150 / adjustedWidth) * maxContainerWidth; // Retain aspect ratio
            maxWidth = maxContainerWidth;
        } else { // Vertical or small image
            maxHeight = 150;
            maxWidth = adjustedWidth;
        };

        App.apply_css(`._${id} {
            background-image: url("file://${path}");
            min-height: ${maxHeight}px;
            min-width: ${maxWidth}px;
        }`);

        return <box cssClasses={[`_${id}`, 'image']} name={id} valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER}/>
    };

    return <label label={content} xalign={0} wrap name={id}/>
};
