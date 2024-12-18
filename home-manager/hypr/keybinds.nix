{
  wayland.windowManager.hyprland.settings = {
    bind = [
      "SuperShift, R, exec, ags -q && ags" # Restart ags (when sleeping external monitor)

      # Quick app access
      "Super, return, exec, foot" # Terminal
      "Super, E, exec, microsoft-edge-stable" # Edge
      "Super, Period, exec, emote" # Emoji picker TODO replace w/ ags
      "Super, V, exec, copyq toggle" # Clipboard TODO replace w/ ags
      ",XF86PowerOff,  exec, ags -t powermenu" # Power menu
      "Super, space, exec, ags -t launcher" # App laucher
      # TODO: Make Super + C hide the last notification

      # Screen recording
      "Super, R, exec, ags -r 'recorder.start()'"
      "ControlSuper, R, exec, ags -r 'recorder.start(true)'" # Custom video selection size
      ",Print, exec, ags -r 'recorder.screenshot()'"
      "SHIFT, Print, exec, ags -r 'recorder.screenshot(true)'" # Fullscreen screensot

      # Mpc player manipluation (Ags integration)
      # TODO: Add Super + , (left arrow) for previous track
      # TODO: Add Super + . (right arrow) for next track
      # TODO: Add super + / to play/pause MPC 

      # Widow positioning
      "SuperShift, left, movewindow, l"
      "SuperShift, right, movewindow, r"
      "SuperShift, up, movewindow, u"
      "SuperShift, down, movewindow, d"

      # Keybinds to commonly used workspaces
      #"Super, d, workspace, 1"
      #"Super, f, workspace, 2"
      #"Super, g, workspace, 3"

      # Workspace, window, tab manipulation
      "ControlSuper, right, workspace, +1"
      "ControlSuper, left, workspace, -1"
      "ControlSuper, BracketLeft, workspace, -1"
      "ControlSuper, BracketRight, workspace, +1"
      "ControlSuper, mouse_down, workspace, -1"
      "ControlSuper, mouse_up, workspace, +1"
      "ControlSuperShift, Right, movetoworkspace, +1"
      "ControlSuperShift, Left, movetoworkspace, -1"
      "Super, Q, killactive" # Kill active app

      # TODO Win + tab should automagically open up an all-apps switcher and switch between them, this is temporary
      "ALT, Tab, cyclenext"
      "ALT, Tab, bringactivetotop"

      # Fullscreen
      ",F11, fullscreen, 0" # F11 functionality
      "ControlShift,F, fullscreenstate, -1, 2" # Fake fullscreen utility

      # Workspace mouse manipulation (use e+1 to skip empty workspaces)
      "Super, mouse_up, workspace, +1"
      "Super, mouse_down, workspace, -1"
      "SuperShift, mouse_up, movewindow, r"
      "SuperShift, mouse_down, movewindow, l"
      "ControlSuperShift, mouse_up, movetoworkspace, +1"
      "ControlSuperShift, mouse_down, movetoworkspace, -1"
      
      "Super, F, workspaceopt, allfloat" # Makes a workspace floating TODO change to just window floating status

      # Special workspaces
      #"SUPER, C, movetoworkspace, special"
      #"SUPER, D, togglespecialworkspace"
    ];

    bindle = [
      # Volume/mute buttons
      ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_SINK@ .05+"
      ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_SINK@ .05-"
      ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_SINK@ toggle"

      # Brightness buttons
      ",XF86MonBrightnessUp, exec, brightnessctl set +5%"
      ",XF86MonBrightnessDown, exec, brightnessctl set 5%-"
    ];

    bindm = [ # Move & resize windows w/ mouse
      "Super, mouse:272, movewindow"
      "Super, mouse:273, resizewindow"
    ];

    bindn = [
      ", mouse:274, exec, wl-copy -pc" # Disables middle mouse paste
    ];
  }; 
}