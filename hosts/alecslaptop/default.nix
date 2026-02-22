{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/printing.nix
    ../../modules/laptop.nix
  ];

  networking.hostName = "alecslaptop"; # Hostname
  home-manager.users.alec.imports = [ ./hm.nix ];

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    #kdePackages.kdenlive # Video editor
    blockbench # Minecraft 3D modeling app
    godot # Game engine
    gimp3 # Image editor
    teams-for-linux # Unoffical Teams client
    libreoffice # Preview Word documents and Excel sheets offline
    gnome-sound-recorder # Voice recording app
    gnome-disk-utility # Drive repartitioning utility
    flashprint # Flashforge 3D printer slicer
    thunderbird # Email client
    worldpainter # Minecraft world generator
    chromium # Honorlock supported browser
    kicad-small # PCB design

    bun # All-in-one JS toolkit
    jre # For Minecraft - uses the latest stable Java runtime version
    nodejs_22 # JS runtime
    steam-run # Used for running some games
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
