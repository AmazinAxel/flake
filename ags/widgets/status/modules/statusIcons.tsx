import { Gtk } from 'ags/gtk4'
import { createBinding, createState } from "ags"
import { streamingMode } from '../../notifications/notifications';
import { focus }  from '../../launcher/launcher';
import Bluetooth from 'gi://AstalBluetooth';
import Wp from 'gi://AstalWp';
import Battery from 'gi://AstalBattery';
import { readFile } from 'ags/file';

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

let [ networkIcon, setNetworkIcon ] = createState('');

const updateNetworkIcon = () => {
  const state = readFile('/sys/class/net/wlan0/operstate').trim();

  setNetworkIcon(
      state === 'up'
          ? 'network-wireless-symbolic'
          : state === 'down'
          ? 'network-wireless-offline-symbolic'
          : 'network-wireless-acquiring-symbolic'
  );
};
updateNetworkIcon();
setInterval(updateNetworkIcon, 3000); // todo find non poll method

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
