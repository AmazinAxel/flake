{ inputs, config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ]; # Hardware-specific settings

  networking.hostName = "alecslaptop"; # Hostname
  
  # Bootloader settings
  boot = {
    # Sea Islands Radeon support for Vulkan
    kernelParams = [ "radeon.cik_support=0" "amdgpu.cik_support=1" ];
    
    initrd = { # make sure to load AMD GPU support
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
    };
  };

  hardware = {
    #alsa.enablePersistence = true; # Fix sound not working on boot

    # OpenCL drivers for better hardware acceleration
    graphics.extraPackages = with pkgs; [ rocmPackages.clr.icd ];
    amdgpu.opencl.enable = true;
  };

  services = {
    upower.enable = true; # For getting battery level (used by the desktop)
    power-profiles-daemon.enable = false; # No power-profiles!
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
      };
    };
  };
}
