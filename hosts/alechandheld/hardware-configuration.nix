{ lib, ... }: {

  boot.initrd.availableKernelModules = [ "usbhid" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  boot.loader = {
    grub.enable = false;
    generic-extlinux-compatible = {
      enable = true;
      #configurationLimit = 1;
    };
    systemd-boot.enable = lib.mkForce false;
  };

  hardware.deviceTree = {
    enable = false;
    dtbSource = ./dtb;
  };
  hardware.enableRedistributableFirmware = true;
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
