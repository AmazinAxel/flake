import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { playlistName } from './mediaPlayer';

// Update launcher background to wallpaper
playlistName.subscribe(() => app.apply_css(`.backgroundOverlay { background-image: url("file:///home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg"); }`))

export default ({ header, content }: { header: any; content: any }) =>
    <box heightRequest={700}>
        <box
            widthRequest={500}
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
