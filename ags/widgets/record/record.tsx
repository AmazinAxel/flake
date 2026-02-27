import { execAsync } from "ags/process";
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import BackgroundSection from "../../lib/backgroundSection";
import { notifySend } from '../../lib/notifySend';
import { recMic, setRecMic, recQuality, startRec, setRecQuality, isRec } from './service';
import inputControl from "../../lib/inputControl";

export default () => inputControl('recordMenu', () =>
    <box
        focusable={true}
        halign={Gtk.Align.CENTER}
        valign={Gtk.Align.CENTER}
        $={(self) => app.connect('window-toggled', () =>
            app.get_window('recordMenu')?.visible && self.grab_focus()
        )}
    >
        <Gtk.EventControllerKey
            onKeyPressed={(_, key) => {
                switch (key) {
                    case 32: // Space - start recording
                        startRec();
                        app.get_window('recordMenu')?.hide()
                        break;
                    case 99: // C - clip & save last 30 seconds
                        execAsync("pkill -SIGUSR1 -f gpu-screen-recorder")
                        notifySend({
                            appName: 'Clip',
                            title: 'Clip saved',
                            actions: [{
                                id: 1,
                                label: 'Open Clips folder',
                                command: 'nemo /home/alec/Videos/Clips',
                            }]
                        });
                        app.get_window('recordMenu')?.hide()
                        break;
                    case 114: // R - toggle microphone input
                        setRecMic(!recMic.peek())
                        break;
                    case 113: // Q - toggle quality
                        (recQuality.peek() == 'Medium') ?
                            setRecQuality('Ultra') : setRecQuality('Medium');
                        break;
                    default:
                        app.get_window('recordMenu')?.hide()
                };
            }}/>
        <BackgroundSection
            height={100} width={350}
            header={
                <box $type="overlay" hexpand vexpand halign={Gtk.Align.CENTER} valign={Gtk.Align.CENTER} spacing={8}>
                    <image iconSize={2.0} iconName={recMic((m) => (m) ? 'audio-input-microphone-symbolic' : 'microphone-disabled-symbolic')}/>
                    <label label={recQuality}/>
                </box>
            }
            content={<></>}/>
    </box>
);

export const RecordingIndicator = () =>
    <image
        visible={isRec}
        halign={Gtk.Align.END}
        cssClasses={['recIndicator']}
        iconName="media-record-symbolic"/>
