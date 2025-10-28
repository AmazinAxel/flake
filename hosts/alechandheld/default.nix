{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    retroarch-full
    retroarch-joypad-autoconfig
  ];

  # Retroarch requirements
  programs.gamemode.enable = true;
  hardware.opengl.enable = true;

  services.sshd.enable = true;

  networking = {
    wireless.iwd.enable = false;
    networkmanager = {
      enable = true;
      wifi.scanRandMacAddress = false; # Fix disconnects
    };
    hostName = "alechandheld";
    firewall.enable = false;
  };

  # Extend microSD lifespan
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=32M
  '';
}
