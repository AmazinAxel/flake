import { createState, createBinding, For, This } from 'ags';
import { timeout } from 'ags/time';
import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app';
import Wp from 'gi://AstalWp';
import { brightness } from '../../lib/brightness';
import { monitors } from '../../lib/monitors';
import OutTransition from '../../lib/outTransition';

const speaker = Wp.get_default()?.audio.defaultSpeaker!;
let dontShow = true;
let count = 0;
export const [ icon, setIcon ] = createState('');
export const [ val, setVal ] = createState(0);
const [ windowVisible, setWindowVisible ] = createState(false);
const [ reveal, setReveal ] = createState(false);
const volumeBind = createBinding(speaker, 'volume');
const isMuted = createBinding(speaker, 'mute');

timeout(2000, () => dontShow = false); // stop osd from showing when ags starts

export default () =>
    <For each={monitors}>
        {(monitor) => <This this={app}>
            <window
                name="osd"
                anchor={Astal.WindowAnchor.BOTTOM}
                application={app}
                layer={Astal.Layer.OVERLAY}
                gdkmonitor={monitor}
                visible={windowVisible}
                defaultHeight={1} // fix bug
                defaultWidth={1}
                $={() => {
                    brightness.subscribe(() =>
                        osdChange('display-brightness-symbolic', brightness.peek())
                    );

                    // volume changes for the mute bind as well
                    const volumeChanged = () => osdChange(speaker.volume_icon, speaker.volume);
                    volumeBind.subscribe(volumeChanged);
                    isMuted.subscribe(volumeChanged);
                }}
            >
                <OutTransition duration={125} reveal={reveal} onHidden={() => (count === 0) && setWindowVisible(false)} type={Gtk.RevealerTransitionType.SLIDE_UP}>
                    <box cssClasses={['osd']}>
                        <image iconName={icon}/>
                        <levelbar value={val} widthRequest={400}/>
                    </box>
                </OutTransition>
            </window>
        </This>}
    </For>

const osdChange = (iconType: string, value: number) => {
    if (dontShow)
        return;

    setIcon(iconType);
    setVal(value);
    setWindowVisible(true);
    setReveal(true);

    count++;
    timeout(500, () => {
        if (--count === 0)
            setReveal(false);
    });
};
