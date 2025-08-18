import { execAsync } from "ags/process";
import { Gtk } from 'ags/gtk4';
import app from 'ags/gtk4/app'
import Astal from "gi://Astal?version=4.0"

import { notifySend } from '../services/notifySend'; 
import { recMic, setRecMic, recQuality, startRec, setRecQuality } from '../services/screenRecord';

let window: Gtk.Window;
export default () => <window
    name="recordMenu"
    keymode={Astal.Keymode.ON_DEMAND}
    application={app}
    $={(self) => window = self}
    cssClasses={['widgetBackground']}
    >
        <Gtk.EventControllerKey
            onKeyPressed={(self, key) => {
                switch (key) {
                    case 32: // Space - start recording
                        startRec();
                        window.hide()
                        break;
                    case 99: // C - clip & save last 30 seconds
                        execAsync("killall -SIGUSR1 gpu-screen-recorder")
                        notifySend({
                            appName: 'Screen Recording',
                            title: 'Screen recording saved',
                            iconName: 'emblem-videos-symbolic',
                            actions: [{
                                id: 1,
                                label: 'Open Clips folder',
                                command: 'nemo /home/alec/Videos/Clips',
                            }]
                        });
                        window.hide()
                        break;
                    case 114: // R - toggle microphone input
                        setRecMic(!recMic.get())
                        break;
                    case 113: // Q - toggle quality
                        (recQuality.get() == 'medium') ?
                            setRecQuality('ultra') : setRecQuality('medium');
                        break;
                    default:
                        window.hide()
                };
            }}/>

        <box orientation={Gtk.Orientation.VERTICAL}>
            <label label="Record & Clipping" cssClasses={['header']}/>
            <label label={recMic((m) => (m) ? "Recording microphone input" : "Not recording microphone input")}/>
            <label label={recQuality((q) => "Recording quality: " + q)}/>
        </box>
    </window>