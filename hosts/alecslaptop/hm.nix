{
  wayland.windowManager.sway = {
    config = {
      output = {
        "HDMI-A-1" = {
          resolution = "1920x1080@144Hz";
          position = "0 0";
        };
        "*".position = "1920 0"; # Laptop/other monitors
      };

      startup = [
        { command = "librewolf"; }
        { command = "thunderbird"; }
        { command = "teams-for-linux"; }
      ];
      workspaceOutputAssign = [
        { workspace = "1"; output = "HDMI-A-1"; }
        { workspace = "2"; output = "HDMI-A-1"; }
        { workspace = "3"; output = "HDMI-A-1"; }
        { workspace = "4"; output = "HDMI-A-1"; }
        { workspace = "5"; output = "DP-1"; }
      ];
      keybindings."Mod4+D" = ''exec wayshot -s "$(slurp)" --stdout | wl-copy''; # Side mouse key screenshot
    };
    extraConfig = ''
      for_window [app_id="librewolf"] move to workspace 3; workspace 3
      for_window [app_id="thunderbird"] move to workspace 7; workspace 7
      for_window [app_id="teams-for-linux"] move to workspace 8; workspace 8
    '';
  };
}
