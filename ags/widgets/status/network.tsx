import { createState, For } from 'ags';
import { Gtk } from 'ags/gtk4';
import { execAsync } from 'ags/process';
import Gdk from 'gi://Gdk';
import asideStatusWindow from '../../lib/asideStatusWindow';
import app from 'ags/gtk4/app';

type WifiNet = { ssid: string; security: string; strength: number; connected: boolean; path: string };

const STATION = 'wlan0';
const IWD_BUS = 'net.connman.iwd';
const DEVICE_IFACE = 'net.connman.iwd.Device';
const STATION_IFACE = 'net.connman.iwd.Station';
const NETWORK_IFACE = 'net.connman.iwd.Network';

const [ networks, setNetworks ] = createState<WifiNet[]>([]);
const [ scanning, setScanning ] = createState(false);
const [ pendingSSID, setPendingSSID ] = createState<string | null>(null);
const [ wifiOn, setWifiOn ] = createState(true);

const sigIcon = (n: number) => [
    'network-wireless-signal-none-symbolic',
    'network-wireless-signal-weak-symbolic',
    'network-wireless-signal-ok-symbolic',
    'network-wireless-signal-good-symbolic',
    'network-wireless-signal-excellent-symbolic',
][Math.min(Math.max(n, 0), 4)];

// Signal is in 100*dBm units from iwd (e.g. -7000 = -70 dBm)
const dbmToStrength = (mbm: number) => {
    const dbm = mbm / 100;
    return dbm >= -50 ? 4 : dbm >= -65 ? 3 : dbm >= -75 ? 2 : dbm >= -85 ? 1 : 0;
};

// busctl --json=short wraps variant values as {type, data}; unwrap to the plain value
const unwrap = (v: any): any => (v && typeof v === 'object' && 'data' in v) ? v.data : v; // todo clean

// busctl call returning parsed JSON data
// busctl always wraps the return value in an outer array; unwrap both layers
const busctlJSON = (...args: string[]): Promise<any> =>
    execAsync(['busctl', '--json=short', 'call', IWD_BUS, ...args])
        .then(out => {
            const v = unwrap(JSON.parse(out.trim()));
            return Array.isArray(v) ? v[0] : v;
        });

// busctl call with no return value needed (scan, disconnect, connect)
const busctlAct = (...args: string[]) =>
    execAsync(['busctl', 'call', IWD_BUS, ...args]);

let stationPath = '';
let devicePath = '';

type ObjMap = Record<string, Record<string, Record<string, any>>>;

const getObjects = async (): Promise<ObjMap> => {
    const raw: any = await busctlJSON('/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects');

    // Unwrap variant values one level deep
    const result: ObjMap = {};
    for (const [path, ifaces] of Object.entries(raw as Record<string, unknown>)) {
        result[path] = {};
        for (const [iface, props] of Object.entries(ifaces as Record<string, unknown>)) {
            result[path][iface] = Object.fromEntries(
                Object.entries(props as Record<string, unknown>).map(([k, v]) => [k, unwrap(v)])
            );
        }
    }
    return result;
};

const refresh = async () => {
    try {
        const objects = await getObjects();

        // Locate device and station paths
        for (const [path, ifaces] of Object.entries(objects)) {
            if (ifaces[DEVICE_IFACE]?.['Name'] === STATION) {
                devicePath = path;
                if (STATION_IFACE in ifaces) stationPath = path;
            }
        }

        const powered: boolean = objects[devicePath]?.[DEVICE_IFACE]?.['Powered'] ?? true;
        setWifiOn(powered);

        if (!powered || !stationPath) {
            setNetworks([]);
            return;
        }

        // GetOrderedNetworks → a(on): [[objectPath, signalMbm], ...]
        const ordered: [string, number][] = await busctlJSON(stationPath, STATION_IFACE, 'GetOrderedNetworks');

        setNetworks(
            ordered
                .map(([netPath, signalMbm]): WifiNet | null => {
                    const p = objects[netPath]?.[NETWORK_IFACE];
                    if (!p?.['Name']) return null;
                    return {
                        ssid: p['Name'] as string,
                        security: p['Type'] as string,
                        strength: dbmToStrength(signalMbm),
                        connected: p['Connected'] as boolean,
                        path: netPath,
                    };
                })
                .filter((n): n is WifiNet => n !== null)
                .sort((a, b) => Number(b.connected) - Number(a.connected))
        );
    } catch(e) {
        console.error('Network refresh error:', e);
    }
};

const toggleWifi = async () => {
    try {
        if (!devicePath) await refresh();
        const next = !wifiOn();
        await execAsync([
            'busctl', 'call', IWD_BUS, devicePath,
            'org.freedesktop.DBus.Properties', 'Set',
            'ssv', DEVICE_IFACE, 'Powered', 'b', next ? 'true' : 'false',
        ]);
        setWifiOn(next);
        if (!next) setNetworks([]);
        else await refresh();
    } catch(e) {
        console.error('WiFi toggle error:', e);
    }
};

const scan = async () => {
    if (scanning()) return;
    setScanning(true);
    try {
        if (!stationPath) await refresh();
        await busctlAct(stationPath, STATION_IFACE, 'Scan');
        setTimeout(() => { refresh().finally(() => setScanning(false)); }, 3000);
    } catch(e) {
        console.error('Scan error:', e);
        setScanning(false);
    }
};

export default () => asideStatusWindow('wifi', () =>
    <box orientation={Gtk.Orientation.VERTICAL}>
        <box spacing={4} marginBottom={7}>
            <button
                hexpand halign={Gtk.Align.START}
                cssClasses={wifiOn.as(on => on ? ['active'] : [])}
                onClicked={toggleWifi}
		cursor={Gdk.Cursor.new_from_name('pointer', null)}
                $={(self) => { self.connect('map', scan); }}
            >
                <image iconName={wifiOn.as(on =>
                    on ? 'network-wireless-symbolic' : 'network-wireless-offline-symbolic'
                )}/>
            </button>
            <button
                onClicked={scan}
                sensitive={scanning.as(s => !s)}
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
                $={(self) => {
                    app.connect('window-toggled', () => {
                        if (app.get_window('bluetooth')?.visible == true)
                            self.grab_focus();
                    });
                }}
            >
                <image iconName="view-refresh-symbolic"/>
            </button>
        </box>
        <Gtk.Separator visible={wifiOn}/>
        <For each={networks}>
            {(net: WifiNet) => {
                let entry: Gtk.Entry | null = null;
                return <box orientation={Gtk.Orientation.VERTICAL}>
                    <button
                        cursor={Gdk.Cursor.new_from_name('pointer', null)}
                        cssClasses={net.connected ? ['active'] : []}
                        onClicked={() => {
                            if (net.connected) {
                                busctlAct(stationPath, STATION_IFACE, 'Disconnect')
                                    .then(refresh).catch(() => {});
                            } else if (net.security !== 'open') {
                                setPendingSSID(pendingSSID() === net.ssid ? null : net.ssid);
                            } else {
                                busctlAct(net.path, NETWORK_IFACE, 'Connect')
                                    .then(refresh).catch(() => {});
                            }
                        }}
                    >
                        <box spacing={8}>
                            <image iconName={sigIcon(net.strength)}/>
                            <label hexpand halign={Gtk.Align.START} label={net.ssid} ellipsize={3}/>
                            {net.security !== 'open' && <image iconName="network-wireless-encrypted-symbolic"/>}
                        </box>
                    </button>
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
    </box>
);
