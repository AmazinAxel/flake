import { Gtk } from "ags/gtk4";
import Gdk from "gi://Gdk";
import { execAsync } from 'ags/process';
import { createState } from 'ags';

const mediaCss = new Gtk.CssProvider();
Gtk.StyleContext.add_provider_for_display(
    Gdk.Display.get_default()!, mediaCss, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

export type musicAction = 'next' | 'prev';
export const [ isPlaying, setIsPlaying ] = createState(false);
export const [ playlist, setPlaylist ] = createState(1);
export const [ playlistName, setPlaylistName ] = createState('');

// These playlists match with the folder names in ~/Music
const playlists =      ['Study',  'Focus',  'Synthwave', 'Liked', 'SynthAmbient', 'Ambient'];
const playlistColors = ['bf616a', '5e81ac', 'b48ead',    '8fbcbb',      'ebcb8b',       '81a1c1'];

let mpcQueue: Promise<unknown> = Promise.resolve();
const mpc = (...cmds: string[]) => {
    for (const c of cmds)
        mpcQueue = mpcQueue.then(() => execAsync('mpc ' + c).catch(() => {}));
    return mpcQueue;
};

export const updTrack = (direction: musicAction) => {
    mpc('pause', direction, 'play');
    setIsPlaying(true);
};

export const playPause = () => {
    mpc('toggle');
    setIsPlaying(!isPlaying.peek());
};

export const chngPlaylist = (direction: musicAction) => {
    if (direction == 'next') {
        (playlist.peek() == playlists.length)
        ? (setPlaylist(1)) // Go to first
        : (setPlaylist(Number(playlist.peek()) + 1));
    } else if (direction == 'prev') {
        (playlist.peek() == 1)
        ? (setPlaylist(playlists.length)) // Go to last
        : (setPlaylist(Number(playlist.peek()) - 1));
    };

    // Stop playing music
    mpc('pause');
    setIsPlaying(false);

    setPlaylistName(playlists[Number(playlist.peek()) - 1]);
    execAsync(`swaybg -i /home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg -m fill`);

    // Clear the current cache and add the new playlist
    mpc('clear', `add ${playlistName.peek()}/`, 'shuffle');
    playPause(); // Start playing
};

export const initMedia = () => {
    setPlaylistName('Study'); // Must set to invoke binds
    execAsync('swaybg -i /home/alec/Projects/flake/wallpapers/Study.jpg -m fill');
    mpc('crossfade 2', 'clear', `add ${playlistName.peek()}/`, 'shuffle');
};


export const Media = () =>
    <box name={'mediaBtn'}
        $={() => playlistName.subscribe(() => {
            const color = playlistColors[playlist.peek() - 1];
            mediaCss.load_from_string(`
                #status #mediaBtn {
                    background-color: #${color};
                }
            `);
        })
    }>
    <Gtk.EventControllerScroll
        flags={Gtk.EventControllerScrollFlags.VERTICAL}
        onScroll={(_, __, y) => {
            execAsync('mpc volume ' + ((y < 0) ? '+5' : '-5'))
        }}/>
        <image iconName={isPlaying.as(
            (v: boolean) => (v) ? 'media-playback-pause-symbolic' : 'media-playback-start-symbolic')
        }/>
    </box>
