let
  mod = "Mod4";
  currentWorkspace = "$(swaymsg -p -t get_workspaces | grep focused | grep -oE '[0-9]+')";
  workspace = direction: "exec sh -c 'current=${currentWorkspace}; target=$((current ${direction} 1)); [ $target -lt 1 ] && target=1; [ $target -gt 9 ] && target=9; [ $target -eq $current ] || swaymsg workspace number $target'";
  moveItemToWorkspace = direction: "exec sh -c 'current=${currentWorkspace}; target=$((current ${direction} 1)); [ $target -lt 1 ] && target=1; [ $target -gt 9 ] && target=9; [ $target -ne $current ] && swaymsg move container to workspace number $target && swaymsg workspace number $target'";
in {
  wayland.windowManager.sway = {
    config.keybindings = {
      # Volume
      "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_SINK@ .05+";
      "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_SINK@ .05-";
      "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_SINK@ toggle";

      # Brightness
      "XF86MonBrightnessUp" = "exec brightnessctl set +15%";
      "XF86MonBrightnessDown" = "exec brightnessctl set -15%";

      # Apps
      "${mod}+E" = "exec librewolf";
      "${mod}+return" = "exec foot";
      
      # Ags
      "${mod}+Z" = "exec ags toggle bar";
      "${mod}+space" = "exec ags toggle launcher";
      "${mod}+period" = "exec ags toggle emojiPicker";
      "${mod}+X" = "exec ags toggle quickSettings";
      "${mod}+A" = "exec ags toggle chat";
      "${mod}+C" = "exec ags request hideNotif"; # Closes last notification
      "${mod}+control+D" = "exec ags request toggleDND";

      "${mod}+V" = "exec ags toggle clipboard";
      # Enter = select entry, C = copy 2nd entry, E = edit image with swappy, W = wipe clipboard

      "${mod}+R" = "exec ags request record";
      # R = toggle mic, Q = toggle quality, C = clip last 30s, Space = record

      "XF86PowerOff" = "exec ags toggle powermenu";
      "${mod}+shift+S" = "exec ags toggle powermenu";
      # S = sleep, Q = shutdown, L = lock, R = restart 

      # Ags MPD controls
      "${mod}+control+period" = "exec ags request 'media next'";
      "${mod}+control+comma" = "exec ags request 'media prev'";
      "${mod}+greater" = "exec ags request 'media nextPlaylist'";
      "${mod}+less" = "exec ags request 'media prevPlaylist'";
      "${mod}+slash" = "exec ags request 'media toggle'";

      "Print" = ''exec wayshot -s "$(slurp)" --stdout | wl-copy''; # Screenshot

      # Move focus in a workspace
      "${mod}+left" = "focus left";
      "${mod}+right" = "focus right";
      "${mod}+up" = "focus up";
      "${mod}+down" = "focus down";

      # Move window in a workspace
      "${mod}+shift+left" = "move left";
      "${mod}+shift+right" = "move right";
      "${mod}+shift+up" = "move up";
      "${mod}+shift+down" = "move down";

      # Move through workspaces
      "control+${mod}+right" = workspace "+";
      "control+${mod}+left" = workspace "-";
      "control+${mod}+shift+right" = moveItemToWorkspace "+";
      "control+${mod}+shift+left" = moveItemToWorkspace "-";

      "${mod}+F" = "floating toggle";
      "F11" = "fullscreen toggle";
      "${mod}+Q" = "kill";
      "${mod}+tab" = "workspace back_and_forth";
    };
    # Scroll through workspaces
    extraConfig = ''
      bindsym --whole-window Mod4+button5 ${workspace "+"}
      bindsym --whole-window Mod4+button4 ${workspace "-"}
      bindsym --whole-window Control+Mod4+button5 ${moveItemToWorkspace "+"}
      bindsym --whole-window Control+Mod4+button4 ${moveItemToWorkspace "-"}
    '';
  };
}