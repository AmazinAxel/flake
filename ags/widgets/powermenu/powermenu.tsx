import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { execAsync } from 'ags/process';
import { setIsLocked } from '../lockscreen/lockscreen';
import inputControl from '../../lib/inputControl';

const handleKeys = (_ctrl: any, key: number) => {
   app.get_window('powermenu')?.hide();
   switch (key) {
      case 115: // S - sleep
         execAsync('systemctl hibernate');
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
};

export default () => inputControl('powermenu', () =>
   <box
      cssClasses={['widgetBackground']}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
   >
      <image cssClasses={['sleep']} iconName="weather-clear-night-symbolic"/>
      <image cssClasses={['shutdown']} iconName="system-shutdown-symbolic"/>
      <image cssClasses={['lock']} iconName="system-lock-screen-symbolic"/>
      <image cssClasses={['reboot']} iconName="system-reboot-symbolic"/>
   </box>,
   undefined,
   undefined,
   handleKeys
   );
