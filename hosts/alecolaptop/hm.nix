{
  wayland.windowManager.sway = {
    config = {
      startup = [{ command = "librewolf"; }];
      keybindings."Mod4+D" = ''exec wayshot -s "$(slurp)" --stdout | wl-copy''; # Side mouse key screenshot
    };
    extraConfig = ''
      for_window [app_id="librewolf"] move to workspace 1; workspace 1
    '';
  };
}
