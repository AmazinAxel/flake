{
  wayland.windowManager.sway = {
    config = {
      output."eDP-1".scale = "1.3";
      startup = [{ command = ''swaymsg "workspace 1; exec librewolf"''; }];
      keybindings."Mod4+D" = ''exec wayfreeze --hide-cursor --after-freeze-cmd 'grim -g "$(slurp)" - | wl-copy; killall wayfreeze' ''; # Side mouse key screenshot
    };
    extraConfig = ''
    '';
  };
}
