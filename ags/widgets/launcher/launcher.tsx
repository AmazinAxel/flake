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

export const [ focus, setIsFocused ] = createState(false);
const focusBlockedAppNames = ['discord', 'slack'];

const isBlocked = (a: Apps.Application) =>
    focus.peek() && focusBlockedAppNames.some(b => a.name.toLowerCase().includes(b));

const search = (text: string) => setAppsList(
    text.length < 2 ? [] : apps.fuzzy_query(text).filter(a => !isBlocked(a)).slice(0, 5)
);

const launchApp = (selectedApp: Apps.Application) => {
    // Launch through the compositor so the app inherits sway's full session
    // environment, exactly like an app started from a foot terminal. Launching
    // as a child of ags (AstalApps' launch(), or systemd-run --scope) inherits
    // ags's LD_PRELOAD (gtk4-layer-shell) and GI_TYPELIB_PATH pollution, which
    // crashes apps. systemd-run --user avoids that but loses GDK_PIXBUF_MODULE_FILE
    // and other session vars, so GTK apps coredump on icon load. swaymsg exec
    // gets it right: sway's env has the right loaders without ags's pollution.
    const cmd = selectedApp.executable.replace(/ ?%[a-zA-Z]/g, '').trim();
    execAsync(['swaymsg', 'exec', '--', cmd])
        .catch(err => console.error(`Failed to launch ${selectedApp.name}:`, err));
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
