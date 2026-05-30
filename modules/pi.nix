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
    networkmanager = {
      enable = true;
      wifi.powersave = false; # Stop network drops
    };
    wireless.iwd.enable = lib.mkForce false;
  };

  hardware = {
    enableRedistributableFirmware = lib.mkForce false; # not needed
    firmware = [ pkgs.raspberrypiWirelessFirmware ]; # needed for wifi to work
  };

  services = {
    openssh.enable = true; # SSH support

    # IP resolve shorthand for .local address
    avahi = {
      enable = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true; # For HTTP IP
      };
    };
  };

  fileSystems."/" = { # Device SD card
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = lib.mkForce [ "noatime" ]; # force to not include discard flag from common.nix
  };

  services.journald.extraConfig = "Storage=volatile";
  nixpkgs.hostPlatform = "aarch64-linux";
}
