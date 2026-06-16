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
      settings.connection."wifi.scan-rand-mac-address" = "no"; # helps with drops
    };
    wireless.iwd.enable = lib.mkForce false;
  };

  # help with wifi drops
  boot.extraModprobeConfig = "options brcmfmac roamoff=1 feature_disable=0x82000";

  # systemd.services.wifi-watchdog = {
  #   description = "Restart NetworkManager if wifi loses connectivity";
  #   after = [ "NetworkManager.service" ];
  #   serviceConfig.Type = "oneshot";
  #   script = ''
  #     if ! ${pkgs.iputils}/bin/ping -c 2 -W 5 -I wlan0 1.1.1.1 >/dev/null 2>&1; then
  #       ${pkgs.systemd}/bin/systemctl restart NetworkManager.service
  #     fi
  #   '';
  # };
  # systemd.timers.wifi-watchdog = {
  #   wantedBy = [ "timers.target" ];
  #   timerConfig = {
  #     OnBootSec = "2min";
  #     OnUnitActiveSec = "2min";
  #   };
  # };

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

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
  };
}
