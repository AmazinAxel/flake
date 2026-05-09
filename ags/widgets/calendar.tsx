import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { barMargin } from './bar/bar';
const { BOTTOM, LEFT } = Astal.WindowAnchor;

export default () =>
  <window
    name="calendar"
    anchor={BOTTOM | LEFT}
    application={app}
    layer={Astal.Layer.OVERLAY}
    marginLeft={barMargin}
  >
    <Gtk.Calendar/>
  </window>
