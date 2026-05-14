import { Astal } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import { statusMargin } from '../widgets/status/status';
const { BOTTOM, LEFT } = Astal.WindowAnchor;

export default (name: string, Child: () => JSX.Element) =>
    <window
        name={name}
        anchor={BOTTOM | LEFT}
        application={app}
        layer={Astal.Layer.OVERLAY}
        marginLeft={statusMargin}
        cssClasses={['asideStatusWidget']}
    >
        <Child/>
    </window>
