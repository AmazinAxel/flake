import { Gtk } from "ags/gtk4";
import Gdk from "gi://Gdk";
import { execAsync } from 'ags/process';
import { timeout } from 'ags/time';
import { createState } from 'ags';
import AstalIO from 'gi://AstalIO';

const themeCss = new Gtk.CssProvider();
Gtk.StyleContext.add_provider_for_display(
    Gdk.Display.get_default()!, themeCss, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);

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

let swaybg: AstalIO.Process | null = null;
playlistName.subscribe(() => {
    const wallpaper = `/home/alec/Projects/flake/wallpapers/${playlistName.peek()}.jpg`;
    const old = swaybg;
    swaybg = AstalIO.Process.subprocessv(['swaybg', '-i', wallpaper, '-m', 'fill']);
    if (old) timeout(1000, () => old.kill());

    themeCss.load_from_string(`
        #status #mediaBtn { background-color: #${playlistColors[playlist.peek() - 1]}; }
        .backgroundOverlay { background-image: url("file://${wallpaper}"); }
        #lockscreen entry { background-image: linear-gradient(rgba(0, 0, 0, 0.3), rgba(0, 0, 0, 0.5)), url("file://${wallpaper}"); }
    `);
});

export const chngPlaylist = (direction: musicAction) => {
    const n = playlists.length;
    setPlaylist((playlist.peek() - 1 + (direction == 'next' ? 1 : n - 1)) % n + 1);

    // Stop playing music
    mpc('pause');
    setIsPlaying(false);

    setPlaylistName(playlists[playlist.peek() - 1]);

    // Clear the current cache and add the new playlist
    mpc('clear', `add ${playlistName.peek()}/`, 'shuffle');
    playPause(); // Start playing
};

export const initMedia = () => {
    setPlaylistName('Study'); // Must set to invoke binds
    mpc('crossfade 2', 'clear', `add ${playlistName.peek()}/`, 'shuffle');
};


export const Media = () =>
    <box name={'mediaBtn'}>
    <Gtk.EventControllerScroll
        flags={Gtk.EventControllerScrollFlags.VERTICAL}
        onScroll={(_, __, y) => {
            execAsync('mpc volume ' + ((y < 0) ? '+5' : '-5'))
        }}/>
        <image iconName={isPlaying.as(
            (v: boolean) => (v) ? 'media-playback-pause-symbolic' : 'media-playback-start-symbolic')
        }/>
    </box>
