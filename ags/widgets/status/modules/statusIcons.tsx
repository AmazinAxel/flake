import { Gtk } from 'ags/gtk4'
import { createBinding, createState } from "ags"
import { streamingMode } from '../../notifications/notifications';
import { focus }  from '../../launcher/launcher';
import Bluetooth from 'gi://AstalBluetooth';
import Wp from 'gi://AstalWp';
import Battery from 'gi://AstalBattery';
import Gio from 'gi://Gio';

const bluetooth = Bluetooth.get_default()
const speaker = Wp.get_default()?.audio.defaultSpeaker!;
const battery = Battery.get_default();

const btIsPoweredBind = createBinding(bluetooth, 'isPowered');
const BluetoothIcon = () =>
  <image
    iconName='bluetooth-active-symbolic'
    visible={btIsPoweredBind}
  />

const batPercentageBind = createBinding(battery, 'percentage');
const batteryIconName = createBinding(battery, 'batteryIconName')
const BatteryWidget = () =>
    <image
      tooltipText={batPercentageBind((p) => Math.round(p * 100) + '%')}
      iconName={batteryIconName}
      visible={Boolean(battery.percentage)} // Hide if on desktop
    />

const volumeIconBind = createBinding(speaker, 'volumeIcon')
const VolumeIcon = () =>
  <image iconName={volumeIconBind}/>

const StreamingModeIcon = () =>
  <image visible={streamingMode} iconName='notifications-disabled-symbolic'/>

const FocusIcon = () =>
  <image visible={focus} iconName='emoji-flags-symbolic'/>

const iwdBus = 'net.connman.iwd';
const stationInterface = 'net.connman.iwd.Station';
const systemBus = Gio.DBus.system;

const [ networkIcon, setNetworkIcon ] = createState('network-wireless-offline-symbolic');

const iconForState = (state?: string) =>
    (state === 'connected' || state === 'roaming') ? 'network-wireless-symbolic'
        : (state === 'connecting' || state === 'disconnecting') ? 'network-wireless-acquiring-symbolic'
        : 'network-wireless-offline-symbolic';

const applyState = (state?: string) => {
  if (!state) return;
  const icon = iconForState(state);
  if (icon !== networkIcon.peek()) setNetworkIcon(icon);
};

systemBus.signal_subscribe(
  iwdBus, 'org.freedesktop.DBus.Properties', 'PropertiesChanged',
  null, stationInterface, Gio.DBusSignalFlags.NONE,
  (_c, _s, _p, _i, _sig, params) => {
    const [, changed] = params.recursiveUnpack() as [string, Record<string, any>];
    if ('State' in changed) applyState(changed.State);
  },
);

systemBus.call(
  iwdBus, '/', 'org.freedesktop.DBus.ObjectManager', 'GetManagedObjects',
  null, null, Gio.DBusCallFlags.NONE, -1, null,
  (conn, res) => {
    try {
      const [objects] = conn!.call_finish(res).recursiveUnpack() as [Record<string, Record<string, any>>];
      for (const ifaces of Object.values(objects)) {
        const station = ifaces[stationInterface];
        if (station && 'State' in station) { applyState(station.State); break; }
      };
    } catch {  };
  },
);

const NetworkIcon = () => <image iconName={networkIcon}/>

export const Status = () =>
  <box orientation={Gtk.Orientation.VERTICAL} spacing={7} cssClasses={['statusMenu']}>
    <VolumeIcon/>
    <BatteryWidget/>
    <NetworkIcon/>
    <BluetoothIcon/>
    <StreamingModeIcon/>
    <FocusIcon/>
  </box>
