import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
const { BOTTOM, LEFT } = Astal.WindowAnchor;

export default () =>
  <window
    name="calendar"
    anchor={BOTTOM | LEFT}
    application={app}
  >
    <Gtk.Calendar/>
  </window>
