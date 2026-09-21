{
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "usbhid" "hid_generic" "i8042" "atkbd" ];
  boot.kernelModules = [ "kvm-amd" ];

  # After LUKS: swap device to /dev/mapper/cryptpersist and add the luks.devices block below.
  # boot.initrd.luks.devices."cryptpersist" = {
  #   device = "/dev/disk/by-uuid/<crypto_LUKS UUID from cryptsetup reencrypt>";
  #   allowDiscards = true;
  #   bypassWorkqueues = true;
  #   crypttabExtraOpts = [ "password-echo=no" ];
  # };

  fileSystems."/persist" = {
    device = "/dev/disk/by-uuid/ca0e7cbb-b202-4129-a821-ff5dcdbb8488";
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
