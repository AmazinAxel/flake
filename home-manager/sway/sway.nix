{ pkgs, ... }: {
  wayland.windowManager.sway = {
    enable = true;
    package = pkgs.swayfx;

    checkConfig = false;
    wrapperFeatures.gtk = true;
# INSTALL GAMMASTEP - temporary until Swayfx filter system is finished
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

      in {
        background = ""; # background color of window
        
        focused = { # focused window
          background = "#285577";
          border = "#4c7899";
          childBorder = "#285577";
          indicator = "#2e9ef4";
          text = "#ffffff";
        };

        /*focusedInactive = {

        };

        placeholder = {

        };

        unfocused = {

        };

        urgent = {

        };

        # Main (blue)
        set $cl_high #81A1C1
        # Indicator (gray)
        set $cl_indi #D8DEE9
        # Background (black)
        set $cl_back #3B4252
        # Foreground (gray)
        set $cl_fore #ECEFF4
        # Urgent (red)
        set $cl_urge #BF616A

        # Color group       border     bg         text       indi       childborder
        focused          = "${cl_high} ${cl_high} ${cl_fore} ${cl_indi} ${cl_high}";
        focused_inactive = "${cl_back} ${cl_back} ${cl_fore} ${cl_back} ${cl_back}";
        unfocused        = "${cl_back} ${cl_back} ${cl_fore} ${cl_back} ${cl_back}";
        urgent           = "${cl_urge} ${cl_urge} ${cl_fore} ${cl_urge} ${cl_urge}";*/
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
      ];

      #xwayland = false;
    };

    # SwayFX settings
    extraConfig = ''
      for_window [app_id="foot"] blur enable
      blur_radius 10
      corner_radius 4
    '';

    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION="1"
    '';
  };
}