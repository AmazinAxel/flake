{
  wayland.windowManager.sway = {
    config = {
      output = {
        "DP-1".position = "1920 0";
        "HDMI-A-1" = {
          resolution = "1920x1080@60Hz";
          position = "0 0";
        };
      };

      workspaceOutputAssign = [
        { workspace = "1"; output = "HDMI-A-1"; }
        { workspace = "2"; output = "HDMI-A-1"; }
        { workspace = "3"; output = "HDMI-A-1"; }
        { workspace = "4"; output = "DP-1"; }
        { workspace = "5"; output = "DP-1"; }
        { workspace = "6"; output = "DP-1"; }
        { workspace = "7"; output = "DP-1"; }
        { workspace = "8"; output = "DP-1"; }
        { workspace = "9"; output = "DP-1"; }
      ];

      startup = [
        { command = "discord"; }
        { command = "librewolf"; }
      ];
    };

    extraConfig = ''
      for_window [app_id="discord"] move to workspace 1; workspace 1
      for_window [app_id="librewolf"] move to workspace 4; workspace 4
    '';

    extraSessionCommands = ''
      export LIBVA_DRIVER_NAME=nvidia
      export GBM_BACKEND=nvidia-drm
      export __GLX_VENDOR_LIBRARY_NAME=nvidia
      export NVD_BACKEND=direct
      export WLR_NO_HARDWARE_CURSORS=1
    '';
  };
}
