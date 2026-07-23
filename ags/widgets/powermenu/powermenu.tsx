import app from 'ags/gtk4/app'
import { execAsync } from 'ags/process';
import { lockScreen } from '../lockscreen/lockscreen';
import inputControl from '../../lib/inputControl';

const handleKeys = (_ctrl: any, key: number) => {
   app.get_window('powermenu')?.hide();
   switch (key) {
      case 115: // S - sleep
         lockScreen();
         execAsync('systemctl suspend');
         break;
      case 104: // H - hibernate
         execAsync('systemctl hibernate');
         break;
      case 113: // Q - power off
         execAsync('systemctl poweroff')
         break;
      case 108: // L - lock
         lockScreen();
         break;
      case 114: // R - reboot
         execAsync('systemctl reboot');
         break;
   };
};

export default () => inputControl('powermenu', () => <box/>,
   undefined,
   undefined,
   handleKeys
   );
