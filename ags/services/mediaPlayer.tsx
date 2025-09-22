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
const playlistColors = ['CC7F1F', '649FEC', 'C363C7',    '8169E5',       '1A47D0']

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
    <box heightRequest={35} marginBottom={1}>
        <overlay>
            <box
                cssClasses={isPlaying.as((v: boolean) => v ? ['playing', 'mediaBg'] : ['mediaBg'])}
                hexpand
                $={() =>
                    playlistName.subscribe(() =>
                        app.apply_css(`#bar .mediaBg { background-color: #${playlistColors[playlist.get() - 1]}; }`)
                )}
            />
            <button
                cssClasses={['media']}
                $type="overlay"
                onClicked={() => playPause()}
                cursor={Gdk.Cursor.new_from_name('pointer', null)}
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
        </overlay>
    </box>
