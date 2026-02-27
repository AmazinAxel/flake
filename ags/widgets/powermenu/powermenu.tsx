import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { execAsync } from 'ags/process';
import { setIsLocked } from '../lockscreen/lockscreen';
import inputControl from '../../lib/inputControl';

export default () => inputControl('powermenu', () =>
   <box
      cssClasses={['widgetBackground']}
      halign={Gtk.Align.CENTER}
      valign={Gtk.Align.CENTER}
      focusable={true}
      $={(self) => app.connect('window-toggled', () =>
         app.get_window('powermenu')?.visible && self.grab_focus()
      )}
   >
      <Gtk.EventControllerKey
         onKeyPressed={(_, key) => {
         app.get_window('powermenu')?.hide();
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
      <image cssClasses={['sleep']} iconName="weather-clear-night-symbolic"/>
      <image cssClasses={['shutdown']} iconName="system-shutdown-symbolic"/>
      <image cssClasses={['lock']} iconName="system-lock-screen-symbolic"/>
      <image cssClasses={['reboot']} iconName="system-reboot-symbolic"/>
   </box>
   );
