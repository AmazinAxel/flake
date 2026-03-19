{ pkgs, lib, ... }: {
  users.users.alec = { # Default user
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "dialout" ];
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 2; # Save space in /boot
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 0; # Hold down space on boot to access
    };
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    initrd.systemd.enable = lib.mkDefault true; # Faster parallel boot
  };

  networking = {
    dhcpcd.enable = false;
    wireless.iwd = {
      enable = lib.mkDefault true;
      settings = {
        IPv6.Enabled = true;
        Settings.AutoConnect = true;
        General.EnableNetworkConfiguration = true;
        Network.NameResolvingService = "systemd";
      };
    };
  };

  time.timeZone = "America/Los_Angeles"; # lang also set to en_US
  zramSwap.enable = lib.mkDefault true; # Compress ram for better performance

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    warn-dirty = false;
  };

  services = {
    journald.extraConfig = "SystemMaxUse=20M";
    resolved.enable = true; # DNS resolve
  };
  fileSystems."/".options = [ "noatime" "discard" ]; # SSD trim
  documentation.enable = false;
  environment.defaultPackages = lib.mkForce [];
  programs.command-not-found.enable = false; # Don't show recommendations when a package is missing

  system.stateVersion = lib.mkDefault "24.05";
}
