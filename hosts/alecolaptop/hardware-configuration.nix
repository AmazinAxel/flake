{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/47638a3b-7a1b-4eeb-972e-a6c63769990c";
    fsType = "ext4";
    neededForBoot = true;
    options = [ "noatime" ];
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
