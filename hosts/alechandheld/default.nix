{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./customKernel.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    (retroarch.withCores (cores: with cores; [
      
    ]))
    # TODO remove
    evtest
  ];

  zramSwap.enable = false; # Breaks boot if enabled
  #nix.settings.use-sandbox = false; # temp build fix

  # For running retroarch
  services = {
    #cage = {
    #  enable = true;
    #  user = "alec";
    #  program = "${pkgs.retroarch}/bin/retroarch";
    #  extraArguments = [ "-s" ]; # Allow TTY switching
    #};
    sshd.enable = true;
    libinput.enable = true;
    earlyoom = {
      enable = true;
      freeMemThreshold = 5; # 5%
    };
  };

  networking = {
    wireless.iwd.enable = false;
    networkmanager.enable = true;
    hostName = "alechandheld";
  };

  hardware.graphics.enable = true; # Mesa/OpenGL for Panfrost GPU (Mali-G31)

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  # Extend card lifespan
  services.journald.extraConfig = "Storage=volatile";
}
