{ inputs, pkgs, ... }: {
  imports = [
    ./hypr/hyprland.nix
    ./hypr/keybinds.nix
    ./hypr/hyprlock.nix

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

      extraPackages = with inputs.astal.packages.${pkgs.system}; [
        apps # App launcher
        battery # Laptop battery
        bluetooth # Bluez
        hyprland # For workspaces
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
    };
  };

  # Astal clipboard management
  services = {
    swww.enable = true; # Auto-start wallpaper manager on boot
    cliphist = {
      enable = true;
      extraOptions = [ "-preview-width" "200" "-max-items" "20" "-max-dedupe-search" "5" ];
    };
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
        XDG_PROJECTS_DIR = "/home/alec/Projects";
        XDG_CAPTURES_DIR = "/home/alec/Videos/Captures";
        XDG_CLIPS_DIR = "/home/alec/Videos/Clips";
      };
    };
  };
}
