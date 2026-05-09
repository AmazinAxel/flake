import { Gtk } from 'ags/gtk4';
import sidebarWindow from '../lib/sidebarWindow';

export default () => sidebarWindow('calendar', () => <Gtk.Calendar/>);
