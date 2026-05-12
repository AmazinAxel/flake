{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" ];
  boot.kernelModules = [ "kvm-amd" ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/ca0e7cbb-b202-4129-a821-ff5dcdbb8488";
    fsType = "ext4";
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
