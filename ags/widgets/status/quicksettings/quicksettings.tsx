import { BrightnessSlider } from '../../../lib/brightness';
import { VolumeSlider, SinkSelector } from './sound';
import { Gtk } from 'ags/gtk4';
import asideStatusWindow from '../../../lib/asideStatusWindow';

export default () => asideStatusWindow('quickSettings', () =>
    <box widthRequest={300} cssClasses={['quickSettings']} orientation={Gtk.Orientation.VERTICAL}>
        <box orientation={Gtk.Orientation.VERTICAL}>
            <VolumeSlider/>
            <BrightnessSlider/>
        </box>
        <Gtk.Separator/>
        <SinkSelector/>
    </box>
);