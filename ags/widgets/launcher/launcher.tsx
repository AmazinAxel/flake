import Apps from 'gi://AstalApps'
import { Gtk, Gdk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { createState, For } from 'ags';
import { execAsync } from 'ags/process';
import BackgroundSection from "../../lib/backgroundSection";
import inputControl from '../../lib/inputControl';

const apps = new Apps.Apps()
let textBox: Gtk.Entry;
const [appsList, setAppsList] = createState(new Array<Apps.Application>())
setAppsList(apps.fuzzy_query('').slice(0, 5));

const search = (text: string) => setAppsList(apps.fuzzy_query(text).slice(0, 5))

const hide = () => app.toggle_window("launcher");
const EscKey = () => <Gtk.EventControllerKey onKeyPressed={(_, key) => key == 65307 && hide()}/>

export default () => inputControl('launcher', () =>
    <BackgroundSection
        height={700} width={500}
        header={<entry
            $type="overlay"
            primaryIconName="system-search-symbolic"
            placeholderText="Search"
            onActivate={() => {
                launchApp(apps.fuzzy_query(textBox.text)?.[0]);
                hide();
            }}
            onNotifyText={({ text }) => search(text)}
            $={self => {
                textBox = self;
                app.connect("window-toggled", () =>
                    app.get_window("launcher")?.visible && self.grab_focus()
                );
        }}>
            <EscKey/>
        </entry>}

        content={<box spacing={6} orientation={Gtk.Orientation.VERTICAL}>
            <EscKey/>
            <For each={appsList}>
                {(app) => (
                    <button
                        onClicked={() => { launchApp(app); hide(); }}
                        cssClasses={["button"]}
                    >
                        <Gtk.EventControllerKey
                            onKeyPressed={(_, key) => {
                                if (key == Gdk.KEY_Return) {
                                    launchApp(app);
                                    hide();
                                }
                            }}
                        />
                        <box>
                            <image iconName={app.iconName} />
                            <box valign={Gtk.Align.CENTER}>
                                <label
                                    cssClasses={["name"]}
                                    xalign={0}
                                    label={app.name}
                                />
                            </box>
                        </box>
                    </button>
                )}
            </For>
        </box>}
        />, () => textBox.text = '');

// Launch app seperately from astal in wayland mode
const launchApp = (app: Apps.Application) => {
    let exe = app.executable
        .split(/\s+/)
        .filter((str) => !str.startsWith('%') && !str.startsWith('@'))
        .join(' ');

    execAsync(`sh -c '${exe} &'`);

    // Get away from social media addiction
    if (!app.name.includes('discord') && !app.name.includes('slack'))
        app.set_frequency(app.get_frequency() + 1);
};
