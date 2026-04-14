#!/usr/bin/env fish

source /home/alec/homelab/scripts/logging.fish # Logging

# Check whether drive is mounted
if not mountpoint -q /media
    log "S: no drive"
    exit 1
end

mkdir -p /media/Music
set playlists \
    "Synthwave https://open.spotify.com/playlist/1YIe34rcmLjCYpY9wJoM2p" \
    "Focus https://open.spotify.com/playlist/3Qk9br14pjEo2aRItDhb2f" \
    "Study https://open.spotify.com/playlist/0vvXsWCC9xrXsKd4FyS8kM" \
    "SynthAmbient https://open.spotify.com/playlist/4murW7FWRb0LFbG7eUwDy0" \
    "Ambient https://open.spotify.com/playlist/07lYUEyTkWP3NqIa7Kzyqx"

for playlist in $playlists
    set name (echo $playlist | awk '{print $1}')
    set url (echo $playlist | awk '{print $2}')
    spotdl download "$url" --output /media/Music/$name
end

log "S: pulled music"
