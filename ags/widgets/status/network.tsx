import { createState, For } from 'ags';
import { Gtk } from 'ags/gtk4';
import { execAsync } from 'ags/process';
import Gdk from 'gi://Gdk';
import Gio from 'gi://Gio';
import GLib from 'gi://GLib';
import { currentAsideWindow } from '../../lib/asideStatusWindow';
import { streamingMode } from '../notifications/notifications';

type WifiNet = { ssid: string; security: string; icon: string; connected: boolean; known: boolean; path: string };

// iwd config thingys
const station = 'wlan0';
const iwdBus = 'net.connman.iwd';
const deviceInterface = 'net.connman.iwd.Device';
const stationInterface = 'net.connman.iwd.Station';
const networkInterface = 'net.connman.iwd.Network';

const unwrap = (v: any): any => (v && typeof v === 'object' && 'data' in v) ? v.data : v;

const [ networks, setNetworks ] = createState<WifiNet[]>([]);
const [ scanning, setScanning ] = createState(false);
const [ wifiOn, setWifiOn ] = createState(true);

const openPopovers = new Set<Gtk.Popover>();
const closeAllPopovers = () => { for (const p of openPopovers) p.popdown(); };

const sigIcon = (mbm: number) => {
    const dbm = mbm / 100;
    const n = dbm >= -50 ? 4 : dbm >= -65 ? 3 : dbm >= -75 ? 2 : dbm >= -85 ? 1 : 0; // Signal is in 100*dBm units from iwd
    return `network-wireless-signal-${['none', 'weak', 'ok', 'good', 'excellent'][n]}-symbolic`;
};

const busctlJSON = (...args: string[]): Promise<any> =>
    execAsync(['busctl', '--json=short', 'call', iwdBus, ...args])
        .then(out => {
            const v = unwrap(JSON.parse(out.trim()));
            return Array.isArray(v) ? v[0] : v;
        });

const busctlAct = (...args: string[]) =>
    execAsync(['busctl', 'call', iwdBus, ...args]);

let stationPath = '';
let devicePath = '';

const systemBus = Gio.DBus.system;
let scanSubId = 0;
let scanTimeoutId = 0;

const clearScanTimeout = () => {
    if (scanTimeoutId) {
        GLib.source_remove(scanTimeoutId);
        scanTimeoutId = 0;
    };
};

const unsubscribeScan = () => {
    if (scanSubId) {
        systemBus.signal_unsubscribe(scanSubId);
        scanSubId = 0;
    };
    clearScanTimeout();
};

const finishScan = () => {
    unsubscribeScan();
    refresh().finally(() => setScanning(false));
};

const watchScanFinish = () => {
    unsubscribeScan();
    scanSubId = systemBus.signal_subscribe(
        iwdBus,
        'org.freedesktop.DBus.Properties',
        'PropertiesChanged',
        stationPath,
        stationInterface,
        Gio.DBusSignalFlags.NONE,
        (_bus, _sender, _path, _iface, _signal, params) => {
            const [, changed] = params.deep_unpack() as [string, Record<string, any>, string[]];
            if ('Scanning' in changed && changed.Scanning === false) finishScan();
        },
    );
    // Safety net
    scanTimeoutId = GLib.timeout_add(GLib.PRIORITY_DEFAULT, 8000, () => {
        scanTimeoutId = 0;
        finishScan();
        return GLib.SOURCE_REMOVE;
    });
};

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
            if (ifaces[deviceInterface]?.['Name'] === station) {
                devicePath = path;
                if (stationInterface in ifaces) stationPath = path;
            }
        }

        const powered: boolean = objects[devicePath]?.[deviceInterface]?.['Powered'] ?? true;
        setWifiOn(powered);

        if (!powered || !stationPath) {
            setNetworks([]);
            return;
        }

        const ordered: [string, number][] = await busctlJSON(stationPath, stationInterface, 'GetOrderedNetworks');

        setNetworks(
            ordered
                .map(([netPath, signalMbm]): WifiNet | null => {
                    const p = objects[netPath]?.[networkInterface];
                    if (!p?.['Name']) return null;
                    const kn = p['KnownNetwork'];
                    return {
                        ssid: p['Name'] as string,
                        security: p['Type'] as string,
                        icon: sigIcon(signalMbm),
                        connected: p['Connected'] as boolean,
                        known: typeof kn === 'string' && kn !== '' && kn !== '/',
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
            'busctl', 'call', iwdBus, devicePath,
            'org.freedesktop.DBus.Properties', 'Set',
            'ssv', deviceInterface, 'Powered', 'b', next ? 'true' : 'false',
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
        watchScanFinish();
        await busctlAct(stationPath, stationInterface, 'Scan').catch((e) => {
            if (!String(e).includes('Operation already in progress')) throw e;
        });
    } catch(e) {
        console.error('Scan error:', e);
        unsubscribeScan();
        setScanning(false);
    }
};

export default () =>
    <box orientation={Gtk.Orientation.VERTICAL}>
        <label
            visible={streamingMode}
            label="Streaming mode enabled"
            halign={Gtk.Align.CENTER}
        />
        <box visible={streamingMode.as(d => !d)} orientation={Gtk.Orientation.VERTICAL}>
        <box>
            <button
                hexpand halign={Gtk.Align.START}
                cssClasses={wifiOn.as(on => on ? ['active', 'wifiButton'] : ['unpowered', 'wifiButton'])}
                onClicked={toggleWifi}
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
                $={(self) => {
                    self.connect('map', refresh);
                    currentAsideWindow.subscribe(() => {
                        if (currentAsideWindow.peek() === 'wifi' && !wifiOn())
                            self.grab_focus();
                    });
                }}
            >
                <image iconName={wifiOn.as(on =>
                    on ? 'network-wireless-symbolic' : 'network-wireless-offline-symbolic'
                )}/>
            </button>
            <button
                onClicked={scan}
                sensitive={scanning.as(s => !s)}
                visible={wifiOn}
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
                cssClasses={scanning.as(s => s ? ['active'] : [])}
                $={(self) => {
                    currentAsideWindow.subscribe(() => {
                        if (currentAsideWindow.peek() === 'wifi' && wifiOn())
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
                let popover: Gtk.Popover | null = null;
                const submit = () => {
                    const pw = entry?.text ?? '';
                    const args = pw
                        ? ['iwctl', '--passphrase', pw, 'station', station, 'connect', net.ssid]
                        : ['iwctl', 'station', station, 'connect', net.ssid];
                    execAsync(args).then(() => { refresh(); popover?.popdown(); }).catch(() => {});
                };
                return <button
                    cursor={Gdk.Cursor.new_from_name('pointer', null)}
                    cssClasses={net.connected ? ['active'] : []}
                    onClicked={() => {
                        if (net.connected) {
                            busctlAct(stationPath, stationInterface, 'Disconnect')
                                .then(refresh).catch(() => {});
                        } else if (net.security !== 'open' && !net.known) {
                            if (!popover) return;
                            if (popover.get_visible()) popover.popdown();
                            else {
                                closeAllPopovers();
                                popover.popup();
                                entry?.grab_focus();
                            }
                        } else {
                            busctlAct(net.path, networkInterface, 'Connect')
                                .then(refresh).catch(() => {});
                        }
                    }}
                    $={(self) => {
                        popover = new Gtk.Popover();
                        popover.add_css_class('passwordRow');

                        entry = new Gtk.Entry({ hexpand: true, visibility: false, placeholderText: 'Password' });
                        entry.connect('activate', submit);

                        // todo jsx components
                        const row = new Gtk.Box();
                        row.append(entry);
                        popover.set_child(row);
                        popover.set_parent(self);

                        const p = popover;
                        p.connect('show', () => openPopovers.add(p));
                        p.connect('closed', () => openPopovers.delete(p));

                        self.connect('unrealize', () => {
                            openPopovers.delete(p);
                            p.unparent();
                        });
                    }}
                >
                    <box spacing={10}>
                        <image iconName={net.icon}/>
                        <label hexpand halign={Gtk.Align.START} label={net.ssid} ellipsize={3}/>
                        {net.security !== 'open' && <image iconName="network-wireless-encrypted-symbolic"/>}
                    </box>
                </button>;
            }}
        </For>
        </box>
    </box>
