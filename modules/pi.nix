{ pkgs, lib, ... }: {
  imports = [ ./tmpfs-root.nix ];

  boot = {
    loader = { # Raspi boot
      systemd-boot.enable = false;
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 2;
      };
    };

    initrd.systemd.enable = false; # necessary for boot, fail to start closure otherwise
    supportedFilesystems = lib.mkForce [ "ext4" ]; # dont build zfs!!
    initrd.supportedFilesystems = lib.mkForce [ "ext4" ];
  };

  networking = {
    useNetworkd = false; # use nm
    firewall.allowedTCPPorts = [ 9000 8000 ];
    networkmanager = {
      enable = true;
      wifi.powersave = false; # Stops network drops
      settings.connection."wifi.scan-rand-mac-address" = "no"; # helps with drops
    };
    wireless.iwd.enable = false; # use nm
  };
  systemd.network.enable = false; # no networkd

  # help with wifi drops
  boot.extraModprobeConfig = "options brcmfmac roamoff=1 feature_disable=0x82000";

  hardware = {
    enableRedistributableFirmware = lib.mkForce false; # not needed
    firmware = [ pkgs.raspberrypiWirelessFirmware ]; # needed for wifi to work
  };

  # avahi .local publishing comes from common.nix
  services.openssh.enable = true;

  fileSystems."/persist" = {
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" "commit=60" ];
  };
  fileSystems."/boot" = { # extlinux kernels
    device = "/persist/boot";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections" # networkmanager wifi
  ];

  services.journald.extraConfig = "Storage=volatile";
  nixpkgs.hostPlatform = "aarch64-linux";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };
  boot.kernel.sysctl = {
    # "vm.swappiness" = 180;
    "vm.page-cluster" = 0;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.dirty_writeback_centisecs" = 6000;
  };

  environment.systemPackages = [
    (pkgs.writeScriptBin "persist-prune" (builtins.readFile ../scripts/persist-prune.fish))
  ];
}
