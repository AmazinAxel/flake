{ pkgs, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/laptop.nix
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
    zettlr
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
    consoleLogLevel = 3; # Suppress ACPI BIOS firmware bug spam

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

  swapDevices = [{ device = "/persist/swapfile"; size = 18 * 1024; }];

  environment.persistence."/persist" = {
    directories = [ "/var/lib/flatpak" ]; # Sober
    users.alec.directories = [
      ".local/share/Steam" ".steam" # Steam
      ".thunderbird" # Thunderbird
      ".config/kdeconnect" # kdeconnect
    ];
  };

  services.flatpak.enable = true; # For running Sober
}
