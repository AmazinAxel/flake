{ inputs, pkgs, ... }: {
  imports = [
    ./sway/keybinds.nix
    ./sway/sway.nix

    ./vscode.nix
    ./fish.nix
    ./foot.nix
    ./gtk.nix
    ./librewolf.nix
    ./mpd.nix
    ./starship.nix
    ./swappy.nix

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
        auth # Lockscreen
        battery # Laptop battery
        bluetooth # Bluez
        mpris # Media controls
        notifd # Desktop notifications
        wireplumber # Used by pipewire
        pkgs.gtksourceview5 # Chat code syntax highlighting
        pkgs.glib-networking # AI chat
      ];
    };
  };
  systemd.user.startServices = "sd-switch"; # Better system unit reloads

  home = {
    stateVersion = "23.05";
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
