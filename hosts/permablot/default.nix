{ pkgs, ... }: {
  imports = [
    ../common.nix
    ../../modules/pi.nix
  ];
  environment.systemPackages = with pkgs; [
    (python3.withPackages (ps: with ps; [
      pyserial
      prompt-toolkit
      numpy
      pillow
      scikit-image
    ]))
    poppler-utils
  ];

  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", ATTR{idProduct}=="000a", MODE="0666"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", ATTRS{idProduct}=="000a", MODE="0666"
  '';

  users.extraGroups.gpio = { };
  users.users.alec.extraGroups = [ "gpio" ];
  hardware = {
    i2c.enable = true;
    deviceTree = {
      enable = true;
      overlays = [{
        name = "dwc2-host";
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

  boot.kernelModules = [ "cdc_acm" ];  # dwc2 will autoload now

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
