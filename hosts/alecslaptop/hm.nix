{
  wayland.windowManager.sway.config = {
    output = { # Monitors
      "HDMI-A-1".pos = "1280 0";
    };

    todo

    monitor = [
      "        , preferred,     auto,     auto"
      "HDMI-A-1, 1920x1080@144, auto-left,  auto"
    ];

    exec-once = [ # Autostart apps
      "[workspace 3 silent] librewolf"
      "[workspace 7 silent] thunderbird"
      "[workspace 8 silent] teams-for-linux"
    ];

    workspace = [
      "1, monitor:HDMI-A-1"
      "2, monitor:HDMI-A-1"
      "3, monitor:HDMI-A-1"
      "4, monitor:HDMI-A-1"
      "5, monitor:DP-1"
    ];

    bind = [ "Super, D, exec, screenshot" ]; # Custom side mouse key for quick screenshots
  };
}