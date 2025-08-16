import app from "ags/gtk4/app"
import { Astal } from "ags/gtk4"

import { Corner } from './corners';
const { TOP, LEFT, BOTTOM } = Astal.WindowAnchor;

export const cornerTop = (monitor: number) =>
    <window
        name="cornertop"
        monitor={monitor}
        anchor={TOP | LEFT}
        application={app}
        visible
        child={Corner('top')}
    />

export const cornerBottom = (monitor: number) =>
    <window
        name="cornerbottom"
        monitor={monitor}
        anchor={BOTTOM | LEFT}
        application={app}
        child={Corner('bottom')}
        visible
    />

