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
      enable = true;
      device = "/dev/vda";
    };
  };

  fileSystems."/" = { 
    device = "/dev/disk/by-uuid/d7dff580-7883-4856-b837-2b4f9b821b9a";
    fsType = "ext4";
  };
  swapDevices = [ ];
  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
