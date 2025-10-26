{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  environment.systemPackages = with pkgs; [
    emulationstation
  ];

  services.sshd.enable = true;

  networking.hostName = "alecolaptop";
}