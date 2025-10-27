{ pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    pegasus-frontend
    retroarch
  ];

  services.sshd.enable = true;

  #hardware.devicetree = {
  #  enable = false;
  #}

  # Additional microSD card
  #fileSystems."/othercard/" = {
  #  device = "/dev/disk/by-uuid/";
  #  fsType = "exfat";
  #  options = [ "nofail" ];
  #};

  boot.kernelPatches = builtins.map (p: {
    name = builtins.elemAt (pkgs.lib.splitString "." (builtins.baseNameOf p.url)) 0;
    patch = pkgs.fetchpatch p;
  }) (import ./kernel-patches.nix);

  networking = {
    wireless.iwd.enable = lib.mkForce false;
    networkmanager.enable = true;
    hostName = "alechandheld";
    firewall.enable = false;
  };

  services.journald.extraConfig = "Storage=volatile"; # Better microSD lifespan
}
