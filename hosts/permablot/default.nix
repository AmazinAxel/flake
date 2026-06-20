{ printerblot, ... }: {
  imports = [
    ../common.nix
    ../../modules/pi.nix
  ];

  systemd.tmpfiles.rules = [
    "w /sys/class/leds/ACT/trigger - - - - none" # no LED
    "d /var/lib/blotd 2775 alec users -"
  ];

  systemd.services = {
    blotd = {
      wantedBy = [ "multi-user.target" ];
      after = [ "multi-user.target" ];
      environment.BLOT_DATA_DIR = "/var/lib/blotd";
      serviceConfig = {
        ExecStart = "${printerblot.blotd}/bin/blotd";
        RuntimeDirectory = "blot-socket"; # /run/blot-socket socket
        Restart = "always";
        RestartSec = 2;
      };
    };

    blot-web = {
      wantedBy = [ "multi-user.target" ];
      after = [ "blotd.service" "network.target" ];
      environment.BLOT_DATA_DIR = "/var/lib/blotd";
      serviceConfig = {
        ExecStart = "${printerblot.blot-web}/bin/blot-web";
        User = "alec";
        AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
        Restart = "always";
        RestartSec = 2;
      };
    };
  };

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", MODE="0666"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", MODE="0666"
  '';

  hardware = {
    deviceTree = {
      enable = true;
      overlays = [{
        name = "dwc2-host"; # what does this even do???????????
        dtsText = ''
          /dts-v1/;
          /plugin/;
          / {
            compatible = "brcm,bcm2837";
            fragment@0 {
              target = <&usb>;
              __overlay__ {
                dr_mode = "host";
              };
            };
          };
        '';
      }];
    };
  };

  boot.kernelModules = [ "cdc_acm" ]; # dwc2 TODO needed?

  # Networking
  networking = {
    hostName = "permablot";
    firewall.allowedTCPPorts = [ 80 ];
  };

  system.stateVersion = "25.11";

  /*
  [all]
  # For proper boot
  kernel=u-boot-rpi3.bin
  arm_64bit=1
  enable_uart=1

  # Disable hdmi output
  gpu_mem=16
  disable_fw_kms_setup=1
  disable_overscan=1
  hdmi_force_hotplug=0
  hdmi_blanking=2

  # Faster boot
  boot_delay=0
  disable_splash=1
  avoid_warnings=1
  */
}
