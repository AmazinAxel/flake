// Stolen from https://github.com/matt1432/nixos-configs/blob/master/modules/ags/config/widgets/corners/index.tsx

import app from "ags/gtk4/app"
import { Astal } from "ags/gtk4"

import { Corner } from './corners';
const { TOP, LEFT, BOTTOM } = Astal.WindowAnchor;

export default (monitor: number) =>
    cornerTop(monitor) &&
    cornerBottom(monitor)


// TODO combine these into the default export
const cornerTop = (monitor: number): Astal.Window =>
    <window
        name="cornertop"
        monitor={monitor}
        anchor={TOP | LEFT}
        application={app}
        visible
    >
        {Corner('top')}
    </window>

const cornerBottom = (monitor: number): Astal.Window => (
    <window
        name="cornerbottom"
        monitor={monitor}
        anchor={BOTTOM | LEFT}
        application={app}
        visible
    >
        {Corner('bottom')}
    </window>
);
