{
  imports = [ ../../home-manager/laptop.nix ];

  wayland.windowManager.sway.config = {
    output."eDP-1".scale = "1.3";
    startup = [{ command = ''swaymsg "workspace 1; exec zen-beta"''; }];

    # Side mouse key screenshot
    keybindings."Mod4+D" = ''exec wayfreeze --hide-cursor --after-freeze-cmd 'grim -g "$(slurp)" - | wl-copy; killall wayfreeze' '';
  };

  # Platformio for Neovim
  programs.neovim.plugins = [(pkgs.vimUtils.buildVimPlugin {
    pname = "vim-platformio";
    version = "1.0";
    src = pkgs.fetchFromGitHub {
      owner = "normen";
      repo = "vim-pio";
      rev = "master";
      hash = "sha256-BW+bBb17+ukfWTg1zMMBxHk0thL6xFWiPXuHjB5K6VE=";
    };
  })];
}
