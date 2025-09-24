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
const playlistColors = ['d08770', '5e81ac', 'b48ead',    'ebcb8b',       '81a1c1']

export const updTrack = (direction: musicAction) => {
    exec('mpc pause');
    exec('mpc ' + direction);

    // Start playing again
    execAsync('mpc play');
    setIsPlaying(true);
};

export const playPause = () => {
    execAsync('mpc toggle');
    setIsPlaying(!isPlaying.get());
};

export const chngPlaylist = (direction: musicAction) => {
    let wallpaperTransitionAngle;
    if (direction == 'next') {
        wallpaperTransitionAngle = 270;
        (playlist.get() == playlists.length)
        ? (setPlaylist(1)) // Go to first
        : (setPlaylist(Number(playlist.get()) + 1));
    } else if (direction == 'prev') {
        wallpaperTransitionAngle = 90;
        (playlist.get() == 1)
        ? (setPlaylist(playlists.length)) // Go to last
        : (setPlaylist(Number(playlist.get()) - 1));
    }

    // Stop playing music
    exec('mpc pause');
    setIsPlaying(false);

    setPlaylistName(playlists[Number(playlist.get()) - 1]);
    execAsync(`swww img /home/alec/Projects/flake/wallpapers/${playlistName.get()}.jpg --transition-type=wave --transition-angle=${wallpaperTransitionAngle} --transition-wave=100,100 --filter=Nearest --transition-duration=1 --transition-fps=145`);

    // Clear the current cache and add the new playlist
    exec('mpc clear');
    exec(`mpc add ${playlistName.get()}/`);
    exec('mpc shuffle');
    playPause(); // Start playing
};

export const initMedia = () => {
    setPlaylistName('Study'); // Must set to invoke binds

    execAsync('mpc crossfade 2');
    execAsync('swww img /home/alec/Projects/flake/wallpapers/Study.jpg --transition-type=wave --transition-angle=90 --transition-wave=100,100 --filter=Nearest --transition-duration=1 --transition-fps=145');

    exec('mpc clear');
    exec(`mpc add ${playlistName.get()}/`);
    execAsync('mpc shuffle');
};


export const Media = () =>
    <button
        name={'mediaBtn'}
        onClicked={playPause}
        cursor={Gdk.Cursor.new_from_name('pointer', null)}
        hexpand
        $={() =>
            playlistName.subscribe(() => {
                const color = playlistColors[playlist.get() - 1];
                app.apply_css(`
                    #bar #mediaBtn {
                        background-color: #${color};
                    }
                    #bar #media {
                        border: 0.15rem shade(#${color}, 0.6) solid;
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