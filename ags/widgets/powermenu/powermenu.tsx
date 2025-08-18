import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { execAsync } from 'ags/process';
import Hyprland from 'gi://AstalHyprland?version=0.1';
const hypr = Hyprland.get_default();

const centerCursor = () => {
   let x, y;
   const monitor = hypr.focusedMonitor;
   const scale = monitor.scale;

   if (monitor.transform == 0) { // Horizontal display
      x = monitor.x + (monitor.width / (2 * scale));
      y = monitor.y + (monitor.height / (2 * scale));
   } else { // Vertical (90deg) display
      x = monitor.x - (monitor.height / (2 * scale));
      y = monitor.y - (monitor.width / (2 * scale));
   };
   hypr.dispatch('movecursor', `${x} ${y}`);
};

let window: Gtk.Window;
export default () =>
   <window
      name="powermenu"
      $={(self) => window = self}
      application={app}
      keymode={Astal.Keymode.ON_DEMAND}
      onShow={centerCursor}
   >
      <Gtk.EventControllerKey
         onKeyPressed={(_, key) => {
         window.hide();
         switch (key) {
            case 115: // S - sleep
               execAsync('hyprlock');
               execAsync('systemctl suspend');
               break;
            case 113: // Q - power off
               execAsync('systemctl poweroff')
               break;
            case 108: // L - lock
               execAsync('hyprlock');
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
