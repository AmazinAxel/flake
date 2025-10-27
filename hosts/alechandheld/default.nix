{ pkgs, lib, ... }: {
  imports = [
    ./hardware-config.nix
    ../common.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    #emulationstation
  ];

  services.sshd.enable = true;

  networking = {
    wireless.iwd.enable = lib.mkForce false;
    networkmanager.enable = true;
    hostName = "alechandheld";
    firewall.enable = false;
  };
}
