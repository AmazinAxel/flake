import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

export default (windowName: string, Child: () => JSX.Element, onShow?: any) =>
  <window
    name={windowName}
    namespace={windowName}
    keymode={Astal.Keymode.EXCLUSIVE}
    anchor={TOP | BOTTOM | LEFT | RIGHT}
    application={app}
    layer={Astal.Layer.OVERLAY}
    onShow={onShow}
    class="backgroundDim"
  >
		<Gtk.EventControllerKey onKeyPressed={(_, key) => (key == 65307) && app.toggle_window(windowName)}/>
    <Child/>
  </window>
