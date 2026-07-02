{ pkgs, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/printing.nix
     ../../modules/impermanence.nix
    inputs.lanzaboote.nixosModules.lanzaboote
  ];

  environment.persistence."/persist" = {
    directories = [ "/var/lib/cups" "/var/lib/sbctl" ]; # printer config and secure boot keys
    users.alec.directories = [
      ".thunderbird"
      ".config/GIMP"
      ".config/libreoffice"
      ".config/kicad"
      ".local/share/kicad"
      ".platformio"
      ".config/kdeconnect"
      ".local/share/kdeconnect"
      ".local/share/com.hackclub.lookout"
      ".bun"
    ];
  };

  networking.hostName = "alecolaptop";
  home-manager.users.alec.imports = [ ./hm.nix ];

  swapDevices = [{ device = "/persist/swapfile"; size = 12288; }];
  zramSwap.memoryPercent = 100;

  environment.systemPackages = with pkgs; [
    gimp3
    libreoffice
    thunderbird
    (symlinkJoin {
      name = "kicad"; paths = [ kicad ]; nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/kicad --set GTK_THEME Adwaita";
    })

    inputs.lookout-nix.packages.${pkgs.stdenv.hostPlatform.system}.default

    openjdk25
    bun
    claude-code
    platformio-core

    sbctl # TODO remove
  ];
  programs.kdeconnect.enable = true;

  hardware = {
    keyboard.qmk.enable = true;
    graphics.extraPackages = with pkgs; [
      libva
      libva-utils
      libvdpau-va-gl
      libva-vdpau-driver
      rocmPackages.clr.icd
    ];
  };

  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelParams = [
      "mem_sleep_default=deep"
      "amdgpu.abmlevel=2" # adaptive backlight for display power saving
      "amd_pstate=active" # enable SPPC in the BIOS first!!!
    ];
    kernel.sysctl = {
      "vm.dirty_writeback_centisecs" = 6000; # batch disk writes
      "vm.swappiness" = 180; # kernel max
      "vm.page-cluster" = 0;
      "vm.watermark_boost_factor" = 0;
      "vm.watermark_scale_factor" = 125;
    };
  };

  services = {
    upower.enable = true; # For displaying battery level on astal shell
    tlp = { # Better battery life
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "balance_power";
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

        # Wake on LAN
        WOL_DISABLE = "Y";
      };
    };

    pipewire.extraConfig.pipewire = {
      "99-combine-bt"."context.modules" = [{
        name = "libpipewire-module-combine-stream";
        args = {
          "combine.mode" = "sink";
          "node.name" = "combined-bt-sink";
          "node.description" = "Bluetooth combined output";
          "node.latency" = "2048/48000"; # 42ms buffer to absorb jitter
          "combine.latency-compensate" = false; # less jitter
          "combine.props" = {
            "audio.position" = [ "FL" "FR" ];
            "audio.rate" = 48000;
          };
          "combine.on-demand-streams" = true;
          "combine.start-streams-on-load" = false;
          "stream.props"."audio.rate" = 48000;
          "stream.rules" = [{
            matches = [
              { "node.name" = "bluez_output.94_4B_F8_8F_85_28.1"; }
              { "node.name" = "bluez_output.D6_1F_21_FC_F9_C7.1"; }
            ];
            actions.create-stream = { };
          }];
        };
        flags = [ "ifexists" "nofail" ];
      }];
    };

    pipewire.wireplumber.extraConfig = {
      # might not be necessary
      "10-bluetooth"."monitor.bluez.properties" = {
        "bluez5.codecs" = [ "aac" "sbc_xq" "sbc" ];
        "bluez5.enable-msbc" = false;
      };
    };

    udev = {
      packages = [ pkgs.platformio-core.udev ];
      # Pi Pico
      extraRules = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", MODE="0666"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", MODE="0666"
      '';
    };
  };
}
