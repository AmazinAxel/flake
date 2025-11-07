{
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  # Additional microSD card
  fileSystems."/mnt/content" = {
    device = "/dev/disk/by-uuid/89bd4766-cb7b-46ad-aef9-13c21769d7c9";
    fsType = "ext4";
    options = [ "nofail" "noatime" "discard" ];
  };

  boot = {
    initrd.availableKernelModules = [ "usbhid" "hid" "hid_generic" "usbhid" "joydev" "evdev" ];
    loader = {
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 2;
      };
      systemd-boot.enable = false;
    };
    kernelModules = [ "hid" "hid_generic" "usbhid" "joydev" "evdev" ];
  };

  hardware = {
    deviceTree.name = "allwinner/sun50i-h700-anbernic-rg35xx-h.dtb";
    enableRedistributableFirmware = true;
    
    # For gamepad/joystick?
    i2c.enable = true;
    uinput.enable = true;
  };
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
