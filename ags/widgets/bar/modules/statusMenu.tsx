import Gdk from 'gi://Gdk'
import app from 'ags/gtk4/app'
import { Gtk } from 'ags/gtk4'
import { createBinding } from "ags"
import { DND } from '../../notifications/notifications';
import Bluetooth from 'gi://AstalBluetooth';
import Wp from 'gi://AstalWp';
import Battery from 'gi://AstalBattery';

const bluetooth = Bluetooth.get_default()
const speaker = Wp.get_default()?.audio.defaultSpeaker!;
const battery = Battery.get_default();

const btConnectedBind = createBinding(bluetooth, 'isConnected');
const btIsPoweredBind = createBinding(bluetooth, 'isPowered');
const BluetoothIcon = () =>
  <image
    cssClasses={btConnectedBind((isConn) => (isConn) ? ['btConnected'] : [''])}
    iconName='bluetooth-active-symbolic'
    visible={btIsPoweredBind}
  />

const batPercentageBind = createBinding(battery, 'percentage');
const batteryIconName = createBinding(battery, 'batteryIconName')
const BatteryWidget = () => 
    <image
      tooltipText={batPercentageBind((p) => (p * 100) + '%')}
      iconName={batteryIconName}
      //visible={(!battery.percentage == 0)} // Hide if on desktop TODO
    />

const volumeIconBind = createBinding(speaker, 'volumeIcon')
const VolumeIcon = () =>
  <image iconName={volumeIconBind}/>

// TODO
//const DNDIcon = () =>
//  <image visible={bind(DND)} iconName='notifications-disabled-symbolic'/>

export const Status = () =>
  <button
    onActivate={() => {
      app.get_window('calendar')?.hide();
      app.toggle_window('quickSettings');
    }}
    cursor={Gdk.Cursor.new_from_name('pointer', null)}
  >
    <Gtk.EventControllerScroll
      onScroll={(_, __, y) => { speaker.volume = (y < 0) ? speaker.volume + 0.05 : speaker.volume - 0.05 }}/>
    <box orientation={Gtk.Orientation.VERTICAL} spacing={7} cssClasses={['statusMenu']}>
      <VolumeIcon/>
      <BatteryWidget/>
      <BluetoothIcon/>
    </box>
  </button>
