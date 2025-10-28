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
      user = "alec";
      program = "${pkgs.retroarch}/bin/retroarch";
      extraArguments = [ "-s" ]; # Allow switching terminals
    };
    sshd.enable = true; # Just in case
  };
  programs.gamemode.enable = true;

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
