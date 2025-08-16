{ inputs, pkgs, ... }: {
  imports = [
    ./hypr/hyprland.nix
    ./hypr/keybinds.nix
    ./hypr/hyprlock.nix

    ./codium.nix
    ./fish.nix
    ./foot.nix
    ./gtk.nix
    ./librewolf.nix
    ./mpd.nix
    ./starship.nix

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
        battery # For laptop only - not used on desktop
        bluetooth # Bluez integration
        hyprland # Workspace integration
        mpris # Media controls
        notifd # Desktop notification integration
        wireplumber # Used by pipewire
      ];
    };
  };
  systemd.user.startServices = "sd-switch"; # Better system unit reloads

  home = {
    stateVersion = "23.05";
    username = "alec";
    homeDirectory = "/home/alec";

    # Glboal cursor system
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
      extraOptions = [ "-preview-width" "200" "-max-items" "20" "-max-dedupe-search" "20" ];
    };
  };

  xdg = {
    # Symlink all fonts
    dataFile."fonts" = {
      target = "./fonts";
      source = ./fonts;
    };

    userDirs = {
      enable = true; # Allows home-manager to manage & create user dirs
      createDirectories = true; # Auto-creates all directories
      extraConfig.XDG_PROJECTS_DIR = "/home/alec/Projects";
      extraConfig.XDG_CAPTURES_DIR = "/home/alec/Videos/Captures";
      extraConfig.XDG_CLIPS_DIR = "/home/alec/Videos/Clips";
      extraConfig.XDG_MODELS_DIR = "/home/alec/Models";
    };

    # Swappy config
    configFile."swappy/config".text = ''
      [Default]
      save_dir=$HOME/Pictures/Screenshots
      save_filename_format=%Y%m%d-%H%M%S-edited.png
      show_panel=false
      line_size=10
      text_size=20
      text_font=Sora
      paint_mode=brush
      early_exit=true
      fill_shape=false
    '';
  };
}
