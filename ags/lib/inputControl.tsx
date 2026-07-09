import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

export default (windowName: string, Child: () => JSX.Element, onShow?: any, searchableDialog?: boolean, onKeyPressed?: any) =>
  <window
    name={windowName}
    namespace={windowName}
    keymode={Astal.Keymode.EXCLUSIVE}
    anchor={TOP | BOTTOM | LEFT | RIGHT}
    application={app}
    layer={Astal.Layer.OVERLAY}
    onShow={onShow}
    cssClasses={searchableDialog ? ['backgroundDim', 'searchableDialog'] : ['backgroundDim']}
  >
		<Gtk.EventControllerKey
			propagationPhase={Gtk.PropagationPhase.CAPTURE}
			onKeyPressed={(ctrl, key, keycode, state) => {
			  if (key == 65307) { app.toggle_window(windowName); return true; } // Escape
			  return onKeyPressed?.(ctrl, key, keycode, state) ?? false;
			}}/>
    <Child/>
  </window>
