{ lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];
  networking.hostName = "vm"; # Hostname

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # When booting UEFI we can use systemd boot but qemu only supports BIOS by default
  # so we enable grub & disable systemd boot
  boot.loader = {
    systemd-boot.enable = false;
    grub = {
      enable = false;
      device = "nodev";
    };
  };

  fileSystems."/" = { 
    device = "/dev/disk/by-uuid/63547912-74ae-442a-bda4-9c07eb438aa1";
    fsType = "ext4";
  };

  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
