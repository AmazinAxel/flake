{ lib, config, pkgs, ... }: {
  imports = [
    ./hypr/hyprland.nix
    ./hypr/keybinds.nix
    ./hypr/hyprlock.nix
    ./fastfetch.nix # TODO remove me after patching microfetch
    ./fish.nix
    ./fonts.nix
    ./foot.nix
    ./gtk.nix
    ./mpd.nix
    ./starship.nix
    ./swappy.nix
    ./vscode.nix

    ./sway/sway.nix
    ./sway/keybinds.nix
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
      #x11.enable = true; # TODO for sway maybe??
    };
  };

  xdg = {
    configFile."homepage.html" = { source = ./homepage.html; };

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
