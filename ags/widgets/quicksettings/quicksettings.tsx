import { BrightnessSlider } from '../../lib/brightness';
import { VolumeSlider, SinkSelector } from './sound';
import { Gtk } from 'ags/gtk4';
import sidebarWindow from '../../lib/sidebarWindow';

const quickSettings = () =>
    <box widthRequest={350} cssClasses={['quickSettings']} orientation={Gtk.Orientation.VERTICAL}>
        <box orientation={Gtk.Orientation.VERTICAL}>
            <VolumeSlider/>
            <BrightnessSlider/>
        </box>
        <label label="Audio devices" name="quicksettingsAudioLabel" halign={Gtk.Align.START}/>
        <SinkSelector/>
    </box>

export default () => sidebarWindow('quickSettings', quickSettings);
