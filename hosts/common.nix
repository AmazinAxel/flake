{ inputs, config, pkgs, modulesPath, ... }: {

  imports = [
    #"${modulesPath}/profiles/perlless.nix"
    /*/etc/nixos/hardware-configuration.nix
    ./system.nix
    ./audio.nix
    ./locale.nix
    ./nautilus.nix
    ./laptop.nix
    ./hyprland.nix
    ./gnome.nix*/
  ];

  home-manager = {
    backupFileExtension = "hm-backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
    users.alec = {
      home.username = "alec";
      home.homeDirectory = "/home/alec";
      imports = [ ../home-manager/home.nix ];
    };
  };

  # Better shell
  programs.zsh = {
    enable = true;
  };

  # Optimized bootloader settings
  boot = {
    loader = {
      systemd-boot.enable = true; # Systemd boot
      efi.canTouchEfiVariables = true;
      timeout = 0; # Hold down space on boot to access menu
      systemd-boot.configurationLimit = 2; # Save space in the /boot partition
    };
    tmp.cleanOnBoot = true;
    kernelPackages = pkgs.linuxPackages_latest; # Use the latest Linux kernel version
    enableContainers = false;
  };

  # Networking configuration using iwd
  networking = {
    networkmanager.wifi.backend = "iwd";
    useNetworkd = true;
    wireless.iwd = {
      enable = true;
      settings = {
        Settings = {
          AutoConnect = true;
          EnableNetworkConfiguration = true;
        };
        General = {
          EnableNetworkConfiguration = true;
        };
      };
    };
  };

  time.timeZone = "America/Los_Angeles"; # US West Coast timezone

  # Internationalization settings
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true; # Allow installing of non open-source applications
  nix.settings.experimental-features = "nix-command flakes";
  programs.dconf.enable = true;

  services.logrotate.enable = false; # Don't need this
  
  users.users.alec = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "networkmanager" ]; 
  };

  # Random settings to optimize the system
  services.journald.extraConfig = "SystemMaxUse=1G";
  nix.settings.auto-optimise-store = true;
  fileSystems."/".options = [ "noatime" "nodiratime" "discard" ]; # Optimize SSD trim

  # Disable ALL documentation
  documentation = {
    enable = false;
    doc.enable = false;
    info.enable = false;
    man.enable = false;
    nixos.enable = false;
    man.man-db.enable = false;
  };

  # Remove even more useless stuff 
  environment.defaultPackages = []; # Remove all default packages
  programs.less.lessopen = null;
  programs.command-not-found.enable = false; # Don't show recommendations when a package is missing

  # Even if the latest NixOS version is newer than this, we don't need to update.
  # To maintain compatibility, this version should stay the same.
  system.stateVersion = "24.05"; # Shouldn't change this value
}

