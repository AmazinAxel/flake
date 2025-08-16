import { BrightnessSlider } from '../../services/brightness';
import { VolumeSlider, SinkSelector } from './sound';
import { Astal, Gdk, Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import { DND, setDND } from '../notifications/notifications';
const { BOTTOM, LEFT } = Astal.WindowAnchor;

const DNDToggle = () =>
    <button
        widthRequest={60}
        cssClasses={DND((dnd) => (dnd) ? ['dnd', 'active'] : ['dnd'])}
        cursor={Gdk.Cursor.new_from_name('pointer', null)}
        onClicked={() => setDND(!DND.get())}
    >
        <image iconName="notifications-disabled-symbolic"/>
    </button>

export default () =>
    <window
        name="quickSettings"
        anchor={BOTTOM | LEFT}
        application={app}
        visible={false}
    >
        <box widthRequest={400} cssClasses={['quickSettings']} orientation={Gtk.Orientation.VERTICAL}>
            <box marginBottom={5}>
                <box orientation={Gtk.Orientation.VERTICAL}>
                    <VolumeSlider/>
                    <BrightnessSlider/>
                </box>
                <DNDToggle/>
            </box>
        </box>
    </window>

