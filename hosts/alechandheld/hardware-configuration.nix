{ pkgs, lib, ... }:
let
  anbernicPanelFirmware = pkgs.runCommand "anbernic-panel-firmware" {} ''
    mkdir -p $out/lib/firmware/panels
    cp ${./panels}/*.panel $out/lib/firmware/panels/
  '';
in {
  # Impermanent root: / is tmpfs (from modules/tmpfs-root.nix; sized down for
  # this 1 GB device), the primary SD's ext4 partition is mounted at /persist.
  # commit=60: batch ext4 journal flushes (default 5s) — fewer SD writes, longer
  # card idle periods.  Worst case on a crash is losing the last minute of writes.
  fileSystems."/".options = lib.mkForce [ "size=192M" "mode=755" ];
  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888";
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

  # external microSD card — ALL game data lives here (ports, PortMaster state,
  # RetroArch saves, game homes).  No continuous "discard" — synchronous erase
  # commands hurt SD latency/wear; services.fstrim does periodic TRIM instead.
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
