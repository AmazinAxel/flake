import BluetoothService from 'gi://AstalBluetooth';
import { createBinding, For } from 'ags';
import { Gtk } from 'ags/gtk4';
import Gdk from 'gi://Gdk';
import Wp from 'gi://AstalWp';
import asideStatusWindow from '../../lib/asideStatusWindow';
import app from 'ags/gtk4/app';

const bluetooth = BluetoothService.get_default();
const audio = Wp.get_default()?.audio; // for auto-sink switching
const bluetoothOn = createBinding(bluetooth, 'isPowered');
const discovering = createBinding(bluetooth.adapter, 'discovering');

const devicesBind = createBinding(bluetooth, 'devices')((devs: BluetoothService.Device[]) =>
    devs.filter(d => d.alias.replaceAll('-', ':') != d.address) // not a mac
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
                    adapter.discovering ? adapter.stop_discovery() : adapter.start_discovery();
                }}
                visible={bluetoothOn}
                cssClasses={discovering.as((d) => d ? ['active'] : [])}
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
            $={(self) => {
                bluetooth.connect('notify::is-powered', () => {
                    if (bluetooth.isPowered)
                        self.get_first_child()?.get_first_child()?.get_first_child()?.grab_focus();
                });
            }}
        >
            <box orientation={Gtk.Orientation.VERTICAL}>
                <For each={devicesBind}>
                    {(device: BluetoothService.Device) => {
                        const connectedBind = createBinding(device, 'connected');
                        const connectingBind = createBinding(device, 'connecting');
                        const batteryBind = createBinding(device, 'batteryPercentage');
                        let btn: Gtk.Button;
                        return <button hexpand
                            sensitive={connectingBind(c => !c)}
                            $={(self) => {
                                btn = self;

                                // use this workaround since we have two binds, TODO maybe theres a better way to combine these, forgot what its called
                                const update = () => {
                                    self.visible = device.paired || device.connected || (bluetooth.adapter?.discovering ?? false);
                                };
                                device.connect('notify::connected', update);
                                bluetooth.adapter?.connect('notify::discovering', update);
                                update();
                            }}
                            onClicked={() => {
                                if (device.connected) {
                                    device.disconnect_device((_, res) => device.disconnect_device_finish(res));
                                    return;
                                }
                                if (bluetooth.adapter?.discovering) bluetooth.adapter.stop_discovery();
                                device.trusted = true; // adds to list

                                // todo clean this up
                                const connectAndSwitch = () => device.connect_device((_, res) => {
                                    device.connect_device_finish(res);
                                    // auto switch sink
                                    const audioSink = audio.speakers.find((s: Wp.Endpoint) => s.name?.includes(device.name));
                                    if (audioSink) audioSink.isDefault = true;
                                });
                                if (device.paired) {
                                    connectAndSwitch();
                                } else {
                                    const id = device.connect('notify::paired', () => {
                                        if (device.paired) {
                                            device.disconnect(id);
                                            connectAndSwitch();
                                        }
                                    });
                                    device.pair();
                                }
                            }}
                            cssClasses={connectedBind((c: boolean) => c ? ['active'] : [])}
                        >
                            <Gtk.EventControllerKey onKeyPressed={(_, key) => {
                                if (key == 65288 && device.paired && !bluetooth.adapter?.discovering) {
                                    btn.visible = false;
                                    bluetooth.adapter?.remove_device(device);
                                }
                            }}/>
                            <box orientation={Gtk.Orientation.HORIZONTAL} hexpand valign={Gtk.Align.CENTER} spacing={10}>
                                <image iconName={device.icon + '-symbolic'}/>
                                <label label={nameSubstitute(device.alias)} halign={Gtk.Align.START} ellipsize={3}/>
                                <label
                                    label={batteryBind((p) => Math.round(p * 100) + '%')}
                                    halign={Gtk.Align.START}
                                    $={(self) => {
                                        const update = () => { self.visible = device.connected && device.batteryPercentage >= 0; };
                                        device.connect('notify::connected', update);
                                        device.connect('notify::battery-percentage', update);
                                        update();
                                    }}
                                />
                            </box>
                        </button>
                    }}
                </For>
            </box>
        </Gtk.ScrolledWindow>
    </box>
);
