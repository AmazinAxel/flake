import GLib from 'gi://GLib';
import Gdk from 'gi://Gdk';
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { createState, For } from 'ags';
import { execAsync } from 'ags/process';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';

const STORE = `${GLib.get_home_dir()}/.password-store`;

let textBox: Gtk.Entry;
let entries: string[] = [];
const [ results, setResults ] = createState(new Array<string>());

const loadEntries = async () => {
    const out = await execAsync(['bash', '-c',
        `cd "${STORE}" 2>/dev/null && find . -type f -name '*.gpg' | sed 's|^\\./||; s|\\.gpg$||' | sort`
    ]).catch(() => '');
    entries = out.split('\n').filter(Boolean);
};

const search = (q: string) => {
    if (q.length < 2) return setResults([]);
    const ql = q.toLowerCase();
    const matched = entries
        .map(n => [n, n.toLowerCase().indexOf(ql)] as const)
        .filter(([, s]) => s >= 0)
        .sort((a, b) => a[1] - b[1])
        .slice(0, 5)
        .map(([n]) => n);
    setResults(matched);
};

const copyPair = async (name: string) => {
    app.get_window('pass')?.set_visible(false);
    const userCmd = `pass show "${name}" | sed -n 's/^\\(login\\|user\\(name\\)\\?\\):[[:space:]]*//Ip' | head -n1 | tr -d '\\n' | wl-copy -n`;
    const passCmd = `pass show "${name}" | head -n1 | tr -d '\\n' | wl-copy -n`;
    await execAsync(['bash', '-c', `${userCmd} && sleep 0.15 && ${passCmd}`])
        .catch((e) => console.error('pass copy failed:', e));
};

const copyUsername = async (name: string) => {
    app.get_window('pass')?.set_visible(false);
    const userCmd = `pass show "${name}" | sed -n 's/^\\(login\\|user\\(name\\)\\?\\):[[:space:]]*//Ip' | head -n1 | tr -d '\\n' | wl-copy -n`;
    await execAsync(['bash', '-c', userCmd])
        .catch((e) => console.error('pass copy failed:', e));
};

loadEntries();

export default () => inputControl('pass', () =>
    <BackgroundSection
        height={700} width={500}
        header={<entry
            $type="overlay"
            primaryIconName="system-search-symbolic"
            placeholderText="Passwords"
            onNotifyText={({ text }) => search(text)}
            onActivate={() => {
                const top = results.peek()[0];
                if (top) copyPair(top);
            }}
            $={self => {
                textBox = self;
                const ctl = new Gtk.EventControllerKey();
                ctl.connect('key-pressed', (_c, keyval) => {
                    if (keyval === Gdk.KEY_u || keyval === Gdk.KEY_U) {
                        const top = results.peek()[0];
                        if (top) copyUsername(top);
                        return true;
                    }
                    return false;
                });
                self.add_controller(ctl);
                app.connect('window-toggled', () => {
                    if (app.get_window('pass')?.visible) {
                        loadEntries();
                        self.grab_focus();
                    }
                });
            }}
        />}
        content={<box spacing={6} orientation={Gtk.Orientation.VERTICAL}>
            <For each={results}>
                {(name) => (
                    <button
                        onClicked={() => copyPair(name)}
                        cssClasses={['button']}
                    >
                        <box>
                            <box valign={Gtk.Align.CENTER}>
                                <label
                                    cssClasses={['name']}
                                    xalign={0}
                                    label={name}
                                />
                            </box>
                        </box>
                    </button>
                )}
            </For>
        </box>}
    />,
    () => { if (textBox) { textBox.text = ''; } setResults([]); },
    true
);
