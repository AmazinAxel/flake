{ pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;

    checkConfig = true;
    wrapperFeatures.gtk = true;
    systemd.xdgAutostart = true;
    xwayland = false;
    config = {
      # super key
      modifier = "Mod4";
      bars = []; # No default ugly sway bar
      gaps = {
        outer = 0;
        inner = 5;
        smartBorders = "no_gaps";
        smartGaps = true;
      };

      focus.newWindow = "focus";

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
        dark0 = "#2e3440";
        dark4 = "#4c566a";
        white0 = "#d8dee9";
        white1 = "#e5e9f0";
        white2 = "#eceff4";

        blue0 = "#5e81ac";
        blue1 = "#81a1c1";
        blue2 = "#88c0d0";
        blue3 = "#8fbcbb";

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
        titlebar = false;
        border = 3;
        #commands = [
        #  {
        #    floating = false;
        #    criteria.class = "Minecraft";
        #  }
        #];
        hideEdgeBorders = "smart"; # or "both" or "none"
      };

      floating.border = 3;

      # Windows that should be opened in floating mode
      #floating = [
      #  { title = ""; }
      #  { class = ""; }
      #];

      startup = [
        { command = "gammastep -O 4500"; }
        { command = "fcitx5 -d"; }
        { command = "batsignal -w 20 -c 5 -d 0 -a Low battery"; }
      ];
    };

    /*extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    '';*/
  };
}