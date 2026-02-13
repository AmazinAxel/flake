{
  wayland.windowManager.sway.config = {
    keybindings = let
      mod = "Mod4";
      currentWorkspace = "$(swaymsg -p -t get_workspaces | grep focused | grep -oE '[0-9]+')";
      workspace = direction: "exec sh -c 'c=${currentWorkspace}; t=$((c ${direction} 1)); [ $t -gt 10 ] && t=1; [ $t -lt 1 ] && t=10; swaymsg workspace number $t'";
      moveItemToWorkspace = direction: "exec sh -c 'c=${currentWorkspace}; t=$((c ${direction} 1)); [ $t -gt 10 ] && t=1; [ $t -lt 1 ] && t=10; swaymsg move container to workspace number $t && swaymsg workspace number $t'";
    in {
      # Volume
      "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_SINK@ .05+";
      "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_SINK@ .05-";
      "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_SINK@ toggle";

      # Brightness
      "XF86MonBrightnessUp" = "exec brightnessctl set +15%";
      "XF86MonBrightnessDown" = "exec brightnessctl set -15%";

      # Power menu
      "XF86PowerOff" = "exec ags toggle powermenu";
      "${mod}+shift+S" = "exec toggle powermenu";

      "${mod}+E" = "exec librewolf"; # Browser
      "${mod}+return" = "exec foot"; # Terminal
      "${mod}+Z" = "exec ags toggle bar"; # Show/hide bar
      "${mod}+V" = "exec ags toggle clipboard"; # Clipboard
      "${mod}+space" = "exec ags toggle launcher"; # App laucher
      "${mod}+period" = "exec ags toggle emojiPicker"; # Emoji picker
      "${mod}+X" = "exec ags toggle quickSettings"; # Quicksettings
      "${mod}+A" = "exec ags toggle chat"; # Chat
      "${mod}+C" = "exec ags request hideNotif"; # Clear last notification
      "${mod}+R" = "exec ags request record"; # Clear last notification
      "${mod}+control+D" = "exec ags request toggleDND"; # Clear last notification

      "${mod}+control+period" = "exec ags request 'media next'"; # Next mpd song
      "${mod}+control+comma" = "exec ags request 'media prev'"; # Previous mpd song
      "${mod}+greater" = "exec ags request 'media nextPlaylist'"; # Next mpd playlist (Shift+.)
      "${mod}+less" = "exec ags request 'media prevPlaylist'"; # Previous mpd playlist (Shift+,)
      "${mod}+slash" = "exec ags request 'media toggle'"; # Toggle song status

      "Print" = ''exec wayshot -s "$(slurp)" --stdout | wl-copy''; # Screenshot

      # Focus
      "${mod}+left" = "focus left";
      "${mod}+right" = "focus right";
      "${mod}+up" = "focus up";
      "${mod}+down" = "focus down";

      # Window positioning
      "${mod}+shift+left" = "move left";
      "${mod}+shift+right" = "move right";
      "${mod}+shift+up" = "move up";
      "${mod}+shift+down" = "move down";

      # Workspaces
      "control+${mod}+right" = workspace "+";
      "control+${mod}+left" = workspace "-";
      "control+${mod}+shift+right" = moveItemToWorkspace "+";
      "control+${mod}+shift+left" = moveItemToWorkspace "-";

      # Scroll through workspaces
      "${mod}+button4" = workspace "+";
      "${mod}+button5" = workspace "-";

      "${mod}+shift+F" = "togglefloating"; # Make window non-tiling
      "F11" = "fullscreen toggle"; # Fullscreen
      "${mod}+Q" = "kill"; # Close window

      "${mod}+tab" = "workspace back_and_forth";
    };
  };
}