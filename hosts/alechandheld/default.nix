{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    (retroarch.withCores (cores: with cores; [
      
    ]))
    retroarch-joypad-autoconfig
  ];

  # For running retroarch
  services = {
    xserver.desktopManager.retroarch.enable = true;
    #cage = {
    #  enable = true;
    #  user = "alec";
    #  program = "${pkgs.retroarch}/bin/retroarch";
    #  extraArguments = [ "-s" ]; # Allow switching terminals
    #};
    sshd.enable = true;
  };
  #programs.gamemode.enable = true; # test

  networking = {
    wireless.iwd.enable = false;
    networkmanager.enable = true;
    hostName = "alechandheld";
    firewall.enable = false;
  };

  users.users.alec.extraGroups = [ "input" "gpio" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  # Extend card lifespan
  services.journald.extraConfig = "Storage=volatile";
}
