{
  wayland.windowManager.sway.config = {
    keybindings = let
      mod = "Mod4";
    in {
      "${mod}+Shift+r" = "exec ags -q && ags"; # Restart Ags 
      
      # Volume & media controls
      XF86AudioRaiseVolume = "exec wpctl set-volume @DEFAULT_SINK@ .05+";
      XF86AudioLowerVolume = "exec wpctl set-volume @DEFAULT_SINK@ .05-";
      XF86AudioMute = "exec wpctl set-mute @DEFAULT_SINK@ toggle";

      # Brightness controls
      XF86MonBrightnessUp = "exec brightnessctl set +5%";
      XF86MonBrightnessDown = "exec brightnessctl set -5%";

      # Quick application access
      XF86PowerOff = "exec ags -t powermenu"; # Power menu
      "${mod}+e" = "exec microsoft-edge-stable";
      "${mod}+Return" = "exec foot"; # Terminal
      "${mod}+v" = "exec copyq toggle"; # Clipboard TODO replace w/ ags
      "${mod}+space" = "exec ags -t launcher"; # App laucher
      "${mod}+period" = "exec emote"; # Emoji picker TODO migrate to ags
      # TODO: Make Super + C hide the last notification

      # Screen recording
      "${mod}+R" = "exec ags -r 'recorder.start()'";
      "Control+${mod}+R" = "exec ags -r 'recorder.start(true)'"; # Custom video selection size
      Print = "exec ags -r 'recorder.screenshot()'";
      "Shift+Print" = "exec ags -r 'recorder.screenshot(true)'"; # Fullscreen screensot

      # Mpc player manipluation (Ags integration)
      # TODO: Add Super + , (left arrow) for previous track
      # TODO: Add Super + . (right arrow) for next track
      # TODO: Add super + / to play/pause MPC 

      # Widow positioning
      "${mod}+Shift+Left" = "move left";
      "${mod}+Shift+Right" = "move right";
      "${mod}+Shift+Up" = "move up";
      "${mod}+Shift+Down" = "move down";

      # Workspace, window, tab manipulation
      "Control+${mod}+Right" = "workspace next";
      "Control+${mod}+Left" = "workspace prev";
      "Control+${mod}+bracketright" = "workspace next";
      "Control+${mod}+bracketleft" = "workspace prev";
      "Control+${mod}+Button2" = "workspace next";
      "Control+${mod}+Button1" = "workspace prev";
      "Control+${mod}+Shift+Right" = "move to workspace next";
      "Control+${mod}+Shift+Left" = "move to workspace prev";
      "${mod}+s" = "togglefloating"; # Make window non-tiling
      F11 = "fullscreen toggle"; # F11 functionality
      "${mod}+q" = "kill"; # Close window

      # Scroll through workspaces
      "${mod}+Button4" = "workspace next";
      "${mod}+Button5" = "workspace prev";
      
      # Move and resize windows
      "${mod}+Button1" = "move";
      "${mod}+Button3" = "resize";
    };
  };
}