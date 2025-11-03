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
    cage = {
      enable = true;
      user = "alec";
      program = "${pkgs.retroarch}/bin/retroarch";
      extraArguments = [ "-s" ]; # Allow TTY switching
    };
    sshd.enable = true;
  };

  networking = {
    wireless.iwd.enable = false;
    networkmanager.enable = true;
    hostName = "alechandheld";
    firewall.enable = false;
  };

  users.users.alec.extraGroups = [ "input" "gpio" ];
  nix.settings = {
    trusted-users = [ "alec" ]; # Remote deployment
    
    # Prevent builds overwhelming device resources
    max-jobs = 1;
    cores = 1;
  };

  # Extend card lifespan
  services.journald.extraConfig = "Storage=volatile";
}
