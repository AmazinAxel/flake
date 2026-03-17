{ pkgs, ... }: {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  # external microSD card for more games
  fileSystems."/mnt/content" = {
    device = "/dev/disk/by-uuid/89bd4766-cb7b-46ad-aef9-13c21769d7c9";
    fsType = "ext4";
    options = [ "nofail" "noatime" "discard" ];
  };

  boot = {
    initrd.availableKernelModules = [ "usbhid" "hid" "evdev" "uinput" ];
    #initrd.kernelModules = [ "panel-simple" "panel-mipi" "pwm-bl" "gpio-backlight" ];
    loader = {
      systemd-boot.enable = false;
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 2;
      };
    };
    # rtw88 modules are now built-in; rocknix-singleadc-joypad is the out-of-tree gamepad driver
    kernelModules = [ "hid" "hid_generic" "usbhid" "evdev" "uinput" "rocknix-singleadc-joypad" "panel-simple" "panel-mipi" "pwm-bl" "gpio-backlight" ];
  };

  hardware = {
    deviceTree.name = "allwinner/sun50i-h700-anbernic-rg35xx-h.dtb";
    enableRedistributableFirmware = true;
    firmware = [ pkgs.linux-firmware ];

    # For gamepad/joystick?
    i2c.enable = true;
    uinput.enable = true;
  };
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
