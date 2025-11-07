{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./kernelconfig.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    (retroarch.withCores (cores: with cores; [
      
    ]))
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
    libinput.enable = true;
  };

  networking = {
    wireless.iwd.enable = false;
    networkmanager.enable = true;
    hostName = "alechandheld";
    firewall.enable = false;
  };

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  # Extend card lifespan
  services.journald.extraConfig = "Storage=volatile";
}
