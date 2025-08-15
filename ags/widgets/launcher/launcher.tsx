import Apps from 'gi://AstalApps'
import { Astal, Gtk, Gdk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
//import { bind } from 'astal'; // todo
import { playlistName } from '../../services/mediaPlayer';

const apps = new Apps.Apps()
let textBox: Gtk.Entry;

const hide = () => app.toggle_window("launcher");

const AppBtn = ({ app }: { app: Apps.Application }) =>
    <button
        onKeyPressed={(_, key) => {
            if (key == Gdk.KEY_Return) {
                app.launch();
                hide();
            }
        }}
        onClicked={() => { app.launch(); hide(); }}
        cssClasses={['button']}
    >
        <box>
            <image iconName={app.iconName}/>
            <box valign={Gtk.Align.CENTER}>
                <label
                    cssClasses={['name']}
                    xalign={0}
                    label={app.name}
                />
            </box>
        </box>
    </button>


export default () =>
    <window
        name="launcher"
        anchor={Astal.WindowAnchor.TOP}
        keymode={Astal.Keymode.ON_DEMAND}
        application={app}
        visible={false}
        onShow={() => textBox.text = ''}
        onKeyPressed={(_, key) =>
            (key == 65307) // Gdk.KEY_Escape
               && hide()
        }
    >
        <box heightRequest={700}>
            <box widthRequest={500} cssClasses={['launcher', 'widgetBackground']} vertical valign={Gtk.Align.START}>
                <overlay>
                    <box
                        cssClasses={['searchBg']}
                        $={() =>
                            playlistName.subscribe((w) =>
                                App.apply_css(`.searchBg { background-image: url("file:///home/alec/Projects/flake/wallpapers/${w}.jpg"); }`)
                            )
                        }
                    />
                    <entry
                        type="overlay"
                        primaryIconName="system-search-symbolic"
                        placeholderText="Search"
                        onActivate={() => {
                            apps.fuzzy_query(textBox.text)?.[0].launch();
                            hide();
                        }}
                        setup={self => { // Auto-grab focus when launched
                            textBox = self;
                            App.connect("window-toggled", () =>
                                (App.get_window("launcher")?.visible == true)
                                    && self.grab_focus()
                            );
                        }}
                    />
                </overlay>
                <box spacing={6} orientation={Gtk.Orientation.VERTICAL}>
                    {bind(textBox, 'text').as(text =>
                        apps.fuzzy_query(text).slice(0, 5)
                        .map((app: Apps.Application) => <AppBtn app={app}/>)
                    )}
                </box>
            </box>
        </box>
    </window>
