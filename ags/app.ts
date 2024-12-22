// @ts-nocheck TODO fix types

import { App } from "astal/gtk3";
import style from "./style.css";
import bar from "./widgets/bar";

App.start({
    css: style,
    main() {
        App.get_monitors().map(bar)
    },
    requestHandler(req, res) {
        if (req == "hideNotif") {
            res("ok");
        };
    }
})

/* Reminders script:
if it's a monday and there's more than five files in Downloads folder
    Utils.notify({summary: "Clear Downloads folder", body: "Clean up some unused files to keep the system clean", actions: { "View folder": () => Utils.execAsync("nemo Downloads/")

else if its a Friday
    Utils.notify({summary: "Sync Spotify playlists", body: "Sync all Spotify playlists to have the latest music", actions: { "Open Terminal": () => Utils.execAsync("foot -e fish -c spotify-sync")

else if download directory is over 1000MB
    Utils.notify({summary: "Clear Downloads folder", body: "The Downloads folder is large! Clean up some unused files.", actions: { "View folder": () => Utils.execAsync("nemo Downloads/")
*/
