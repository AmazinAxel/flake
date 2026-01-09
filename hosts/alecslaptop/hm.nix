{
  wayland.windowManager.hyprland.settings = {
    todo = ''/-output "eDP-1" {
      // Resolution and, optionally, refresh rate of the output.
      // The format is "<width>x<height>" or "<width>x<height>@<refresh rate>".
      // If the refresh rate is omitted, niri will pick the highest refresh rate
      // for the resolution.
      // If the mode is omitted altogether or is invalid, niri will pick one automatically.
      // Run `niri msg outputs` while inside a niri instance to list all outputs and their modes.
      mode "1920x1080@120.030"

      // You can use integer or fractional scale, for example use 1.5 for 150% scale.
      scale 2

      // Transform allows to rotate the output counter-clockwise, valid values are:
      // normal, 90, 180, 270, flipped, flipped-90, flipped-180 and flipped-270.
      transform "normal"

      // Position of the output in the global coordinate space.
      // This affects directional monitor actions like "focus-monitor-left", and cursor movement.
      // The cursor can only move between directly adjacent outputs.
      // Output scale and rotation has to be taken into account for positioning:
      // outputs are sized in logical, or scaled, pixels.
      // For example, a 3840×2160 output with scale 2.0 will have a logical size of 1920×1080,
      // so to put another output directly adjacent to it on the right, set its x to 1920.
      // If the position is unset or results in an overlap, the output is instead placed
      // automatically.
      position x=1280 y=0
  }'';
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