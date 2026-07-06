{ pkgs, lib, ... }:
let
  anbernicPanelFirmware = pkgs.runCommand "anbernic-panel-firmware" {} ''
    mkdir -p $out/lib/firmware/panels
    cp ${./panels}/*.panel $out/lib/firmware/panels/
  '';
in {
  # commit=60: batch ext4 journal flushes (default 5s) — fewer SD writes, longer
  # card idle periods.  Worst case on a crash is losing the last minute of writes.
  fileSystems."/" = {
    device = lib.mkForce "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
    fsType = "ext4";
    options = [ "commit=60" ]; # noatime comes from common.nix
  };

  # external microSD card for more games.  No continuous "discard" — synchronous
  # erase commands hurt SD latency/wear; services.fstrim does periodic TRIM instead.
  fileSystems."/mnt/AlecContent" = {
    device = "/dev/disk/by-label/AlecContent";
    fsType = "ext4";
    options = [ "nofail" "x-systemd.automount" "x-systemd.device-timeout=10s" "noatime" "commit=60" ];
  };

  boot = {
    initrd = {
      availableKernelModules = [ "usbhid" "hid" "evdev" "uinput" ]; # todo
      allowMissingModules = true;
      systemd.enable = false;
    };
    loader = { # todo merge module with pi.nix
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

    uinput.enable = true; # gptokeyb (PortMaster) creates a virtual keyboard via /dev/uinput
  };
  nixpkgs.hostPlatform = "aarch64-linux";
  system.stateVersion = "25.05";
}
