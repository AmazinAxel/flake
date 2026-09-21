{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "hid_generic" "i8042" "atkbd" ];
  boot.kernelModules = [ "kvm-amd" ];

  boot.initrd.luks.devices."cryptpersist" = {
    device = "/dev/disk/by-uuid/0bcca084-f072-4c32-9467-8f5a0efc6dc0";
    allowDiscards = true;
    bypassWorkqueues = true;
    crypttabExtraOpts = [ "password-echo=no" ];
  };

  fileSystems."/persist" = {
    device = "/dev/mapper/cryptpersist";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/FE43-9BB0";
    fsType = "vfat";
    options = [ "fmask=0137" "dmask=0027" ];
  };


  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };
}
