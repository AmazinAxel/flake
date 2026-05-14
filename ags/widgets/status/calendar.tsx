import { Gtk } from 'ags/gtk4';
import asideStatusWindow from '../../lib/asideStatusWindow';

export default () => asideStatusWindow('calendar', () => <Gtk.Calendar/>);
