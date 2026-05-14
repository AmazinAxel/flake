import BluetoothService from 'gi://AstalBluetooth';
import { createBinding, For } from 'ags';
import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import sidebarWindow from '../../lib/sidebarWindow';

const bluetooth = BluetoothService.get_default();
const isMac = (d: BluetoothService.Device) => d.alias.replaceAll('-', ':') === d.address;

const devicesBind = createBinding(bluetooth, 'devices')((devs: BluetoothService.Device[]) =>
    devs.filter(d => !isMac(d)).sort((a, b) => {
        if (a.connected !== b.connected) return a.connected ? -1 : 1;
        if (a.paired !== b.paired) return a.paired ? -1 : 1;
        return a.alias.localeCompare(b.alias);
    })
);

const nameSubstitute = (name: string) => {
	if (!name) return '';
	
	if (name == 'S80A') {
		return "Touchscreen Earbuds";
	} else if (name == 'MINI_KEYBOARD') {
		return "2-key Presenter";
	} else if (name == 'K38') {
		return 'Karaoke Speaker';
	} else if (name == 'MOU-302') {
		return 'Ergo Mouse';
    };
	return name;
};


const BluetoothMenu = () =>
    <box orientation={Gtk.Orientation.VERTICAL}>
        <box spacing={4} marginBottom={7}>
            <button
                hexpand
                halign={Gtk.Align.START}
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
                onClicked={() => bluetooth.toggle()}
                $={(self) => {
                    const update = () => { self.cssClasses = bluetooth.isPowered ? ['active'] : []; };
                    bluetooth.connect('notify::is-powered', update);
                    update();
                }}
            >
                <image iconName="bluetooth-active-symbolic"/>
            </button>
            <button
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
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
        </box>
        <Gtk.Separator/>
        <Gtk.ScrolledWindow hscrollbarPolicy={Gtk.PolicyType.NEVER} hexpand vexpand propagateNaturalWidth propagateNaturalHeight maxContentHeight={500}>
            <box orientation={Gtk.Orientation.VERTICAL}>
            <For each={devicesBind}>
                {(device: BluetoothService.Device) => {
                    const connectedBind = createBinding(device, 'connected');
                    const connectingBind = createBinding(device, 'connecting');
                    const batteryBind = createBinding(device, 'batteryPercentage');
                    return <box cssClasses={['deviceRow']} spacing={8}>
                        <image iconName={(device.icon ? device.icon + '-symbolic' : 'bluetooth-symbolic')}/>
                        <box orientation={Gtk.Orientation.VERTICAL} hexpand valign={Gtk.Align.CENTER}>
                            <label label={nameSubstitute(device.alias)} halign={Gtk.Align.START} ellipsize={3}/>
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
                            onClicked={() => {
                                if (device.connected) device.disconnect_device();
                                else {
                                    if (bluetooth.adapter?.discovering) bluetooth.adapter.stop_discovery();
                                    if (device.paired) device.connect_device();
                                    else device.pair();
                                }
                            }}
                            cssClasses={connectedBind((c: boolean) => c ? ['active'] : [])}
                        >
                            <image iconName={connectedBind((c: boolean) => c ? 'network-disconnect-symbolic' : 'network-transmit-symbolic')}/>
                        </button>
                        <button
                            cursor={Gdk.Cursor.new_from_name('pointer', null)}
                            onClicked={() => bluetooth.adapter?.remove_device(device)}
                        >
                            <image iconName="edit-delete-symbolic"/>
                        </button>
                    </box>;
                }}
            </For>
            </box>
        </Gtk.ScrolledWindow>
    </box>;

export default () => sidebarWindow('bluetooth', BluetoothMenu);
