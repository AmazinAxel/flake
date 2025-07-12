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
    bun # All-in-one JS toolkit
  ];

  # Bootloader settings (w/ AMD GPU support)
  boot.initrd = {
    kernelModules = [ "amdgpu" ];
    includeDefaultModules = false;
  };

  services = {
    upower.enable = true; # For displaying battery level on astal shell
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
