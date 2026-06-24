{ pkgs, lib, modulesPath, ... }: {
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
      wifi.powersave = false; # Stop network drops
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

  services = {
    openssh.enable = true;
    avahi.publish = { # needed for .local connection
      enable = true;
      addresses = true;
    };

  fileSystems."/" = { # Device SD card
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = lib.mkForce [ "noatime" ]; # force to not include discard flag from common.nix
  };

  services.journald.extraConfig = "Storage=volatile";
  nixpkgs.hostPlatform = "aarch64-linux";

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };
}
