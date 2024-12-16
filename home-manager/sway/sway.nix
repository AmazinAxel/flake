{ pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.swayfx;

    checkConfig = false;
    wrapperFeatures.gtk = true;
    config = {
      # super key
      modifier = "Mod4";
      bars = []; # No default ugly sway bar
      gaps = {
        outer = 0;
        inner = 15;
      };

      #workspaceLayout = "tabbed";
      workspaceAutoBackAndForth = true;

      input = {
        "*".xkb_variant = "nodeadkeys";
        "type:touchpad".tap = "enabled";
      };

      output = { # Monitors
        "*" = {
          background = "~/.config/wallpaper.jpeg fill";
          scale = "1.3";
        };
        "HDMI-A-1".pos = "1280 0";
      };

      colors = let # Color vars
        dark0 = "#2e3440"; # Darkest
        dark4 = "#4c566a"; # Dark
        white0 = "#d8dee9"; # Off-white
        white1 = "e5e9f0"; # White
        white2 = "#eceff4"; # Snow White

        blue0 = "#5e81ac"; # Dark blue
        blue1 = "#81a1c1"; # Lighter blue
        blue2 = "#88c0d0"; # Teal blue
        blue3 = "#8fbcbb"; # Greenish-blue

        purple = "#b48ead";
        green = "#a3be8c";
        yellow = "#ebcb8b";
        orange = "#d08770";
        red = "#bf616a";
      in {
        background = ""; # background color of window
        
        focused = { # focused window
          background = blue0;
          border = blue0;
          childBorder = blue0;
          indicator = dark4;
          text = white2;
        };

        focusedInactive = {
          background = blue0;
          border = blue0;
          childBorder = blue0;
          indicator = dark0;
          text = white1;     
        };

        placeholder = {
          background = dark0;
          border = dark4;
          childBorder = dark4;
          indicator = dark0;
          text = white1;
        };

        unfocused = {
          background = dark0;
          border = dark4;
          childBorder = dark4;
          indicator = dark0;
          text = white0;
        };

        urgent = {
          background = red;
          border = orange;
          childBorder = orange;
          indicator = dark4;
          text = white2;
        };
      };

      window = {
        border = 5;
        titlebar = false;
        #commands = [
        #  {
        #    floating = false;
        #    criteria.class = "Minecraft";
        #  }
        #];
        hideEdgeBorders = "smart"; # or "both" or "none"
      };

      # Windows that should be opened in floating mode
      #floating = [
      #  { title = ""; }
      #  { class = ""; }
      #];

      startup = [
        { command = "ags &"; always = true; }
        { command = "gammastep -O 4500"; } # TODO replace with shader
        { command = "fcitx5 -d"; } # Chinese support
        { command = "swww-daemon"; } # Wallpaper service        
        { command = "copyq --start-server"; } # TODO replace with ags
        { command = "emote"; } # TODO replace with ags
        { command = "mpd"; } # Daemon for mpc player
        { command = "sleep 10 && reminders"; } # TODO replace with ags
        # TODO set up swayidle
      ];

      #xwayland = false;
    };

    # SwayFX settings
    extraConfig = ''
      for_window [app_id="foot"] blur enable
      blur_radius 10
      corner_radius 4

      seat seat0 xcursor_theme Bibata-Modern-Ice 24
    '';

    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    '';
  };
}