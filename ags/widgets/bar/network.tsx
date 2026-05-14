import { createState, For } from 'ags';
import { Gtk } from 'ags/gtk4';
import { execAsync } from 'ags/process';
import Gdk from 'gi://Gdk';
import sidebarWindow from '../../lib/sidebarWindow';

type WifiNet = { ssid: string; security: string; strength: number; connected: boolean };

const STATION = 'wlan0';
const [networks, setNetworks] = createState<WifiNet[]>([]);
const [scanning, setScanning] = createState(false);
const [pendingSSID, setPendingSSID] = createState<string | null>(null);

const sigIcon = (n: number) => [
    'network-wireless-signal-none-symbolic',
    'network-wireless-signal-weak-symbolic',
    'network-wireless-signal-ok-symbolic',
    'network-wireless-signal-good-symbolic',
    'network-wireless-signal-excellent-symbolic',
][Math.min(Math.max(n, 0), 4)];

const parseNetworks = (raw: string): WifiNet[] => {
    const clean = raw.replace(/\x1b\[[0-9;]*m/g, '');
    return clean.split('\n')
        .filter(l => /^\s{2,}[> ]/.test(l) && !/Network name|Available networks/.test(l))
        .map(line => {
            const connected = />\s/.test(line);
            const cols = line.replace('>', ' ').trim().split(/\s{2,}/);
            return {
                connected,
                ssid: (cols[0] ?? '').trim(),
                security: (cols[1] ?? 'open').trim(),
                strength: (cols[2] ?? '').replace(/\s/g, '').length,
            };
        })
        .filter(n => n.ssid && !/^[-=]+$/.test(n.ssid));
};

const refresh = () =>
    execAsync(['iwctl', 'station', STATION, 'get-networks'])
        .then(out => setNetworks(
            parseNetworks(out).sort((a, b) => Number(b.connected) - Number(a.connected))
        ))
        .catch(() => {});

const scan = () => {
    if (scanning()) return;
    setScanning(true);
    execAsync(['iwctl', 'station', STATION, 'scan'])
        .then(() => setTimeout(() => { refresh(); setScanning(false); }, 3000))
        .catch(() => setScanning(false));
};

const Content = () =>
    <box orientation={Gtk.Orientation.VERTICAL}
        $={(self) => { self.connect('map', refresh); }}>
        <box cssClasses={['widgetHeader']} spacing={4}>
            <image iconName="network-wireless-symbolic"/>
            <label label="Wi-Fi" hexpand halign={Gtk.Align.START}/>
            <button
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
                onClicked={scan}
                $={(self) => { scanning.subscribe(() => { self.sensitive = !scanning(); }); }}
            >
                <image iconName="view-refresh-symbolic"/>
            </button>
        </box>
        <For each={networks}>
            {(net: WifiNet) => {
                let entry: Gtk.Entry | null = null;
                return <box orientation={Gtk.Orientation.VERTICAL}>
                    <box cssClasses={['networkRow']} spacing={8}>
                        <image iconName={sigIcon(net.strength)}/>
                        <label hexpand halign={Gtk.Align.START} label={net.ssid} ellipsize={3}/>
                        {net.security !== 'open' && <image iconName="network-wireless-encrypted-symbolic"/>}
                        <button
                            cursor={Gdk.Cursor.new_from_name('pointer', null)}
                            cssClasses={net.connected ? ['active'] : []}
                            onClicked={() => {
                                if (net.connected) {
                                    execAsync(['iwctl', 'station', STATION, 'disconnect']).then(refresh).catch(() => {});
                                } else if (net.security !== 'open') {
                                    setPendingSSID(pendingSSID() === net.ssid ? null : net.ssid);
                                } else {
                                    execAsync(['iwctl', 'station', STATION, 'connect', net.ssid]).then(refresh).catch(() => {});
                                }
                            }}
                        >
                            <image iconName={net.connected ? 'network-disconnect-symbolic' : 'network-transmit-symbolic'}/>
                        </button>
                    </box>
                    <box cssClasses={['passwordRow']} spacing={6} visible={false}
                        $={(self) => {
                            pendingSSID.subscribe(() => { self.visible = pendingSSID() === net.ssid; });
                        }}
                    >
                        <Gtk.Entry
                            hexpand
                            visibility={false}
                            placeholderText="Password"
                            $={(self) => {
                                entry = self;
                                self.connect('activate', () => {
                                    const args = self.text
                                        ? ['iwctl', '--passphrase', self.text, 'station', STATION, 'connect', net.ssid]
                                        : ['iwctl', 'station', STATION, 'connect', net.ssid];
                                    execAsync(args).then(() => { refresh(); setPendingSSID(null); }).catch(() => {});
                                });
                            }}
                        />
                        <button
                            cursor={Gdk.Cursor.new_from_name('pointer', null)}
                            onClicked={() => {
                                const pw = entry?.text ?? '';
                                const args = pw
                                    ? ['iwctl', '--passphrase', pw, 'station', STATION, 'connect', net.ssid]
                                    : ['iwctl', 'station', STATION, 'connect', net.ssid];
                                execAsync(args).then(() => { refresh(); setPendingSSID(null); }).catch(() => {});
                            }}
                        >
                            <label label="Connect"/>
                        </button>
                    </box>
                </box>;
            }}
        </For>
    </box>;

export default () => sidebarWindow('wifi', Content);
