{
  programs.niri.settings = {
    input = {
      focus-follows-mouse.enable = true;
      workspace-auto-back-and-forth = true;
      keyboard = {
        repeat-delay = 300;
        repeat-rate = 20;
      };

      touchpad = {
        tap = true;
        dwt = true; # Disable touchpad while typing
        drag = true; # Tap & drag
        natural-scroll = false;
      };

      mouse = {
        # accel-speed 0.2
        # accel-profile "flat"
        # scroll-factor 1.0
        # scroll-factor vertical=1.0 horizontal=-2.0
        # scroll-method "no-scroll"
        # scroll-button 273
        # scroll-button-lock
      };

      trackpoint.enable = false;
      trackball.enable = false;
      tablet.enable = false;
      touch.enable = false;
    };

    layout = {
      gaps = 4; # Window gaps

      default-column-width.proportion = 0.5;

      focus-ring.enable = false;
      tab-indicator.enable = false;
      insert-hint.display.color = "#5e81ac";

      border = {
        width = 2;
        active.color = "#5e81ac";
        inactive.color = "#4c566a";
        urgent.color = "#bf616a";
      };
    };

    spawn-at-startup = [
      { argv = ["hyprlock"]; }
      { argv = ["fcitx5" "-d"]; }
      { argv = ["gammastep" "-O" "3000"]; }
      { argv = ["batsignal" "-w" "20" "-c" "5" "-d" "0" "-a" "Low battery"]; }
    ];

    hotkey-overlay = {
      skip-at-startup = true;
    };

    prefer-no-csd = true;
    screenshot-path = null;

    #animations = {

    #};

    gestures.hot-corners.enable = false;

    window-rules = [{
      matches = [
        { app-id = ''^org\.keepassxc\.KeePassXC$''; }
        { app-id = ''^org\.gnome\.World\.Secrets$''; }
      ];
      block-out-from = "screen-capture";
    }];
  };
}

