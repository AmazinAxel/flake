import { execAsync } from "ags/process";
import { createBinding } from "ags"
import app from 'ags/gtk4/app'
import Astal from "gi://Astal?version=4.0"

import { notifySend } from '../services/notifySend'; 
import { recMic, recQuality, startRec } from '../services/screenRecord';

export default () => <window
    name="recordMenu"
    keymode={Astal.Keymode.ON_DEMAND}
    onKeyPressed={async (self, key) => {
        switch (key) {
            case 32: // Space - start recording
                startRec();
                self.hide()
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
                self.hide()
                break;
            case 114: // R - toggle microphone input
                recMic.set(!recMic.get())
                break;
            case 113: // Q - toggle quality
                (recQuality.get() == 'medium') ?
                    recQuality.set('ultra') : recQuality.set('medium');
                break;
            default:
                self.hide()
        };
    }}
    application={app}
    visible={false}
    cssClasses={['widgetBackground']}
    >
        <box vertical>
            <label label="Record & Clipping" cssClasses={['header']}/>
            <label label={bind(recMic).as((m) => (m) ? "Recording microphone input" : "Not recording microphone input")}/>
            <label label={bind(recQuality).as((q) => "Recording quality: " + q)}/>
        </box>
    </window>