{ pkgs, lib, ... }: {
  users.users.alec = { # Default user
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "dialout" ];
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 2; # Saves space in boot partition
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = 0; # Hold down space on boot to access menu
    };
    tmp.cleanOnBoot = true;
    kernelPackages = pkgs.linuxPackages_latest;
  };

  networking.wireless.iwd = {
    enable = lib.mkDefault true;
    settings = {
      IPv6.Enabled = true;
      Settings.AutoConnect = true;
    };
  };

  # Binary cache
  nix.settings = {
    substituters = [ "https://nix-community.cachix.org" ];
    trusted-public-keys = [ "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=" ];
  };

  time.timeZone = "America/Los_Angeles"; # Locale setting also set to en_US by default

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    warn-dirty = false;
  };

  services.journald.extraConfig = "SystemMaxUse=20M";
  fileSystems."/".options = [ "noatime" "discard" ]; # Optimize SSD trim
  documentation.enable = false;

  environment.defaultPackages = lib.mkForce [];
  programs.command-not-found.enable = false; # Don't show recommendations when a package is missing

  system.stateVersion = lib.mkDefault "24.05";
}

