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
    kernelPackages = pkgs.linuxPackages_latest;
    initrd.systemd.enable = true; # Faster parallel boot
  };

  networking.wireless.iwd = {
    enable = lib.mkDefault true;
    settings = {
      IPv6.Enabled = true;
      Settings.AutoConnect = true;
    };
  };

  time.timeZone = "America/Los_Angeles"; # lang also set to en_US
  zramSwap.enable = true; # Compress ram for better performance

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    warn-dirty = false;
  };

  services.journald.extraConfig = "SystemMaxUse=20M";
  fileSystems."/".options = [ "noatime" "discard" ]; # SSD trim
  documentation.enable = false;
  environment.defaultPackages = lib.mkForce [];
  programs.command-not-found.enable = false; # Don't show recommendations when a package is missing

  system.stateVersion = lib.mkDefault "24.05";
}
