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
  ];

  boot = {
    initrd = {
      kernelModules = [ "amdgpu" ];
      includeDefaultModules = false;
    };
    binfmt.emulatedSystems = [ "aarch64-linux" ];
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
