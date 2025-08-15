//import { bind, timeout, Variable } from 'astal'; // todo
import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Wp from 'gi://AstalWp';
import { brightness } from '../../services/brightness';

const speaker = Wp.get_default()?.audio.defaultSpeaker!;
let dontShow = true;
let count = 0;
const icon: Variable<string> = new Variable('');
const val: Variable<number> = new Variable(0);

timeout(3000, () => dontShow = false);

export default () =>
    <window
        name="osd"
        anchor={Astal.WindowAnchor.BOTTOM}
        application={app}
        visible={false}
        $={(self) => {
            brightness.subscribe((v) =>
                osdChange('display-brightness-symbolic', v, self)
            );

            Variable.derive([bind(speaker, 'volume'), bind(speaker, 'mute')], (v) => {
                osdChange(speaker.volume_icon, v, self);
            });
        }}
    >
        <box cssClasses={['osd']}>
            <image iconName={bind(icon)}/>
            <levelbar value={bind(val).as(Number)} widthRequest={400}/>
        </box>
    </window>

const osdChange = (iconType: string, value: number, osd: Gtk.Window) => {
    if (dontShow)
        return;

    icon.set(iconType);
    val.set(value);
    osd.visible = true;

    count++;
    timeout(2000, () => { // 2 second hide time
        count--;

        if (count === 0)
            osd.visible = false;
    });
};
