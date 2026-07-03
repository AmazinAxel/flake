{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/REPLACE-ME"; #!!!!!!!!!!!!!!!!!!!!
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
