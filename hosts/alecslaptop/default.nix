{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/printing.nix
  ];

  networking.hostName = "alecslaptop"; # Hostname
  home-manager.users.alec.imports = [ ./hm.nix ];

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    kdePackages.kdenlive # Video editor
    blockbench-electron # Minecraft 3D modeling app
    godot # Game engine
    slack # Hack club collaboration
    gimp3 # Image editor
    teams-for-linux # Unoffical Teams client
    libreoffice # Preview Word documents and Excel sheets offline
    gnome-sound-recorder # Voice recording app
    gnome-disk-utility # Drive repartitioning utility
    flashprint # Flashforge 3D printer
    thunderbird # Email client
    worldpainter # Minecraft world generator
    #jetbrains.idea-community # Jetbrains IDEA
    maven # Java build tool
    zulu24 # JDK
    gpu-screen-recorder # Screen record & clipping tool - expose binary for use within Astal

    bun # All-in-one JS toolkit
    jre # For Minecraft - uses the latest stable Java runtime version
    jdk23 # Java JDK version 23 for compling & running jars
    nodejs_22 # JS runtime
    steam-run # Used for running some games
  ];
  programs = {
    kdeconnect.enable = true; # Device integration
    gpu-screen-recorder.enable = true; # Clipping software services
    steam.enable = true; # Gaming
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

  # This host is a build machine for alechandheld and alechomelab
  users.users.builder = {
    isSystemUser = true;
    createHome = false;
    uid = 500;
    group = "builder";
    useDefaultShell = true;
    openssh.authorizedKeys.keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK4iipZezwrhmeGj4ScaYrW97iukXGz+cW44FlEaT3bd alec@alechandheld"];
  };
  users.groups.builder.gid = 500;
  nix.settings.trusted-users = [ "builder" ];

  services = {
    flatpak.enable = true; # For running Sober
    upower.enable = true; # For displaying battery level on astal shell
    sshd.enable = true;

    # Game streaming to console
    sunshine = {
      enable = true;
      autoStart = false;
      openFirewall = true;
      capSysAdmin = true;
    };

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
