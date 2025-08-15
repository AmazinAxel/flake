//import { bind } from 'astal'; // todo
import { Gdk } from 'ags/gtk4';
import MprisService from 'gi://AstalMpris';

const mpris = MprisService.get_default();

export const Mpris = () =>
    <button
        cssClasses={['mpris']}
        onActivate={() => mpris.players[0].play_pause()}
        onScroll={(_, __, y) => {
            const volume = mpris.players[0].get_volume();
            (y > 0)
                ? mpris.players[0].set_volume(volume + 0.05)
                : mpris.players[0].set_volume(volume - 0.05)
        }}
        visible={bind(mpris, 'players').as((players) => (players.length > 0))}
        cursor={Gdk.Cursor.new_from_name('pointer', null)}
    >
        <image iconName="folder-music-symbolic"/>
    </button>
