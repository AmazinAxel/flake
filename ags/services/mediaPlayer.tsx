import app from "ags/gtk4/app"
import { Gdk, Gtk } from "ags/gtk4";
import { exec, execAsync } from 'ags/process';
import { createState } from 'ags';

export type musicAction = 'next' | 'prev';
export const [ isPlaying, setIsPlaying] = createState(false);
export const [ playlist, setPlaylist] = createState(1);
export const [ playlistName, setPlaylistName] = createState('');

// These playlists match with the folder names in ~/Music
const playlists =      ['Study',  'Focus',  'Synthwave', 'SynthAmbient', 'Ambient'];
const playlistColors = ['bf616a', '5e81ac', 'b48ead',    'ebcb8b',       '81a1c1']

export const updTrack = (direction: musicAction) => {
    exec('mpc pause');
    exec('mpc ' + direction);

    // Start playing again
    execAsync('mpc play');
    setIsPlaying(true);
};

export const playPause = () => {
    execAsync('mpc toggle');
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
    exec('mpc pause');
    setIsPlaying(false);

    setPlaylistName(playlists[Number(playlist.peek()) - 1]);
    execAsync(`wbg /home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg`);

    // Clear the current cache and add the new playlist
    exec('mpc clear');
    exec(`mpc add ${playlistName.peek()}/`);
    exec('mpc shuffle');
    playPause(); // Start playing
};

export const initMedia = () => {
    setPlaylistName('Study'); // Must set to invoke binds

    execAsync('mpc crossfade 2');
    execAsync('wbg /home/alec/Projects/flake/wallpapers/Study.jpg');

    exec('mpc clear');
    exec(`mpc add ${playlistName.peek()}/`);
    execAsync('mpc shuffle');
};


export const Media = () =>
    <button
        name={'mediaBtn'}
        onClicked={playPause}
        cursor={Gdk.Cursor.new_from_name('pointer', null)}
        $={() =>
            playlistName.subscribe(() => {
                const color = playlistColors[playlist.peek() - 1];
                app.apply_css(`
                    #bar #mediaBtn {
                        background-color: #${color};
                    }
                    #bar #media {
                        border: 0.15rem shade(#${color}, 1.15) solid;
                    }
                `)
            })
        }
    >
        <Gtk.EventControllerScroll
            flags={Gtk.EventControllerScrollFlags.VERTICAL} 
            onScroll={(_, __, y) => {
                execAsync('mpc volume ' + ((y < 0) ? '+5' : '-5'))
        }}/>
        <image iconName={isPlaying.as(
            (v: boolean) => (v) ? 'media-playback-pause-symbolic' : 'media-playback-start-symbolic')
        }/>
    </button>