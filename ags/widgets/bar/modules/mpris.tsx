import { Gdk } from 'ags/gtk4';
import { createBinding } from "ags"
import MprisService from 'gi://AstalMpris';

const mpris = MprisService.get_default();
const mprisPlayerBind = createBinding(mpris, 'players')

export const Mpris = () =>
    <button
        name={'mprisBtn'}
        onClicked={() => mpris.players[0].play_pause()}
        visible={mprisPlayerBind((players) => (players.length > 0))}
        cursor={Gdk.Cursor.new_from_name('pointer', null)}
    >
        <image iconName="folder-music-symbolic"/>
    </button>
