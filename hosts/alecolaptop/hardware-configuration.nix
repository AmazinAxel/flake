{ lib, ... }: {
  boot = {
    initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "i8042" "atkbd" "usbhid" "hid_generic" ]; # MUST include these modules for keyboard to work for LUKS
    kernelModules = [ "kvm-amd" ];
    initrd.luks.devices."cryptpersist" = {
      device = "/dev/disk/by-uuid/fd5a2a94-4459-4102-a07a-2ea504232b9d";
      allowDiscards = true;
      bypassWorkqueues = true;
    };

    loader = { # Secure boot
      systemd-boot.enable = lib.mkForce false; # lanzaboote replaces systemd-boot
      efi.canTouchEfiVariables = true;
    };
    lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl"; # reuse the already-enrolled sbctl keys
      configurationLimit = 2;
    };
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/cryptpersist";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" "x-initrd.mount" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/6A47-9F78";
    fsType = "vfat";
    options = [ "fmask=0137" "dmask=0027" ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };
}
