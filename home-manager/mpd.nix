{
  services.mpd = {
    enable = true;
    musicDirectory = "/home/alec/Music";
    playlistDirectory = "/home/alec/Music";

    # Audio output declaration is required for volume control
    extraConfig = ''
      restore_paused "no"
      metadata_to_use	"artist,title,track,name,date"
      audio_output {
        type "pipewire"
        name "Main Output"
        always_on "yes"
      }
    '';
  };
}
