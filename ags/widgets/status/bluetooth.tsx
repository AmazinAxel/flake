import BluetoothService from 'gi://AstalBluetooth';
import { createBinding, createComputed, createState, For, onCleanup } from 'ags';
import { Gtk } from 'ags/gtk4';
import Wp from 'gi://AstalWp';
import GLib from 'gi://GLib';
import { currentAsideWindow } from '../../lib/asideStatusWindow';
import { timeout } from 'ags/time';

const bluetooth = BluetoothService.get_default();
const audio = Wp.get_default()?.audio; // for auto-sink switching
const bluetoothOn = createBinding(bluetooth, 'isPowered');

const hook = <T extends { connect(s: string, cb: () => void): number; disconnect(id: number): void }>(
    obj: T | null | undefined, signal: string, cb: () => void,
) => {
    const id = obj?.connect(signal, cb);
    if (id) onCleanup(() => obj!.disconnect(id));
};

let pendingSinkId = 0;
const switchToBluetoothSink = (address: string) => {
    if (!audio) return;
    const wanted = address.replaceAll(':', '_');
    const take = () => {
        const sink = audio.speakers.find(s =>
            (s.get_pw_property('node.name') ?? '').includes(wanted));
        if (!sink) return false;
        sink.isDefault = true;
        return true;
    };
    const stop = () => { if (pendingSinkId) { audio.disconnect(pendingSinkId); pendingSinkId = 0; } };

    stop();
    if (take()) return;
    const id = pendingSinkId = audio.connect('notify::speakers', () => take() && stop());
    timeout(10000, () => pendingSinkId === id && stop());
};

const [ discovering, setDiscovering ] = createState(false);
let adapterId = 0;
let wiredAdapter: BluetoothService.Adapter | null = null;
const wireAdapter = (adapter: BluetoothService.Adapter | null) => {
    if (wiredAdapter && adapterId) wiredAdapter.disconnect(adapterId);
    wiredAdapter = adapter;
    adapterId = 0;
    if (!adapter) return setDiscovering(false);
    setDiscovering(adapter.discovering);
    adapterId = adapter.connect('notify::discovering', () => setDiscovering(adapter.discovering));
};
wireAdapter(bluetooth.adapter);
bluetooth.connect('notify::adapter', () => wireAdapter(bluetooth.adapter));

const [ stickyKeys, setStickyKeys ] = createState<ReadonlySet<string>>(new Set());
const stickyAdd = (address: string) => {
    if (stickyKeys.peek().has(address)) return;
    const next = new Set(stickyKeys.peek());
    next.add(address);
    setStickyKeys(next);
};
const stickyClear = () => stickyKeys.peek().size && setStickyKeys(new Set());

let scanToken = 0;

const devicesBind = createBinding(bluetooth, 'devices');
const menuOpen = currentAsideWindow((a) => a === 'bluetooth');
const visibleDevices = createComputed((track) =>
    track(menuOpen) ? track(devicesBind) : []);

const hasName = (alias: string, address: string) =>
    !!alias && alias.replaceAll('-', ':') != address;
const NAMES: Record<string, string> = {
    S80A: 'Touchscreen Earbuds',
    MINI_KEYBOARD: '2-key Presenter',
    K38: 'Karaoke Speaker',
    'MOU-302': 'Ergo Mouse',
};
const nameSubstitute = (name: string) => NAMES[name] ?? name ?? '';

const listed = (d: BluetoothService.Device) =>
    hasName(d.alias, d.address)
        && (d.paired || d.trusted || d.connected || discovering.peek() || stickyKeys.peek().has(d.address));

const firstListed = () => {
    const devices = devicesBind.peek();
    return devices.find(d => d.connected && listed(d)) ?? devices.find(listed) ?? null;
};

let focusedDevice: BluetoothService.Device | null = null;
const focusDevice = () => (focusedDevice && listed(focusedDevice) ? focusedDevice : firstListed());

const focusOnOpen = (self: Gtk.Widget, when: () => boolean) =>
    onCleanup(currentAsideWindow.subscribe(() => {
        if (currentAsideWindow.peek() !== 'bluetooth') return;
        GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE, () => {
            if (currentAsideWindow.peek() === 'bluetooth' && when()) self.grab_focus();
            return GLib.SOURCE_REMOVE;
        });
    }));

const wireMenuLifecycle = () =>
    onCleanup(currentAsideWindow.subscribe(() => {
        if (currentAsideWindow.peek() === 'bluetooth') return;
        if (bluetooth.adapter?.discovering) bluetooth.adapter.stop_discovery();
        stickyClear();
    }));

export default () =>
    <box orientation={Gtk.Orientation.VERTICAL} $={wireMenuLifecycle}>
        <box>
            <button
                hexpand halign={Gtk.Align.START}
                onClicked={() => bluetooth.toggle()}
                cssClasses={bluetoothOn.as(power => [power ? 'active' : 'unpowered', 'bluetoothButton'])}
                $={(self) => focusOnOpen(self, () => !bluetooth.isPowered)}
            >
                <image iconName="bluetooth-active-symbolic"/>
            </button>
            <button
                onClicked={() => {
                    const adapter = bluetooth.adapter;
                    if (!adapter) return;
                    if (adapter.discovering) return adapter.stop_discovery();
                    adapter.start_discovery();
                    const token = ++scanToken;
                    timeout(60000, () => {
                        if (token === scanToken && bluetooth.adapter?.discovering)
                            bluetooth.adapter.stop_discovery();
                    });
                }}
                visible={bluetoothOn}
                cssClasses={discovering.as((d) => d ? ['active'] : [])}
                $={(self) => focusOnOpen(self, () => bluetooth.isPowered && !focusDevice())}
            >
                <image iconName="view-refresh-symbolic"/>
            </button>
        </box>
        <Gtk.Separator visible={bluetoothOn}/>
        <Gtk.ScrolledWindow
            hscrollbarPolicy={Gtk.PolicyType.NEVER}
            hexpand vexpand
            propagateNaturalWidth propagateNaturalHeight
            maxContentHeight={500}
            visible={bluetoothOn}
            $={(self) => hook(bluetooth, 'notify::is-powered', () => {
                if (bluetooth.isPowered && !focusDevice())
                    self.get_first_child()?.get_first_child()?.get_first_child()?.grab_focus();
            })}
        >
            <box orientation={Gtk.Orientation.VERTICAL}>
                <For each={visibleDevices}>
                    {(device: BluetoothService.Device) => {
                        const connected = createBinding(device, 'connected');
                        const connecting = createBinding(device, 'connecting');
                        const battery = createBinding(device, 'batteryPercentage');
                        const paired = createBinding(device, 'paired');
                        const trusted = createBinding(device, 'trusted');
                        const alias = createBinding(device, 'alias');

                        const visible = createComputed((track) =>
                            hasName(track(alias), device.address)
                                && (track(paired) || track(trusted) || track(connected)
                                    || track(discovering) || track(stickyKeys).has(device.address)));

                        let pairId = 0;
                        const stopPairWatch = () => {
                            if (pairId) device.disconnect(pairId);
                            pairId = 0;
                        };
                        onCleanup(stopPairWatch);

                        const connectAndSwitch = () => device.connect_device((_, res) => {
                            try {
                                device.connect_device_finish(res);
                                switchToBluetoothSink(device.address);
                            } catch {};
                        });

                        return <button hexpand
                            visible={visible}
                            sensitive={connecting(c => !c)}
                            $={(self) => {
                                const refocus = () => {
                                    if (currentAsideWindow.peek() === 'bluetooth'
                                        && focusDevice() === device && self.get_mapped())
                                        self.grab_focus();
                                };
                                focusOnOpen(self, () => focusDevice() === device && self.get_mapped());

                                self.connect('state-flags-changed', () => {
                                    if (self.has_focus) focusedDevice = device; // remember
                                });

                                const later = () => GLib.idle_add(GLib.PRIORITY_DEFAULT_IDLE,
                                    () => { refocus(); return GLib.SOURCE_REMOVE; });
                                hook(device, 'notify::connected', later);
                                hook(device, 'notify::connecting', later);

                                onCleanup(() => {
                                    if (focusedDevice === device) focusedDevice = null; // row gone
                                });
                            }}
                            onClicked={() => {
                                focusedDevice = device; // keep focus here
                                if (device.connected)
                                    return device.disconnect_device((_, res) => { try { device.disconnect_device_finish(res); } catch {}; });

                                stickyAdd(device.address);
                                if (bluetooth.adapter?.discovering) bluetooth.adapter.stop_discovery();
                                if (device.paired) {
                                    device.trusted = true;
                                    return connectAndSwitch();
                                }

                                stopPairWatch();
                                const id = pairId = device.connect('notify::paired', () => {
                                    if (!device.paired) return;
                                    stopPairWatch();
                                    device.trusted = true;
                                    connectAndSwitch();
                                });
                                timeout(30000, () => pairId === id && stopPairWatch());
                                device.pair();
                            }}
                            cssClasses={createComputed((track) =>
                                track(connecting) ? ['connecting']
                                : track(connected) ? ['active']
                                : []
                            )}
                        >
                            <Gtk.EventControllerKey onKeyPressed={(_, key) => {
                                if (key == 65288 && (device.paired || device.trusted) && !bluetooth.adapter?.discovering)
                                    bluetooth.adapter?.remove_device(device);
                            }}/>
                            <box orientation={Gtk.Orientation.HORIZONTAL} hexpand valign={Gtk.Align.CENTER} spacing={10}>
                                <image iconName={device.icon + '-symbolic'}/>
                                <label label={alias(nameSubstitute)} halign={Gtk.Align.START} hexpand ellipsize={3}/>
                                <label
                                    visible={createComputed((track) => track(connected) && track(battery) >= 0)}
                                    label={battery((p) => Math.round(p * 100) + '%')}
                                    halign={Gtk.Align.END}
                                />
                            </box>
                        </button>
                    }}
                </For>
            </box>
        </Gtk.ScrolledWindow>
    </box>
