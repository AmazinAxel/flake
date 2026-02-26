import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { execAsync } from 'ags/process';
import { setIsLocked } from '../lockscreen/lockscreen';

let window: Gtk.Window;
export default () =>
   <window
      name="powermenu"
      $={(self) => window = self}
      application={app}
      layer={Astal.Layer.OVERLAY}
      keymode={Astal.Keymode.ON_DEMAND}
   >
      <Gtk.EventControllerKey
         onKeyPressed={(_, key) => {
         window.hide();
         switch (key) {
            case 115: // S - sleep
               setIsLocked(true);
               execAsync('systemctl suspend');
               break;
            case 113: // Q - power off
               execAsync('systemctl poweroff')
               break;
            case 108: // L - lock
               setIsLocked(true);
               break;
            case 114: // R - reboot
               execAsync('systemctl reboot');
               break;
         };
      }}/>
      <box cssClasses={['widgetBackground']}>
         <image cssClasses={['sleep']} iconName="weather-clear-night-symbolic"/>
         <image cssClasses={['shutdown']} iconName="system-shutdown-symbolic"/>
         <image cssClasses={['lock']} iconName="system-lock-screen-symbolic"/>
         <image cssClasses={['reboot']} iconName="system-reboot-symbolic"/>
      </box>
   </window>
