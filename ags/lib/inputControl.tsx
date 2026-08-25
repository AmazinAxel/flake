import app from "ags/gtk4/app"
import { Astal, Gtk } from "ags/gtk4"
const { TOP, BOTTOM, LEFT, RIGHT } = Astal.WindowAnchor;

export default (windowName: string, Child: () => JSX.Element, onShow?: any, searchableDialog?: boolean, onKeyPressed?: any, keymode: Astal.Keymode = Astal.Keymode.EXCLUSIVE, layer: Astal.Layer = Astal.Layer.OVERLAY, focusTarget?: () => Gtk.Widget | undefined) =>
  <window
    name={windowName}
    namespace={windowName}
    keymode={keymode}
    anchor={TOP | BOTTOM | LEFT | RIGHT}
    application={app}
    layer={layer}
    onShow={(self: any) => {
      onShow?.(self);
      const target = focusTarget?.();
      if (!target) return;
      target.grab_focus();
      (target as Gtk.Entry).set_position?.(-1); // cursor pos
    }}
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
