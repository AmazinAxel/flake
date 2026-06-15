import Apps from 'gi://AstalApps'
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { createState, For } from 'ags';
import { execAsync } from 'ags/process';
import BackgroundSection from "../../lib/backgroundSection";
import inputControl from '../../lib/inputControl';

const apps = new Apps.Apps();
let textBox: Gtk.Entry;
const [ appsList, setAppsList ] = createState(new Array<Apps.Application>());
setAppsList(apps.fuzzy_query('').slice(0, 5));

export const [ focus, setIsFocused ] = createState(false);
const focusBlockedAppNames = ['discord', 'slack'];

const isBlocked = (a: Apps.Application) =>
    focus.peek() && focusBlockedAppNames.some(b => a.name.toLowerCase().includes(b));

const search = (text: string) => setAppsList(
    apps.fuzzy_query(text).filter(a => !isBlocked(a)).slice(0, 5)
);

const launchApp = (selectedApp: Apps.Application) => {
    selectedApp.launch();
    app.toggle_window("launcher");
};

export default () => inputControl('launcher', () =>
    <BackgroundSection
        height={700} width={500}
        header={<entry
            $type="overlay"
            primaryIconName="system-search-symbolic"
            placeholderText="Search"
            onActivate={() => launchApp(apps.fuzzy_query(textBox.text)?.[0])}
            onNotifyText={({ text }) => search(text)}
            $={self => {
                textBox = self;
                app.connect("window-toggled", () => app.get_window("launcher")?.visible && self.grab_focus());
        }}>
        </entry>}

        content={<box spacing={6} orientation={Gtk.Orientation.VERTICAL}>
            <For each={appsList}>
                {(app) => (
                    <button
                        onClicked={() => launchApp(app)}
                        cssClasses={["button"]}
                    >
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
        />, () => textBox.text = '', true);
