{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/74c7aefb-4781-42a7-ac7f-bd639ba124a6";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/8B49-7B9B";
    fsType = "vfat";
    options = [ "fmask=0137" "dmask=0027" ];
  };

  nixpkgs.hostPlatform = "x86_64-linux";
  hardware = {
    enableRedistributableFirmware = true;
    cpu.amd.updateMicrocode = true;
  };
}
