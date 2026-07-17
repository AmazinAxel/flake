{ pkgs, inputs, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
    ../../modules/laptop.nix
    ../../modules/printing.nix
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
      ".bun"
    ];
  };

  networking.hostName = "alecolaptop";
  home-manager.users.alec.imports = [ ./hm.nix ];

  swapDevices = [{ device = "/persist/swapfile"; size = 10 * 1024; }];

  environment.systemPackages = with pkgs; [
    gimp3
    libreoffice
    thunderbird
    zettlr
    (symlinkJoin {
      name = "kicad"; paths = [ kicad ]; nativeBuildInputs = [ makeWrapper ];
      postBuild = "wrapProgram $out/bin/kicad --set GTK_THEME Adwaita";
    })

    openjdk25
    bun
    claude-code
    platformio-core
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
  };

  services = {
    pipewire = {
      extraConfig.pipewire = {
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

      # might not be necessary
      wireplumber.extraConfig = {
        "10-bluetooth"."monitor.bluez.properties" = {
          "bluez5.codecs" = [ "aac" "sbc_xq" "sbc" ];
          "bluez5.enable-msbc" = false;
        };
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
