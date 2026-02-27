import app from "ags/gtk4/app"
import { Astal } from "ags/gtk4"
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
  >
    <Child/>
  </window>
