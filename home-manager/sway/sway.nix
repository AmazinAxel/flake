{ pkgs, inputs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    package = inputs.swayfx.packages."x86_64-linux".swayfx-unwrapped;

    checkConfig = false;
    wrapperFeatures.gtk = true;
    systemd.xdgAutostart = true;
    xwayland = true;
    config = {
      # super key
      modifier = "Mod4";
      bars = []; # No default ugly sway bar
      gaps = {
        outer = 0;
        inner = 15;
        smartBorders = "no_gaps"; # on or off
        smartGaps = true;
      };

      #workspaceLayout = "tabbed";
      workspaceAutoBackAndForth = true;

      input = {
        "*".xkb_variant = "nodeadkeys";
        "type:touchpad".tap = "enabled";
        "type:keyboard" = {
          repeat_delay = "200";
          repeat_rate = "30";
        };
      };

      output = { # Monitors
        #"*".scale = "1.3";
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
        #{ command = "desktop-widgets &"; always = true; } # Ags widgets
        { command = "gammastep -O 4500"; } # TODO replace with shader
        { command = "fcitx5 -d"; } # Chinese support
        { command = "swww-daemon"; } # Wallpaper service        
        { command = "copyq --start-server"; } # TODO replace with ags
        { command = "emote"; } # TODO replace with ags
        { command = "mpd"; } # Daemon for mpc player
        { command = "sleep 10 && reminders"; } # TODO replace with ags
        { command = "spice-vdagent"; } # TODO remove when finished with vm
        # TODO set up swayidle
      ];
    };

    # SwayFX settings
    extraConfig = ''
      shadows enable
      corner_radius 2
      for_window [app_id="foot"] blur enable
      blur_radius 10
    '';
    
    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    '';
  };
}
