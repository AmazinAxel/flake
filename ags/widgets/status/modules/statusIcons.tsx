import { Gtk } from 'ags/gtk4'
import { createBinding, createState } from "ags"
import { DND } from '../../notifications/notifications';
import { focus }  from '../../launcher/launcher';
import Bluetooth from 'gi://AstalBluetooth';
import Wp from 'gi://AstalWp';
import Battery from 'gi://AstalBattery';
import { monitorFile, readFile } from 'ags/file';

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
      tooltipText={batPercentageBind((p) => (p * 100) + '%')}
      iconName={batteryIconName}
      visible={Boolean(battery.percentage)} // Hide if on desktop
    />

const volumeIconBind = createBinding(speaker, 'volumeIcon')
const VolumeIcon = () =>
  <image iconName={volumeIconBind}/>

const DNDIcon = () =>
  <image visible={DND} iconName='notifications-disabled-symbolic'/>

const FocusIcon = () =>
  <image visible={focus} iconName='emoji-flags-symbolic'/>

let [ networkIcon, setNetworkIcon ] = createState('');

const updateNetworkIcon = () => {
  const state = readFile('/sys/class/net/wlan0/operstate').trim();
  //console.log('changed', state)

  setNetworkIcon(
      state === 'up'
          ? 'network-wireless-symbolic'
          : state === 'down'
          ? 'network-wireless-offline-symbolic'
          : 'network-wireless-acquiring-symbolic'
  );
};
updateNetworkIcon()
monitorFile('/sys/class/net/wlan0/operstate', updateNetworkIcon); // todo find workaround

const NetworkIcon = () => <image iconName={networkIcon}/>

export const Status = () =>
  <box orientation={Gtk.Orientation.VERTICAL} spacing={7} cssClasses={['statusMenu']}>
    <VolumeIcon/>
    <BatteryWidget/>
    <NetworkIcon/>
    <BluetoothIcon/>
    <DNDIcon/>
    <FocusIcon/>
  </box>
