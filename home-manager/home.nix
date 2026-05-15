{ inputs, pkgs, ... }: {
  imports = [
    ./sway/keybinds.nix
    ./sway/sway.nix

    ./nordvim/nordvim.nix

    ./fish.nix
    ./foot.nix
    ./gtk.nix
    ./mpd.nix
    ./swappy.nix
    ./starship.nix
    ./vscode.nix
    ./zen.nix

    inputs.ags.homeManagerModules.default
  ];

  programs = {
    home-manager.enable = true;
    ags = {
      enable = true;
      configDir = ../ags;
      systemd.enable = true;

      extraPackages = with inputs.astal.packages.x86_64-linux; [
        apps # App launcher
        auth
        battery
        bluetooth
        mpris
        notifd
        wireplumber

        pkgs.gtksourceview5 # Chat code syntax highlighting
        pkgs.glib-networking # AI chat
        pkgs.brightnessctl
        pkgs.sway # swaymsg IPC
        pkgs.iwd # wifi control
        pkgs.mpc # MPD
        pkgs.cliphist
        pkgs.wl-clipboard # wl-copy
        pkgs.swappy
        pkgs.swaybg
        pkgs.procps # pkill for gpu-screenrec
      ];
    };
  };
  systemd.user.startServices = "sd-switch"; # Better system unit reloads

  home = {
    stateVersion = "26.05";
    username = "alec";
    homeDirectory = "/home/alec";

    # Global cursor
    pointerCursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      sway.enable = true;
    };
  };

  # Astal clipboard management
  services.cliphist = {
    enable = true;
    extraOptions = [ "-preview-width" "200" "-max-items" "20" "-max-dedupe-search" "5" ];
  };

  xdg = {
    dataFile."fonts" = { # Symlink fonts
      target = "./fonts";
      source = ./fonts;
    };

    userDirs = {
      enable = true;
      createDirectories = true; # Auto-creates all directories
      extraConfig = {
        PROJECTS = "/home/alec/Projects";
        CAPTURES = "/home/alec/Videos/Captures";
        CLIPS = "/home/alec/Videos/Clips";
      };
    };
  };
}
