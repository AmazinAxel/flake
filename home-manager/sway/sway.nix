{ pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    checkConfig = false;
    wrapperFeatures.gtk = true;
    xwayland = false;

    config = {
      modifier = "Mod4"; # Super
      bars = []; # No default ugly sway bar
      gaps.inner = 5;

      focus = {
        newWindow = "focus";
        followMouse = "always"; # "yes"
      };

      workspaceAutoBackAndForth = true;

      input = {
        "*".xkb_variant = "nodeadkeys";
        "type:pointer" = {
          accel_profile = "flat";
          pointer_accel = "-0.1";
        };
        "type:touchpad" = {
          tap = "enabled";
          drag_lock = "disable";
        };
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
          indicator = blue0;
          text = white2;
        };

        focusedInactive = {
          background = blue0;
          border = blue0;
          childBorder = blue0;
          indicator = blue0;
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
      output."*".adaptive_sync = "on"; # VRR

      startup = [
        { command = "fcitx5 -d"; }
        { command = "batsignal -w 20 -c 5 -d 0 -a Low battery"; }
        { command = "wl-gammarelay-rs"; }
        { command = "sleep 1 && busctl --user set-property rs.wl-gammarelay / rs.wl.gammarelay Temperature q 3500"; }
      ];
    };
    # Disable middle mouse paste
    extraConfig = ''
      primary_selection disabled
    '';
  };
}