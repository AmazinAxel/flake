import BluetoothService from 'gi://AstalBluetooth';
import { createBinding, For } from 'ags';
import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import sidebarWindow from '../../lib/sidebarWindow';

const bluetooth = BluetoothService.get_default();

const isMac = (s: string) => /^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$/i.test(s);
const deviceName = (d: BluetoothService.Device) => d.alias || d.name || '';
const hasName = (d: BluetoothService.Device) => { const n = deviceName(d); return n.length > 0 && !isMac(n); };

const devicesBind = createBinding(bluetooth, 'devices')((devs: BluetoothService.Device[]) =>
    devs.filter(hasName).sort((a, b) => {
        if (a.connected !== b.connected) return a.connected ? -1 : 1;
        if (a.paired !== b.paired) return a.paired ? -1 : 1;
        return deviceName(a).localeCompare(deviceName(b));
    })
);

const Content = () =>
    <box orientation={Gtk.Orientation.VERTICAL}>
        <box cssClasses={['widgetHeader']} spacing={4}>
            <image iconName="bluetooth-symbolic"/>
            <label label="Bluetooth" hexpand halign={Gtk.Align.START}/>
            <button
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
                tooltipText="Scan"
                onClicked={() => {
                    const adapter = bluetooth.adapter;
                    if (!adapter) return;
                    adapter.discovering ? adapter.stop_discovery() : adapter.start_discovery();
                }}
                $={(self) => {
                    const update = () => { self.cssClasses = bluetooth.adapter?.discovering ? ['active'] : []; };
                    bluetooth.adapter?.connect('notify::discovering', update);
                    update();
                }}
            >
                <image iconName="view-refresh-symbolic"/>
            </button>
            <button
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
                tooltipText="Toggle Bluetooth"
                onClicked={() => bluetooth.toggle()}
                $={(self) => {
                    const update = () => { self.cssClasses = bluetooth.isPowered ? ['active'] : []; };
                    bluetooth.connect('notify::is-powered', update);
                    update();
                }}
            >
                <image iconName="bluetooth-active-symbolic"/>
            </button>
        </box>
        <For each={devicesBind}>
            {(device: BluetoothService.Device) => {
                const connectedBind = createBinding(device, 'connected');
                const connectingBind = createBinding(device, 'connecting');
                const batteryBind = createBinding(device, 'batteryPercentage');
                return <box cssClasses={['deviceRow']} spacing={8}>
                    <image iconName={(device.icon ? device.icon + '-symbolic' : 'bluetooth-symbolic')}/>
                    <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
                        <label label={deviceName(device)} halign={Gtk.Align.START} ellipsize={3}/>
                        <label
                            visible={batteryBind((p: number) => p >= 0)}
                            label={batteryBind((p: number) => p >= 0 ? `${Math.round(p)}%` : '')}
                            cssClasses={['deviceBattery']}
                            halign={Gtk.Align.START}
                        />
                    </box>
                    <button
                        cursor={Gdk.Cursor.new_from_name('pointer', null)}
                        sensitive={connectingBind((c: boolean) => !c)}
                        tooltipText={connectedBind((c: boolean) => c ? 'Disconnect' : (device.paired ? 'Connect' : 'Pair'))}
                        onClicked={() => {
                            if (device.connected) device.disconnect_device();
                            else if (device.paired) device.connect_device();
                            else device.pair();
                        }}
                        cssClasses={connectedBind((c: boolean) => c ? ['active'] : [])}
                    >
                        <image iconName={connectedBind((c: boolean) => c ? 'network-disconnect-symbolic' : 'network-transmit-symbolic')}/>
                    </button>
                    <button
                        cursor={Gdk.Cursor.new_from_name('pointer', null)}
                        tooltipText="Remove"
                        onClicked={() => bluetooth.adapter?.remove_device(device)}
                    >
                        <image iconName="edit-delete-symbolic"/>
                    </button>
                </box>;
            }}
        </For>
    </box>;

export default () => sidebarWindow('bluetooth', Content);
