import { Astal } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { barMargin } from '../widgets/bar/bar';
const { BOTTOM, LEFT } = Astal.WindowAnchor;

export default (name: string, Child: () => JSX.Element) =>
    <window
        name={name}
        anchor={BOTTOM | LEFT}
        application={app}
        layer={Astal.Layer.OVERLAY}
        marginLeft={barMargin}
        cssClasses={['sidebarWidget']}
    >
        <Child/>
    </window>
