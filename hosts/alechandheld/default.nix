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

  # For running retroarch
  services = {
    cage = {
      enable = true;
      program = "${pkgs.retroarch}/bin/retroarch";
    };
    sshd.enable = true;
  };
  programs.gamemode.enable = true; # For Retroarch

  networking = {
    wireless.iwd.enable = false;
    networkmanager.enable = true;
    hostName = "alechandheld";
    #firewall.enable = false;
  };

  # Extend microSD lifespan
  services.journald.extraConfig = ''
    Storage=volatile
    RuntimeMaxUse=32M
  '';
}
