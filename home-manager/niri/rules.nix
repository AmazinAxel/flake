{
  programs.niri.settings = {
    window-rules = [
      { # Rounded corners for all windows
        geometry-corner-radius = {
          bottom-left = 5.0;
          bottom-right = 5.0;
          top-left = 5.0;
          top-right = 5.0;
        };
        clip-to-geometry = true;
        open-focused = false; # Don't give app focus on start
      }
      {
        matches = [
          { app-id = ''^librewolf$''; }
          { app-id = ''^code$''; }
        ];
        open-maximized = true;
      }
      {
        matches = [
          { app-id = ''^librewolf$''; }
          { app-id = ''^code$''; }
        ];
        open-maximized = true;
      }
    ];

    # Hide clipboard from screen capture
    layer-rules = [{
      matches = [{ namespace = ''clipboard''; }];
      block-out-from = "screen-capture";
    }];
  };
}