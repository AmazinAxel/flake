{ pkgs, ...}: {
    wayland.windowManager.hyprland = {
        enable = true;
        xwayland.enable = false;
        plugins = [
            # TODO add hycov
        ];
        settings = {
            monitor = [ # https://wiki.hyprland.org/Configuring/Monitors/
                "        , preferred,     auto,     auto"
                "HDMI-A-1, 1920x1080@144, auto-left,  auto"
            ];

            input = {
                # Keyboard settings
                kb_layout = "us";
                repeat_delay = 300;
                
                # Mouse settings
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
                vfr = true; # Better power usage
                vrr = 1; # Always sync to monitor refresh rate, even when not fullscreened
                focus_on_activate = true;
                animate_manual_resizes = false;
                force_default_wallpaper = 0;
                disable_autoreload = true; # This saves power!
                disable_hyprland_logo = true;
                new_window_takes_over_fullscreen = 2;
                initial_workspace_tracking = 0; # Always open in current workspace
            };
            binds.scroll_event_delay = 0;

            decoration = {
                rounding = 5;
                blur = {
                    enabled = true;
                    xray = true;
                    special = false;
                    new_optimizations = "on";

                    size = 3;
                    passes = 5;
                    brightness = 0.8;
                    noise = 0.1;
                };

                shadow = {
                    enabled = false; # Diable shadow for better performance
                };

                # Blue light filter shader
                # TODO import instead of making it hardlinked to flake
                screen_shader = "/home/alec/Projects/flake/home-manager/hypr/blue-light-filter.glsl";
            };

            animations = {
                enabled = true;
                bezier = "decel, 0, 1, 0, 1";
                
                # Animations
                animation = [ 
                    "windows, 1, 4, decel, popin 80%"
                    "fade, 1, 2.5, decel"
                    " workspaces, 1, 4, decel, slide"
                ];
            };

            windowrule = let
                c = class: "float, ^(${class})$";
                t = title: "float, title:^(${title})(.*)$";
            in [
                (t "Open File")
                (t "Select a File")
                (t "Save As")
                (t "Library")
                (c "com.github.Aylur.ags")

                "size 20% 90%,^(copyq)$" # CopyQ autosize
                "size 50% 68%,^(emote)$" # Emote autosize
            ];

            windowrulev2 = [
                #"suppressevent maximize, class:.*" # Buggy window blockage
                "float,class:(copyq)$"
                "fullscreenstate, -1, 2,title:(Minecraft 1)(.*)$" # Minecraft titlebar fix
                "renderunfocused,title:(Minecraft 1)(.*)$" # Play Minecraft sounds even when not focused

                # Window organization
                "workspace 3,class:^microsoft-edge$" # MS Edge on Workspace 3
                "workspace 4,class:^teams-for-linux$" # Teams on Workspace 4
                "workspace 6,class:thunderbird" # Thunderbird on Workspace 6
                
                # No gaps when only window in workspace
                "bordersize 0, floating:0, onworkspace:w[tv1]"
                "rounding 0, floating:0, onworkspace:w[tv1]"
                "bordersize 0, floating:0, onworkspace:f[1]"
                "rounding 0, floating:0, onworkspace:f[1]"
            ];

            layerrule = [ # Ags
                "blur, gtk-layer-shell"
                "ignorezero, gtk-layer-shell" 
            ];

            env = [
                "GDK_BACKEND,wayland,x11"
                "T_QPA_PLATFORM,xcb" # FCITX
                
                # Some legacy apps still use xcursor
                "XCURSOR_THEME,Bibata-Modern-Ice"
                "XCURSOR_SIZE,24"
            ];

            exec-once = [
                "hyprlock" # TODO replace with ags
                "fcitx5 -d" # Chinese support
                "swww-daemon" # Wallpaper service
                "copyq --start-server" # TODO replace with ags
                "emote" # TODO replace with ags
                "mpd" # Daemon for mpc player
                "sleep 10 && reminders" # TODO integrate reminders script into ags
                "ags"

                # Autostart apps
                "[workspace 3 silent] microsoft-edge"
                "[workspace 4 silent] teams-for-linux"
                "[workspace 6 silent] thunderbird"

                #exec-once = /usr/bin/gnome-keyring-daemon --start --components=secrets &
                #exec-once = /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
                #exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
            ];

            workspace = [
                # Monitor handling (supports up to two monitors: main screen on left/above, laptop screen on right/bottom)
                "1, monitor:HDMI-A-1"
                "2, monitor:HDMI-A-1"
                "3, monitor:HDMI-A-1"
                "4, monitor:DP-1"
                #"5, monitor:DP-1"
                #"6, monitor:DP-1"
                #"7, monitor:DP-1"
                #"8, monitor:DP-1"
                
                # No gaps when only window in workspace
                "w[tv1], gapsout:0, gapsin:0"
                "f[1], gapsout:0, gapsin:0"
            ];
        };
    };

    #home.file."${config.xdg.configHome}/hypr/xdph.conf" = {
    xdg.configFile."hypr/xdph.conf" = {
        text = ''
            screencopy {
                allow_token_by_default = true
            }
        '';
    };
}
