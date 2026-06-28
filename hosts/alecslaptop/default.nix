{ pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/printing.nix
  ];

  networking.hostName = "alecslaptop"; # Hostname
  home-manager.users.alec.imports = [ ./hm.nix ];

  environment.systemPackages = with pkgs; [
    flowblade
    godot
    gimp3
    libreoffice
    gnome-sound-recorder
    gnome-disk-utility
    flashprint
    thunderbird
    (symlinkJoin {
      name = "kicad-small"; paths = [ kicad-small ]; nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/kicad --set GTK_THEME Adwaita";
    })

    bun
    openjdk25
    nodejs_22
    steam-run
  ];
  programs = {
    steam.enable = true; # Gaming
    kdeconnect.enable = true; # Device integration
  };
  environment.sessionVariables.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.systemd ]; # fix MC warning

  # Bootloader settings
  boot = {
    # Sea Islands Radeon support for Vulkan
    kernelParams = [
      "amd_pstate=active" "mem_sleep_default=deep"
    ];
    consoleLogLevel = 3; # Suppress ACPI BIOS firmware bug spam (KERN_ERR) from console

    # Batch dirty page flushes
    kernel.sysctl."vm.dirty_writeback_centisecs" = 6000;

    initrd = { # AMD GPU support
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # Arch64 cross compilation support
  };

  hardware = { # OpenCL drivers for better hardware acceleration
    graphics.extraPackages = [ pkgs.rocmPackages.clr.icd ];
    amdgpu.opencl.enable = true;
  };

  swapDevices = [{ device = "/swapfile"; size = 4096; }];

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

        # no CPU boost on battery
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 0;

        # firmware platform profile
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        # pci active state power management
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";

        # pci device sleep
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";

        # USB autosuspend
        USB_AUTOSUSPEND = 1;
        USB_EXCLUDE_AUDIO = 1;
        USB_EXCLUDE_PRINTER = 1;

        # SOUND_POWER_SAVE_ON_AC = 0;
        # SOUND_POWER_SAVE_ON_BAT = 0;
        # SOUND_POWER_SAVE_CONTROLLER = "N";

        # Wake on LAN
        WOL_DISABLE = "Y";
      };
    };
  };
}
