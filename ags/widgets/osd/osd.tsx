import { createState, createBinding, For, This } from 'ags';
import { timeout } from 'ags/time';
import { Astal } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Wp from 'gi://AstalWp';
import { brightness } from '../../lib/brightness';
const monitors = createBinding(app, "monitors");

const speaker = Wp.get_default()?.audio.defaultSpeaker!;
let dontShow = true;
let count = 0;
export const [ icon, setIcon ] = createState('');
export const [ val, setVal ] = createState(0);
const [ visible, setVisible ] = createState(false);
const volumeBind = createBinding(speaker, 'volume')

timeout(3000, () => dontShow = false);

export default () =>
    <For each={monitors}>
        {(monitor) => <This this={app}>
            <window
                name="osd"
                anchor={Astal.WindowAnchor.BOTTOM}
                application={app}
                layer={Astal.Layer.OVERLAY}
                gdkmonitor={monitor}
                visible={visible}
                $={() => {
                    brightness.subscribe(() =>
                        osdChange('display-brightness-symbolic', brightness.peek())
                    );
                    volumeBind.subscribe(() =>
                        osdChange(speaker.volume_icon, speaker.volume)
                    );
                }}
            >
                <box cssClasses={['osd']}>
                    <image iconName={icon}/>
                    <levelbar value={val} widthRequest={400}/>
                </box>
            </window>
        </This>}
    </For>

const osdChange = (iconType: string, value: number) => {
    if (dontShow)
        return;

    setIcon(iconType);
    setVal(value);
    setVisible(true);

    count++;
    timeout(1000, () => {
        if (--count === 0)
            setVisible(false);
    });
};
