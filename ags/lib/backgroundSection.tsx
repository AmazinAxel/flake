import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import { playlistName } from './mediaPlayer';

const bgCss = new Gtk.CssProvider();
Gtk.StyleContext.add_provider_for_display(
    Gdk.Display.get_default()!, bgCss, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
playlistName.subscribe(() => bgCss.load_from_string(`.backgroundOverlay { background-image: url("file:///home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg"); }`))

export default ({ header, content, height, width }: { header: any; content: any, height?: number, width: number }) =>
    <box
        heightRequest={height}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
    >
        <box
            widthRequest={width}
            spacing={5}
            cssClasses={['widgetBackground', 'backgroundSection']}
            orientation={Gtk.Orientation.VERTICAL}
            valign={Gtk.Align.START}
        >
            <overlay cssClasses={['header']}>
                <box cssClasses={['backgroundOverlay']}/>
                {header}
            </overlay>

            {content}
        </box>
    </box>
