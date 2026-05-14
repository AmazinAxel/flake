import BluetoothService from 'gi://AstalBluetooth';
import { createBinding, For } from 'ags';
import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import asideStatusWindow from '../../lib/asideStatusWindow';
import app from 'ags/gtk4/app';

const bluetooth = BluetoothService.get_default();
const isMac = (d: BluetoothService.Device) => d.alias.replaceAll('-', ':') === d.address;

const devicesBind = createBinding(bluetooth, 'devices')((devs: BluetoothService.Device[]) =>
    devs.filter(d => !isMac(d)).sort((a, b) => {
        if (a.connected !== b.connected) return a.connected ? -1 : 1;
        if (a.paired !== b.paired) return a.paired ? -1 : 1;
        return a.alias.localeCompare(b.alias);
    })
);

const bluetoothOn = createBinding(bluetooth, 'isPowered');

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


export default () => asideStatusWindow('bluetooth', () =>
    <box orientation={Gtk.Orientation.VERTICAL}>
        <box spacing={4} marginBottom={7}>
            <button
                hexpand
                halign={Gtk.Align.START}
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
                onClicked={() => bluetooth.toggle()}
                cssClasses={bluetoothOn.as(power => power ? ['active', 'bluetoothButton'] : ['unpowered', 'bluetoothButton'])}
                $={(self) => {
                    app.connect('window-toggled', () => {
                        if (app.get_window('bluetooth')?.visible == true && !bluetooth.isPowered)
                            self.grab_focus();
                    });
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
                visible={bluetoothOn}
                $={(self) => {
                    const update = () => { self.cssClasses = bluetooth.adapter?.discovering ? ['active'] : []; };
                    bluetooth.adapter?.connect('notify::discovering', update);
                    update();
                }}
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
            // TODO when bluetooth is turned on, it should grab the first child in this list and focus it
            //$={(self) => (bluetooth.isPowered) && self.get_first_child()?.get_first_child()?.grab_focus()} // todo
        >
            <box orientation={Gtk.Orientation.VERTICAL} spacing={5}>
                <For each={devicesBind}>
                    {(device: BluetoothService.Device) => {
                        const connectedBind = createBinding(device, 'connected');
                        const connectingBind = createBinding(device, 'connecting');
                        const batteryBind = createBinding(device, 'batteryPercentage');
                        return <button hexpand
                            sensitive={connectingBind(c => !c)}
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
                            <Gtk.EventControllerKey onKeyPressed={(_, key) => (key == 65288) && bluetooth.adapter?.remove_device(device)}/>
                            <box orientation={Gtk.Orientation.HORIZONTAL} hexpand valign={Gtk.Align.CENTER} spacing={10}>
                                <image iconName={device.icon + '-symbolic'}/>
                                <label label={nameSubstitute(device.alias)} halign={Gtk.Align.START} ellipsize={3}/>
                                <label
                                    visible={batteryBind((p: number) => p >= 0)}
                                    label={batteryBind((p: number) => p >= 0 ? `${Math.round(p)}%` : '')}
                                    cssClasses={['deviceBattery']}
                                    halign={Gtk.Align.START}
                                />
                                <image hexpand halign={Gtk.Align.END} iconName={connectedBind((c: boolean) => c ? 'network-disconnect-symbolic' : 'network-transmit-symbolic')}/>
                            </box>
                        </button>
                    }}
                </For>
            </box>
        </Gtk.ScrolledWindow>
    </box>
);
