import { execAsync } from 'ags/process';
import GLib from "gi://GLib";
import GdkPixbuf from "gi://GdkPixbuf";
import Gdk from "gi://Gdk";
import { Gtk } from 'ags/gtk4';
import { streamingMode } from '../notifications/notifications';

export const ClipboardItem = (id: string, content: string) => {
    const matches = content.match(/\[\[ binary data (\d+) (B|KiB|MiB) (\w+) (\d+)x(\d+) \]\]/);
    if (matches) { // Image item
        const extension = matches[3];
        const width = Number(matches[4]);
        const height = Number(matches[5]);

        if (streamingMode.peek())
            return <label label={`Image (${width}x${height})`} xalign={0} name={id}/>

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

        const path = `/tmp/ags/cliphist/${id}.${extension}`;

        const picture = new Gtk.Picture({ contentFit: Gtk.ContentFit.CONTAIN });
        const load = () => {
            try {
                const pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(path, Math.round(maxWidth), Math.round(maxHeight), true);
                picture.set_paintable(Gdk.Texture.new_for_pixbuf(pixbuf));
            } catch (_) {}
        };

        if (GLib.file_test(path, GLib.FileTest.EXISTS))
            load();
        else
            execAsync(`bash -c 'mkdir -p /tmp/ags/cliphist/ && cliphist decode ${id} > ${path}'`)
                .then(load)
                .catch(() => {});

        return <box cssClasses={['image']} name={id} overflow={Gtk.Overflow.HIDDEN}
            widthRequest={maxWidth} heightRequest={maxHeight}
            valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER}>
            {picture}
        </box>
    };

    if (streamingMode.peek())
        return <label label={`Text (${content.length} chars)`} xalign={0} name={id}/>

    return <label label={content} xalign={0} wrap name={id}/>
};
