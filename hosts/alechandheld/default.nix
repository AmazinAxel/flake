{ pkgs, ... }: {
  imports = [
    ./hardware-config.nix
    ../common.nix
  ];

  environment.systemPackages = with pkgs; [
    git
    #emulationstation
  ];

  services.sshd.enable = true;

  networking.hostName = "alecolaptop";
}
