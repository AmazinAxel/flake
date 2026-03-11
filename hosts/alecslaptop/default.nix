{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/printing.nix
  ];

  networking.hostName = "alecslaptop"; # Hostname
  home-manager.users.alec.imports = [ ./hm.nix ];

  environment.systemPackages = with pkgs; [
    kdePackages.kdenlive
    blockbench
    godot
    gimp3
    teams-for-linux
    libreoffice
    gnome-sound-recorder
    gnome-disk-utility
    flashprint
    thunderbird
    worldpainter
    kicad

    bun
    jre
    nodejs_22
    steam-run
  ];
  programs = {
    steam.enable = true; # Gaming
    kdeconnect.enable = true; # Device integration
  };

  # Bootloader settings
  boot = {
    # Sea Islands Radeon support for Vulkan
    kernelParams = [ "radeon.cik_support=0" "amdgpu.cik_support=1" ];

    initrd = { # AMD GPU support
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # Arch64 cross compilation support
  };

  hardware = { # OpenCL drivers for better hardware acceleration
    graphics.extraPackages = [ pkgs.rocmPackages.clr.icd ];
    amdgpu.opencl.enable = true;
  };

  services = {
    flatpak.enable = true; # For running Sober
    upower.enable = true; # For displaying battery level on astal shell

    tlp = { # Better battery life
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
