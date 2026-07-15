import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { execAsync } from 'ags/process';
import BackgroundSection from '../../lib/backgroundSection';
import inputControl from '../../lib/inputControl';
import { notifySend } from '../../lib/notifySend';

let siteBox: Gtk.Entry;
let userBox: Gtk.Entry;
let passBox: Gtk.Entry;

const reset = () => {
    siteBox.text = '';
    userBox.text = '';
    passBox.text = '';
};

const save = async () => {
    const site = siteBox?.text.trim();
    const user = userBox?.text.trim();
    const password = passBox?.text;
    if (!site || !user || !password) return;

    const body = user ? `${password}\nlogin: ${user}\n` : `${password}\n`;
    app.get_window('passSave')?.set_visible(false);

    try {
        await execAsync(['bash', '-c', `printf '%s' "$1" | pass insert -m -f "$2"`, 'bash', body, site]);
    } catch (e) {
        notifySend({ appName: 'Pass', title: 'Unable to save password' });
        return;
    }

    // Copy it
    await execAsync(['bash', '-c',
        `printf '%s' "$1" | wl-copy -n && sleep 0.15 && printf '%s' "$2" | wl-copy -n`,
        'bash', user, password
    ]);

    // Sync with homelab
    try {
        await execAsync(['bash', '-c',
            `pass git pull --rebase && { [ "$(pass git rev-list '@{u}..HEAD' --count)" -gt 0 ] && pass git push || true; }`
        ]);
    } catch (e) {
        notifySend({ appName: 'Pass', title: 'Pass sync to homelab failed' });
    }
};

export default () => inputControl('passSave', () =>
    <box halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER}>
        <BackgroundSection
            height={300} width={400}
            header={<label $type="overlay" label="Password"/>}
            content={
                <box orientation={Gtk.Orientation.VERTICAL} spacing={4}>
                    <entry
                        $={self => siteBox = self}
                        placeholderText="Website"
                        onActivate={() => userBox.grab_focus()} // next
                    />
                    <entry
                        $={self => userBox = self}
                        placeholderText="Username"
                        onActivate={() => passBox.grab_focus()} // next
                    />
                    <entry
                        $={self => passBox = self}
                        visibility={false}
                        placeholderText="Password"
                        onActivate={save} // save
                    />
                </box>
            }
        />
    </box>,
    () => { reset(); siteBox?.grab_focus(); }
);
