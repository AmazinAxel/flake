import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { playlistName } from './mediaPlayer';

// Update launcher background to wallpaper
playlistName.subscribe(() => app.apply_css(`.backgroundOverlay { background-image: url("file:///home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg"); }`))

export default ({ header, content, height, width }: { header: any; content: any, height: number, width: number }) =>
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
