import { App, Gdk } from 'astal/gtk4';
import { bind } from 'astal';
import { DND } from '../../notifications/notifications';
import Bluetooth from 'gi://AstalBluetooth';
import Wp from 'gi://AstalWp';
import Battery from 'gi://AstalBattery';

const bluetooth = Bluetooth.get_default()
const speaker = Wp.get_default()?.audio.defaultSpeaker!;
const battery = Battery.get_default();

const BluetoothIcon = () =>
  <image
    cssClasses={bind(bluetooth, 'isConnected').as((isConn) => (isConn) ? ['btConnected'] : [''])}
    iconName='bluetooth-active-symbolic'
    visible={bind(bluetooth, 'isPowered')}
  />

const BatteryWidget = () => 
    <image
      tooltipText={bind(battery, 'percentage').as((p) => (p * 100) + '%')}
      iconName={bind(battery, 'batteryIconName')}
      visible={(!battery.percentage == 0)} // Hide if on desktop
    />

const VolumeIcon = () =>
  <image iconName={bind(speaker, 'volumeIcon')}/>

const DNDIcon = () =>
  <image visible={bind(DND)} iconName='notifications-disabled-symbolic'/>

export const Status = () =>
  <button
    onButtonPressed={() => {
      App.get_window('calendar')?.hide();
      App.toggle_window('quickSettings');
    }}
    cursor={Gdk.Cursor.new_from_name('pointer', null)}
    onScroll={(_, __, y) => speaker.volume = (y < 0) ? speaker.volume + 0.05 : speaker.volume - 0.05 }
  >
    <box vertical spacing={7} cssClasses={['statusMenu']}>
      <VolumeIcon/>
      <BatteryWidget/>
      <BluetoothIcon/>
      <DNDIcon/>
    </box>
  </button>
