{ pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    wrapperFeatures.gtk = true;
    systemd.xdgAutostart = true;
    xwayland = false;

    config = {
      # super key
      modifier = "Mod4";
      bars = []; # No default ugly sway bar
      gaps.inner = 5;

      focus = {
        newWindow = "focus";
        followMouse = "always"; # "yes"
      };

      workspaceAutoBackAndForth = true;

      input = {
        "*".xkb_variant = "nodeadkeys";
        "type:touchpad".tap = "enabled";
        "type:touchpad".drag_lock = "disable";
        "type:keyboard" = {
          repeat_delay = "300";
          repeat_rate = "30";
        };
        
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
      };

      floating.border = 3;

      startup = [
        { command = "gammastep -O 4500"; }
        { command = "fcitx5 -d"; }
        { command = "batsignal -w 20 -c 5 -d 0 -a Low battery"; }
        { command = "wl-gammarelay-rs && busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q 3500"; }
      ];
    };
  };
}