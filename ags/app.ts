import style from './style.css';
import lancherStyle from './widgets/launcher/launcher.css';
import clipboardStyle from './widgets/clipboard/clipboard.css';
import statusStyle from './widgets/status/status.css';
import notificationStyle from './widgets/notifications/notifications.css';
import osdStyle from './widgets/osd/osd.css';
import powermenuStyle from './widgets/powermenu/powermenu.css';
import lockscreenStyle from './widgets/lockscreen/lockscreen.css';

import app from "ags/gtk4/app"
import { execAsync } from "ags/process";
import astalIO from "gi://AstalIO"

import status, { setStatusMargin } from './widgets/status/status';
import bluetooth from './widgets/status/bluetooth';
import wifi from './widgets/status/network';
import chat, { toggleChatSize } from './widgets/chat/chat';
import plan from './widgets/plan';
import calendar from './widgets/status/calendar';
import clipboard from './widgets/clipboard/clipboard';
import emojiPicker from './widgets/emojiPicker';
import launcher, { focus, setIsFocused }  from './widgets/launcher/launcher';
import recordMenu from './widgets/record/record';
import { notifications, clearOldestNotification, invokeOldestNotification, streamingMode, setStreamingMode } from './widgets/notifications/notifications';
import osd from './widgets/osd/osd';
import powermenu from './widgets/powermenu/powermenu';
import quickSettings from './widgets/status/quicksettings/quicksettings';
import lockscreen from './widgets/lockscreen/lockscreen';
import { notifySend } from './lib/notifySend';
import { isRec, stopRec, startClippingService } from './widgets/record/service';

import { monitorBrightness } from './lib/brightness';
import { initMedia, updTrack, playPause, chngPlaylist } from './lib/mediaPlayer';
import workspaces from './widgets/workspaces';
import asideStatusWindow, { setAsideWindow, closeAsideWindow } from './lib/asideStatusWindow';

let blueLightFilter = false;

app.start({
    css: style + lancherStyle + clipboardStyle + statusStyle + notificationStyle + osdStyle + powermenuStyle + lockscreenStyle,
    main() {
        status();
        chat.Window();
        plan.Window();
        clipboard();
        emojiPicker();
        recordMenu();
        osd();
        powermenu();
        asideStatusWindow({
            quickSettings,
            bluetooth,
            wifi,
            calendar
        });
        lockscreen();
        workspaces();

        monitorBrightness();
        notifications();
        initMedia();
        reminders();

        launcher();
        startClippingService(); // Run last so if not installed it wont impact start
    },
    requestHandler(req, res) {
        const reqArgs = req[0].split(" ");
        switch(reqArgs[0]) {
            case "hideNotif":
                clearOldestNotification();
                break;
            case "invokeOldestNotif":
                invokeOldestNotification();
                break;
            case "toggleChatSize":
                toggleChatSize();
                break;
            case "toggleChat":
                if (app.get_window('plan')?.visible) app.toggle_window('plan');
                chat.toggle();
                break;
            case "togglePlan":
                if (app.get_window('chat')?.visible) app.toggle_window('chat');
                plan.toggle();
                break;
            case "record":
                (isRec.peek() == true)
                    ? stopRec()
                    : app.toggle_window("recordMenu");
                break;
            case "media":
                switch (reqArgs[1]) {
                    case "next":
                        updTrack('next');
                        break;
                    case "prev":
                        updTrack('prev');
                        break;
                    case "toggle":
                        playPause();
                        break;
                    case "nextPlaylist":
                        chngPlaylist('next');
                        break;
                    case "prevPlaylist":
                        chngPlaylist('prev');
                        break;
                };
                break;
            case "toggleQuicksettings":
                setAsideWindow('quickSettings');
                break;
            case "toggleCalendar":
                setAsideWindow('calendar');
                break;
            case "toggleBluetooth":
                setAsideWindow('bluetooth');
                break;
            case "toggleWifi":
                setAsideWindow('wifi');
                break;
            case "closeAsideStatusMenuWidget":
                closeAsideWindow();
                break;
            case "toggleInfoArea":
                setStatusMargin(app.get_window('status')?.visible ? 0 : 41);
                app.toggle_window('status');
                break;
            case "toggleStreamingMode":
                setStreamingMode(!streamingMode.peek())
                break;
            case "toggleFocus":
                setIsFocused(!focus.peek());
                break;
            case "toggleFilter":
                execAsync(`busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q ${blueLightFilter ? 3500 : 6500}`);
                blueLightFilter = !blueLightFilter;
                break;
        };
        res("Request handled successfully");
    }
});

const reminders = async () => {
    const lastSync = Number(astalIO.read_file("/home/alec/Projects/flake/ags/lastSync.txt"));

    if ((Date.now() - lastSync) > 540000000) { // Last sync was ~7 days ago
        notifySend({
            appName: 'Sync',
            title: 'Sync system',
            actions: [{
                id: 1,
                label: 'Update & Sync',
                command: `foot -e fish -c 'sys-sync; echo "Press a key to exit"; read --nchars=1'`
            }]
        });
        return;
    };

    const folderSize = await execAsync(`bash -c "du -sb /home/alec/Downloads | awk '{print \$1}'"`)
        .then(Number).catch(() => 0);
    if (folderSize > 100000000) { // Greater than 100MB
        notifySend({
            appName: 'Cleanup',
            title: 'Empty Downloads',
            actions: [{
                id: 1,
                label: 'View folder',
                command: 'nemo /home/alec/Downloads'
            }]
        });
    };
};
