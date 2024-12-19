{ lib, config, pkgs, ... }: {
  imports = [
    ./sway/sway.nix
    ./sway/keybinds.nix
    
    ./fish.nix
    ./foot.nix
    ./gtk.nix
    ./mpd.nix
    ./starship.nix
    ./swappy.nix
    ./codium.nix
  ];

  programs.home-manager.enable = true;
  systemd.user.startServices = "sd-switch"; # Better system unit reloads
  home = {
    packages = lib.mkForce []; # Don't install packages to user PATH
    stateVersion = "23.05";

    # Symlink all wallpapers
    file."wallpapers" = {
      target = "./wallpapers";
      source = ./wallpapers;
    };

    # Glboal cursor system
    pointerCursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
    };
  };

  xdg = {
    configFile."homepage.html" = { source = ./homepage.html; };
    
    # Symlink all fonts
    dataFile."fonts" = {
      target = "./fonts";
      source = ./fonts;
    };

    userDirs = {
      enable = true; # Allows home-manager to manage & create user dirs
      createDirectories = true; # Auto-creates all directories
      extraConfig = {
        XDG_PROJECTS_DIR = "${config.home.homeDirectory}/Projects"; # Add Projects to xdg dirs
      };
    };
  };

  # for postmarketos to optimize local connection
  programs.ssh.enable = true;
  programs.ssh.extraConfig = ''
    Host 172.16.42.1 pmos
        HostName 172.16.42.1
        User user
        StrictHostKeyChecking no
        UserKnownHostsFile=/dev/null
        ConnectTimeout 5
        ServerAliveInterval 1
        ServerAliveCountMax 5
  '';
}
