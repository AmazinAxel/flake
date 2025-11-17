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

export const Status = () =>
  <button
    onClicked={() => {
      app.get_window('calendar')?.hide();
      app.toggle_window('quickSettings');
    }}
    cursor={Gdk.Cursor.new_from_name('pointer', null)}
  >
    <Gtk.EventControllerScroll
      flags={Gtk.EventControllerScrollFlags.VERTICAL}
      onScroll={(_, __, y) => { speaker.volume = (y < 0) ? speaker.volume + 0.05 : speaker.volume - 0.05 }}/>
    <box orientation={Gtk.Orientation.VERTICAL} spacing={7} cssClasses={['statusMenu']}>
      <VolumeIcon/>
      <BatteryWidget/>
      <BluetoothIcon/>
      <DNDIcon/>
    </box>
  </button>
