
{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      input = {
        # Keyboard
        kb_layout = "us";
        repeat_delay = 300;

        # Mouse
        numlock_by_default = true;
        sensitivity = -0.5;

        # Laptop trackpad
        touchpad = {
          disable_while_typing = false;
          natural_scroll = false;
          clickfinger_behavior = true;
          scroll_factor = 0.5;
        };
        scroll_method = "2fg"; # Two-finger scroll
      };

      # General look, feel and behavior
      general = {
        gaps_in = 3;
        gaps_out = 4;
        border_size = 3;
        layout = "dwindle";

        # Window border colors
        "col.active_border" = "rgb(81A1C1) rgb(5E81AC)";
        "col.inactive_border" = "rgb(434C5E)";
      };

      dwindle = {
        preserve_split = true;
        force_split = 2;
      };

      misc = {
        vrr = 1; # Sync to monitor refresh rate even when not fullscreened
        focus_on_activate = true;
        animate_manual_resizes = false;
        force_default_wallpaper = 0;
        disable_autoreload = true;
        disable_hyprland_logo = true;
        new_window_takes_over_fullscreen = 2;
        initial_workspace_tracking = 0; # Always open in current workspace
        #disable_hyprland_qtutils_check = true; # Hide annoying Hypr popup
      };
      binds.scroll_event_delay = 0;
      ecosystem = {
        no_update_news = true;
        no_donation_nag = true;
      };

      decoration = {
        rounding = 5;
        blur = {
          enabled = true;
          xray = true;

          size = 3;
          passes = 5;
          brightness = 0.8;
          noise = 0.1;
        };

        shadow.enabled = false; # Better performance

        # Blue light filter shader
        screen_shader = "${./blue-light-filter.glsl}";
      };

      animations = {
        enabled = true;
        bezier = "decel, 0, 1, 0, 1";

        # Animations
        animation = [
          "windows, 1, 4, decel, popin 80%"
          "fade, 1, 2.5, decel"
          "workspaces, 1, 4, decel, slide"
        ];
      };

      windowrule = let
        c = class: "float, class:^(${class})$";
        t = title: "float, title:^(${title})(.*)$";
      in [
        (c "xdg-desktop-portal-gtk")
      ];

      # Play Minecraft sounds even when not focused
      windowrulev2 = [ "renderunfocused, title:(Minecraft*)(.*)$" ];

      # Hide clipboard history during screenshares
      layerrule = [ "noscreenshare,clipboard" ];

      env = [ # Some legacy apps still use xcursor
        "XCURSOR_THEME, Bibata-Modern-Ice"
        "XCURSOR_SIZE, 24"
      ];

      exec-once = [
        "hyprlock" # Screen lock
        "fcitx5 -d" # Chinese input daemon
      ];
    };
  };
}
