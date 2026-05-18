{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "alecolaptop";
  home-manager.users.alec.imports = [ ./hm.nix ];

  swapDevices = [{ device = "/swapfile"; size = 2048; }];

  environment.systemPackages = with pkgs; [
    gimp3
    teams-for-linux
    libreoffice
    thunderbird
    kicad-small

    arduino-ide
    python3
    openjdk25
    bun
    claude-code
    platformio
  ];

  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
    kernelParams = [ "amd_pstate=active" "mem_sleep_default=deep" ];

    # Batch dirty page flushes
    kernel.sysctl."vm.dirty_writeback_centisecs" = 6000;
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

        # Wifi power
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        # Audio codec
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;
        SOUND_POWER_SAVE_CONTROLLER = "Y";

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
          "combine.props"."audio.position" = [ "FL" "FR" ];
          "combine.on-demand-streams" = true;
          "combine.start-streams-on-load" = false;
          #"stream.props" = {};
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

      "92-low-latency"."context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 48000 ];
      };
    };

    pipewire.wireplumber.extraConfig = {
      # might not be necessary
      "10-bluetooth"."monitor.bluez.properties" = {
        "bluez5.codecs" = [ "aac" "sbc_xq" "sbc" ];
        "bluez5.enable-hw-volume" = true;
        "bluez5.enable-msbc" = false;
      };

      # auto-switch to new sinks (mostly for bluetooth)
      "11-default-policy"."wireplumber.settings" = {
        "default-policy-move" = true;
        "default-policy-follow" = true;
      };
    };

    udev = {
      packages = [ pkgs.platformio-core.udev ];
      # Pi Pico
      extraRules = ''
        SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", MODE="0666"
        SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", MODE="0666"
      '';
      #packages = [ # micro:bit
      #  (pkgs.writeTextFile {
      #    name = "microbit_udev";
      #    text = ''
      #      SUBSYSTEM=="usb", ATTR{idVendor}=="0d28", MODE="0664", TAG+="uaccess"
      #    '';
      #    destination = "/etc/udev/rules.d/50-microbit.rules";
      #  })
      #];
    };
  };
}
