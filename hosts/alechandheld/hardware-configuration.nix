{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  # Additional microSD card
  #fileSystems."/content/" = {
  #  device = "/dev/disk/by-uuid/";
  #  fsType = "ext4";
  #  options = [ "nofail" ];
  #};

  boot = {
    initrd.availableKernelModules = [ "usbhid" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 1;
      };
      systemd-boot.enable = false;
    };
  };

  hardware.deviceTree.name = "allwinner/sun50i-h700-anbernic-rg35xx-h.dtb";
  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
