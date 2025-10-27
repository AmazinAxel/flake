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

  # This device has low RAM so we can improve build times by using alecslaptop as a remote builder
  nix = {
    buildMachines = [{
      hostName = "10.0.0.63";
      system = "x86_64-linux";
      #systems = ["x86_64-linux", "aarch64-linux"];
      protocol = "ssh-ng";
      maxJobs = 1;
      speedFactor = 16;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
      mandatoryFeatures = [ ];
    }];
	  distributedBuilds = true;
	  extraOptions = ''
      builders-use-substitutes = true
    '';
  };

  boot = {
    kernelPackages = pkgs.linuxPackages_6_17;
    kernelPatches = builtins.map (p: {
      name = builtins.elemAt (pkgs.lib.splitString "." (builtins.baseNameOf p.url)) 0;
      patch = pkgs.fetchpatch p;
    }) (import ./kernel-patches.nix);
  };

  networking = {
    wireless.iwd.enable = lib.mkForce false;
    networkmanager = {
      enable = true;
      wifi.scanRandMacAddress = false; # Fix disconnects?
    };
    hostName = "alechandheld";
    firewall.enable = false;
  };

  services.journald.extraConfig = "Storage=volatile"; # Better microSD lifespan
}
