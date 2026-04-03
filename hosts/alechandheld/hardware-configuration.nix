{ pkgs, lib, ... }:
let
  anbernicPanelFirmware = pkgs.runCommand "anbernic-panel-firmware" {} ''
    mkdir -p $out/lib/firmware/panels
    cp ${./panels}/*.panel $out/lib/firmware/panels/
  '';
in {
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
  };

  # external microSD card for more games
  fileSystems."/mnt/AlecContent" = {
    device = "/dev/disk/by-label/AlecContent";
    fsType = "ext4";
    # x-systemd.automount: defers mount until first access and retries automatically on failure.
    # x-systemd.device-timeout: H700 MMC init can take longer than the old 5s on cold boot.
    options = [ "nofail" "x-systemd.automount" "x-systemd.device-timeout=10s" "noatime" "discard" ];
  };

  boot = {
    initrd = {
      availableKernelModules = [ "usbhid" "hid" "evdev" "uinput" ];
      allowMissingModules = true;
      systemd.enable = false;
    };
    loader = {
      systemd-boot.enable = false;
      grub.enable = false;
      generic-extlinux-compatible = {
        enable = true;
        configurationLimit = 2;
      };
    };
    kernelModules = [ "rocknix-singleadc-joypad" ]; # out of tree
    kernelParams = [ "console=tty0" ]; # show terminal early on boot
  };

  hardware = {
    deviceTree.name = "allwinner/sun50i-h700-anbernic-rg35xx-h.dtb";
    enableRedistributableFirmware = true;
    firmware = [ pkgs.linux-firmware anbernicPanelFirmware ];

    # For gamepad/joystick?
    i2c.enable = true;
    uinput.enable = true;
  };
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
