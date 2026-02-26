{
  wayland.windowManager.sway = {
    config = {
      startup = [{ command = ''swaymsg "workspace 1; exec librewolf"''; }];
      keybindings."Mod4+D" = ''exec wayshot -s "$(slurp)" --stdout | wl-copy''; # Side mouse key screenshot
    };
    extraConfig = ''
    '';
  };
}
