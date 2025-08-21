import { BrightnessSlider } from '../../services/brightness';
import { VolumeSlider, SinkSelector } from './sound';
import { Astal, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
const { BOTTOM, LEFT } = Astal.WindowAnchor;

export default () =>
    <window
        name="quickSettings"
        anchor={BOTTOM | LEFT}
        application={app}
    >
        <box widthRequest={350} cssClasses={['quickSettings']} orientation={Gtk.Orientation.VERTICAL}>
            <box marginBottom={5}>
                <box orientation={Gtk.Orientation.VERTICAL}>
                    <VolumeSlider/>
                    <BrightnessSlider/>
                </box>
            </box>
            <SinkSelector/>
        </box>
    </window>

