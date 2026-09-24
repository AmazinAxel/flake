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

const switchToBluetoothSink = (address: string) => {
    if (!audio) return;
    const wanted = address.replaceAll(':', '_');
    const find = () => audio.speakers.find(s =>
        (s.get_pw_property('node.name') ?? '').includes(wanted));

    let id = 0;
    const take = () => {
        const sink = find();
        if (!sink) return false;
        sink.isDefault = true;
        return true;
    };
    const stop = () => { if (id) { audio.disconnect(id); id = 0; } };

    if (take()) return;
    id = audio.connect('notify::speakers', () => take() && stop());
    timeout(10000, stop);
};

const [ discovering, setDiscovering ] = createState(false);
const wireAdapter = (adapter: BluetoothService.Adapter | null) => {
    if (!adapter) return;
    setDiscovering(adapter.discovering);
    adapter.connect('notify::discovering', () => setDiscovering(adapter.discovering));
};
wireAdapter(bluetooth.adapter);
bluetooth.connect('notify::adapter', () => wireAdapter(bluetooth.adapter));

const devicesBind = createBinding(bluetooth, 'devices');

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
    hasName(d.alias, d.address) && (d.paired || d.trusted || d.connected || discovering.peek());

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

export default () =>
    <box orientation={Gtk.Orientation.VERTICAL}>
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
                    adapter.discovering ? adapter.stop_discovery() : adapter.start_discovery();
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
                <For each={devicesBind}>
                    {(device: BluetoothService.Device) => {
                        const connected = createBinding(device, 'connected');
                        const connecting = createBinding(device, 'connecting');
                        const battery = createBinding(device, 'batteryPercentage');
                        const paired = createBinding(device, 'paired');
                        const trusted = createBinding(device, 'trusted');
                        const alias = createBinding(device, 'alias');

                        const visible = createComputed((track) =>
                            hasName(track(alias), device.address)
                                && (track(paired) || track(trusted) || track(connected) || track(discovering)));

                        const connectAndSwitch = () => device.connect_device((_, res) => {
                            device.connect_device_finish(res);
                            switchToBluetoothSink(device.address);
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
                                    return device.disconnect_device((_, res) => device.disconnect_device_finish(res));

                                if (bluetooth.adapter?.discovering) bluetooth.adapter.stop_discovery();
                                device.trusted = true; // adds to list
                                if (device.paired) return connectAndSwitch();

                                const id = device.connect('notify::paired', () => {
                                    if (!device.paired) return;
                                    device.disconnect(id);
                                    connectAndSwitch();
                                });
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
