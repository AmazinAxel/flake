import { exec } from 'astal';
import { Variable } from "astal";

export type musicAction = 'next' | 'prev';
const isPlaying: Variable<Boolean> = new Variable(false);
const playlist: Variable<Number> = new Variable(1);
const playlistName: Variable<String> = new Variable('Study');

// These playlists match with the folder names in ~/Music/
const playlists = ['Study', 'Focus', 'Synthwave', 'SynthAmbient', 'Ambient'];

export const updTrack = (direction: musicAction) => {
    exec('mpc pause'); // Pause to prevent bugs
    exec('mpc ' + direction); // Update track
    
    // Start playing again
    exec('mpc play');
    isPlaying.set(true);
    exec('isplaying');
};

export const playPause = () => {
    isPlaying.set(!isPlaying);
    exec('mpc toggle');
};

export const chngPlaylist = (direction: musicAction) => {
    if (direction == 'next') {
        (playlist.get() == playlists.length) 
        ? (playlist.set(1)) 
        : (playlist.set(Number(playlist.get()) + 1));
    } else if (direction == 'prev') {
        (playlist.get() == 1) 
        ? (playlist.set(playlists.length)) // Go to last  
        : (playlist.set(Number(playlist.get()) - 1));
    }

    // Stop playing music
    exec('mpc pause'); // Not really needed, but kept to prevent potential issues
    isPlaying.set(false);
    
    // Update the playlist and playlist names
    playlistName.set(playlists[Number(playlist.get()) - 1]);

    // Clear the current cache and add the new playlist
    exec('mpc clear');
    exec(`mpc add ${playlistName}/`);
    exec('mpc shuffle'); // Shuffle current playlist
    playPause() // Start playing song again

    // Change the wallpaper
    exec(`swww img /home/alec/wallpapers/${playlistName}.jpg --transition-type grow`);
};

exec('mpc crossfade 2'); // Set crossfade value

// On first start, clear and load new playlist
//exec('mpc clear');
//exec(`mpc add ${playlistName}/`);
exec(`swww img /home/alec//wallpapers/${playlistName}.jpg --transition-type grow`);
