import style from './style.css';
import lancherStyle from './widgets/launcher/launcher.css';
import clipboardStyle from './widgets/clipboard/clipboard.css';
import chatStyle from './widgets/chat/chat.css';
import barStyle from './widgets/bar/bar.css';
import notificationStyle from './widgets/notifications/notifications.css';
import osdStyle from './widgets/osd/osd.css';
import quicksettingsStyle from './widgets/quicksettings/quicksettings.css';
import powermenuStyle from './widgets/powermenu/powermenu.css';

import app from "ags/gtk4/app"
import { exec } from "ags/process";
import astalIO from "gi://AstalIO"
//import Hyprland from 'gi://AstalHyprland?version=0.1';

//import Bar from './widgets/bar/bar';
import chat from './widgets/chat/chat';
import calendar from './widgets/calendar';
import clipboard from './widgets/clipboard/clipboard';
import emojiPicker from './widgets/emojiPicker';
import launcher from './widgets/launcher/launcher';
//import recordMenu from './widgets/record/record';
import { notifications, clearOldestNotification, DND, setDND } from './widgets/notifications/notifications';
import osd from './widgets/osd/osd';
//import powermenu from './widgets/powermenu/powermenu';
import quickSettings from './widgets/quicksettings/quicksettings';
import { notifySend } from './services/notifySend';
import { isRec, stopRec, startClippingService } from './widgets/record/service';
//const hypr = Hyprland.get_default();

import { monitorBrightness } from './services/brightness';
import { initMedia, updTrack, playPause, chngPlaylist } from './services/mediaPlayer';

//const barMap: Map<number, any> = new Map();

app.start({
    css: style + lancherStyle + clipboardStyle + chatStyle + barStyle + notificationStyle + osdStyle + quicksettingsStyle + powermenuStyle,
    main() {
        //hypr.get_monitors().map((monitor) => barMap.set(monitor.id, Bar(monitor.id)));

        chat();
        calendar();
        clipboard();
        emojiPicker();
        launcher();
        //recordMenu();
        osd();
        //powermenu();
        quickSettings();

        monitorBrightness();
        notifications();
        initMedia();
        reminders();

        // Monitor reactivity
        /*hypr.connect('monitor-added', (_, monitor) =>
            barMap.set(monitor.id, Bar(monitor.id))
        );
        hypr.connect('monitor-removed', (_, monitorID) => {
            barMap.get(monitorID)?.destroy();
            barMap.delete(monitorID);
        });*/

        startClippingService(); // Run last so any errors wont impact start
    },
    requestHandler(req, res) {
        const reqArgs = req[0].split(" ");
        switch(reqArgs[0]) {
            case "hideNotif":
                clearOldestNotification();
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
            case "toggleDND":
                setDND(!DND.peek())
                break;
        };
        res("Request handled successfully");
    }
});

const reminders = () => {
    const lastSync = Number(astalIO.read_file("/home/alec/Projects/flake/ags/lastSync.txt"));
    const folderSize = Number(exec(`fish -c "du -sb /home/alec/Downloads | awk '{print \$1}'"`));

    if ((Date.now() - lastSync) > 540000000) { // Last sync was ~7 days ago
        notifySend({
            appName: 'Sync',
            title: 'Sync system files',
            actions: [{
                id: 1,
                label: 'Update & Sync',
                command: `foot -e fish -c 'sys-sync; echo "Press a key to exit"; read --nchars=1'`
            }]
        });
    } else if (folderSize > 100000000) { // Greater than 100MB
        notifySend({
            appName: 'Cleanup',
            title: 'Empty Downloads folder',
            actions: [{
                id: 1,
                label: 'View folder',
                command: 'nemo /home/alec/Downloads'
            }]
        });
    };
};
