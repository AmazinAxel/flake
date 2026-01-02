{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "alecolaptop";
  home-manager.users.alec.imports = [ ./hm.nix ];

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    gimp3 # Image editor
    teams-for-linux # Unoffical Teams client
    libreoffice # Preview Word documents & Excel sheets offline
    thunderbird # Email client

    arduino-ide # Embedded microcontroller programming
    python3 # Required for Arduino IDE
    jre # For Minecraft - uses the latest stable Java runtime version
    bun # All-in-one JS toolkit
    qpwgraph # Audio output visualizer
  ];

  # Bootloader settings (w/ AMD GPU support)
  boot.initrd = {
    kernelModules = [ "amdgpu" ];
    includeDefaultModules = false;
  };

  services = {
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
    udev.packages = [ # For micro:bit development
      (pkgs.writeTextFile {
        name = "microbit_udev";
        text = ''
          SUBSYSTEM=="usb", ATTR{idVendor}=="0d28", MODE="0664", TAG+="uaccess"
        '';
        destination = "/etc/udev/rules.d/50-microbit.rules";
      })
    ];
  };
}
