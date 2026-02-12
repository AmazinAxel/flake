{
    "Mod+Return".action.spawn = "foot";
    "Mod+Z".action.spawn = [ "ags" "toggle" "bar" ];
    "Mod+X".action.spawn = [ "ags" "toggle" "quickSettings" ];
    "Mod+E".action.spawn = "librewolf";
    "Mod+Space".action.spawn = [ "ags" "toggle" "launcher" ];
    "Mod+A".action.spawn = [ "ags" "toggle" "chat" ];
    "Mod+V".action.spawn = [ "ags" "toggle" "clipboard" ];
    "Mod+Period".action.spawn = [ "ags" "toggle" "emojiPicker" ];
    "Mod+Shift+S".action.spawn = [ "ags" "toggle" "powermenu" ];

    "Mod+C".action.spawn = [ "ags" "request" "hideNotif" ];
    "Mod+R".action.spawn = [ "ags" "request" "record" ];
    "Mod+Control+R".action.spawn = [ "ags" "request" "record" ];
    "Mod+Shift+D".action.spawn = [ "ags" "request" "toggleDND" ];
    "Mod+Control+Period".action.spawn = [ "ags" "request" "media next" ];
    "Mod+Control+Comma".action.spawn = [ "ags" "request" "media prev" ];
    "Mod+Shift+Period".action.spawn = [ "ags" "request" "media nextPlaylist" ];
    "Mod+Shift+Comma".action.spawn = [ "ags" "request" "media prevPlaylist" ];
    "Mod+Slash".action.spawn = [ "ags" "request" "media toggle" ];

    "XF86AudioRaiseVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_SINK@" ".05+" ];
    "XF86AudioLowerVolume".action.spawn = [ "wpctl" "set-volume" "@DEFAULT_SINK@" ".05-" ];
    "XF86MonBrightnessUp".action.spawn = [ "brightnessctl" "set" "+15%" ];
    "XF86MonBrightnessDown".action.spawn = [ "brightnessctl" "set" "15%-" ];

    "Mod+O".action.toggle-overview = { };
    "Mod+Q".action.close-window = { };

    # Focus movement
    "Mod+Left".action.focus-column-left = { };
    "Mod+Down".action.focus-window-down = { };
    "Mod+Up".action.focus-window-up = { };
    "Mod+Right".action.focus-column-right = { };

    # Move windows
    "Mod+Ctrl+Left".action.move-column-left = { };
    "Mod+Ctrl+Down".action.move-window-down = { };
    "Mod+Ctrl+Up".action.move-window-up = { };
    "Mod+Ctrl+Right".action.move-column-right = { };

    # Monitor focus
    "Mod+Shift+Left".action.focus-monitor-left = { };
    "Mod+Shift+Down".action.focus-monitor-down = { };
    "Mod+Shift+Up".action.focus-monitor-up = { };
    "Mod+Shift+Right".action.focus-monitor-right = { };

    # Move to monitor
    "Mod+Shift+Ctrl+Left".action.move-column-to-monitor-left = { };
    "Mod+Shift+Ctrl+Down".action.move-column-to-monitor-down = { };
    "Mod+Shift+Ctrl+Up".action.move-column-to-monitor-up = { };
    "Mod+Shift+Ctrl+Right".action.move-column-to-monitor-right = { };

    # Workspace focus
    "Mod+Page_Down".action.focus-workspace-down = { };
    "Mod+Page_Up".action.focus-workspace-up = { };
    "Mod+U".action.focus-workspace-down = { };
    "Mod+I".action.focus-workspace-up = { };

    # Move to workspace
    "Mod+Ctrl+Page_Down".action.move-column-to-workspace-down = { };
    "Mod+Ctrl+Page_Up".action.move-column-to-workspace-up = { };
    "Mod+Ctrl+U".action.move-column-to-workspace-down = { };
    "Mod+Ctrl+I".action.move-column-to-workspace-up = { };

    "Mod+Shift+Page_Down".action.move-workspace-down = { };
    "Mod+Shift+Page_Up".action.move-workspace-up = { };
    "Mod+Shift+U".action.move-workspace-down = { };
    "Mod+Shift+I".action.move-workspace-up = { };

    "Mod+WheelScrollDown".cooldown-ms = 150;
    "Mod+WheelScrollDown".action.focus-workspace-down = { };
    "Mod+WheelScrollUp".cooldown-ms = 150;
    "Mod+WheelScrollUp".action.focus-workspace-up = { };
    "Mod+Ctrl+WheelScrollDown".cooldown-ms = 150;
    "Mod+Ctrl+WheelScrollDown".action.move-column-to-workspace-down = { };
    "Mod+Ctrl+WheelScrollUp".cooldown-ms = 150;
    "Mod+Ctrl+WheelScrollUp".action.move-column-to-workspace-up = { };
    "Mod+WheelScrollRight".action.focus-column-right = { };
    "Mod+WheelScrollLeft".action.focus-column-left = { };
    "Mod+Ctrl+WheelScrollRight".action.move-column-right = { };
    "Mod+Ctrl+WheelScrollLeft".action.move-column-left = { };
    "Mod+Shift+WheelScrollDown".action.focus-column-right = { };
    "Mod+Shift+WheelScrollUp".action.focus-column-left = { };
    "Mod+Ctrl+Shift+WheelScrollDown".action.move-column-right = { };
    "Mod+Ctrl+Shift+WheelScrollUp".action.move-column-left = { };

    # Previous workspace
    "Alt+Tab".action.focus-workspace-previous = { };

    # Fullscreen / floating
    "Mod+Shift+F".action.maximize-column = { };
    "Mod+Ctrl+Shift+F".action.toggle-windowed-fullscreen = { };
    "F11".action.fullscreen-window = { };

    "Mod+F".action.toggle-window-floating = { };

    # Screenshot
    "Print".action.screenshot = { show-pointer = false; };

    # Keyboard inhibit
    "Mod+Escape".allow-inhibiting = false;
    "Mod+Escape".action.toggle-keyboard-shortcuts-inhibit = { };
  };
}