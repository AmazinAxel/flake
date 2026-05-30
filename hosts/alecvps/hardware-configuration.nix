
{
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "rpool/data/subvol-112-disk-0";
    fsType = "zfs";
  };

  swapDevices = [ ];

  networking.hostId = "261fd1d6"; # random

  nixpkgs.hostPlatform = "x86_64-linux";
}