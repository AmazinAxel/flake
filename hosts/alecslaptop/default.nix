{ inputs, config, lib, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix # Hardware-specific settings
  ];

  # Bootloader settings
  boot = {
    # Sea Islands Radeon support for Vulkan
    kernelParams = [ "radeon.cik_support=0" "amdgpu.cik_support=1" ];
    
    initrd = { # make sure to load AMD GPU support
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
    };
  };

  # DaVinci Resolve OpenCL driver requirement
  hardware.graphics.extraPackages = with pkgs; [ rocmPackages.clr.icd amdvlk ];

  services.power-profiles-daemon.enable = false; # No power-profiles!
  services.tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      };
  };
  
  networking.hostName = "alecslaptop"; # Hostname
}
