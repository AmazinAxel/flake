{ pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/laptop.nix
    ../../modules/printing.nix
    ../../modules/bluetooth-audio.nix
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
    kdePackages.kdenlive
    thunderbird
    aseprite
    zettlr
    (symlinkJoin {
      name = "kicad"; paths = [ kicad ]; nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/kicad --set GTK_THEME Adwaita";
    })

    bun
    openjdk25
    jdk25
    nodejs_22
    steam-run
  ];
  programs.steam.enable = true; # Gaming
  environment.sessionVariables.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.systemd ]; # fix MC warning

  # Bootloader settings
  boot = {
    kernelParams = [ "amd_pstate=active" ];
    consoleLogLevel = 3; # Suppress ACPI BIOS firmware bug spam

    initrd = { # AMD GPU support
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
      compressor = "zstd";
      compressorArgs = [ "-19" "-T0" ];
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # Arch64 cross compilation support
  };

  services.fstrim.enable = true;

  hardware = { # OpenCL drivers for better hardware acceleration
    graphics.extraPackages = [ pkgs.rocmPackages.clr.icd ];
    amdgpu.opencl.enable = true;
  };

  swapDevices = [{ device = "/persist/swapfile"; size = 18 * 1024; }];

  environment.persistence."/persist" = {
    directories = [ "/var/lib/flatpak" ]; # Sober
    users.alec.directories = [
      ".local/share/Steam" ".steam" # Steam
      ".thunderbird" # Thunderbird
      ".config/kdeconnect" # kdeconnect
      ".config/playit_gg" # playit agent login

      # apps
      ".config/GIMP"
      ".config/libreoffice"
      ".config/kicad"
      ".local/share/kicad"
      ".FlashPrint5" # FlashPrint slicer
      ".config/godot"
      ".local/share/godot"
      ".config/Zettlr"
      ".config/aseprite"
      ".config/flowblade"
      ".local/share/kdenlive"
    ];
  };

  services = {
    flatpak.enable = true; # For running Sober
    scx = { # scheduler for less active cores
      enable = true;
      package = pkgs.scx.rustscheds;
      scheduler = "scx_lavd";
    };

    udev = {
      packages = [ pkgs.platformio-core.udev ];
      # Pi Pico
      extraRules = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", MODE="0666"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", MODE="0666"

        # WCH CH32X035
        SUBSYSTEM=="usb", ATTR{idVendor}=="4348", ATTR{idProduct}=="55e0", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="55e0", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="8010", MODE="0666"
        SUBSYSTEM=="usb", ATTR{idVendor}=="1a86", ATTR{idProduct}=="8012", MODE="0666"
      '';
    };
  };
}
