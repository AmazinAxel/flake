import { createState, createBinding } from 'ags';
import { timeout } from 'ags/time';
import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Wp from 'gi://AstalWp';
import { brightness } from '../../services/brightness';

const speaker = Wp.get_default()?.audio.defaultSpeaker!;
let dontShow = true;
let count = 0;
export const [ icon, setIcon] = createState('');
export const [ val, setVal] = createState(0);
const volumeBind = createBinding(speaker, 'volume')

timeout(3000, () => dontShow = false);

export default () =>
    <window
        name="osd"
        anchor={Astal.WindowAnchor.BOTTOM}
        application={app}
        $={(self) => {
            brightness.subscribe(() =>
                osdChange('display-brightness-symbolic', brightness.get(), self)
            );
            volumeBind.subscribe(() =>
                osdChange(speaker.volume_icon, speaker.volume, self)
            );
        }}
    >
        <box cssClasses={['osd']}>
            <image iconName={icon}/>
            <levelbar value={val} widthRequest={400}/>
        </box>
    </window>

const osdChange = (iconType: string, value: number, osd: Gtk.Window) => {
    if (dontShow)
        return;

    setIcon(iconType);
    setVal(value);
    osd.visible = true;

    count++;
    timeout(1000, () => {
        count--;

        if (count === 0)
            osd.visible = false;
    });
};
