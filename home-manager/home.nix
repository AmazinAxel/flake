{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  
  imports = [
    #./hypr/hyprland.nix
    #./fish.nix
    ./fastfetch.nix
    #./gtk.nix
    #./homepage.nix
    #./mpd.nix
    #./starship.nix
    #./swappy.nix
    #./vscode.nix
  ];

  home = {
    username = "alec";
    homeDirectory = "/home/alec";
  };

  # Enable home-manager
  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
