{ pkgs, lib, ... }: {
  imports = [
    ./services.nix
    ../common.nix
    ../../modules/pi.nix
  ];
  environment.systemPackages = with pkgs; [ bun spotdl jq fish ];

  hardware = {
    firmware = [ pkgs.raspberrypiWirelessFirmware ];
    i2c.enable = true;

    deviceTree = { # spi for display output
      enable = true;
      filter = "*rpi-zero-2*.dtb";
      overlays = [{ name = "spi0"; dtsFile = ./spi0.dts; }];
    };
  };
  boot.kernelModules = [ "spidev" ];

  fonts.packages = [(pkgs.stdenv.mkDerivation { # Planning fonts
    name = "fonts";
    src = ../../home-manager/fonts;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp -r $src/* $out/share/fonts/truetype/
    '';
  })];

  # Networking
  networking = {
    hostName = "alechomelab";
    firewall.allowedTCPPorts = [ 80 9000 8000 ];
    #wifi.powersave = false; # Stop network drops
  };

  services = {
    samba = { # USB NAS
      enable = true;
      package = pkgs.samba4Full; # Autodiscovery support
      openFirewall = true;
      settings."USB" = {
        path = "/media";
        writable = true;
        "valid users" = [ "alec" ];
        "admin users" = [ "alec" ]; # Full read/write access
      };
    };
    avahi.publish.userServices = true; # NAS
    samba-wsdd = { # Auto-disovery
      enable = true;
      openFirewall = true;
    };
  };

  fileSystems."/media" = { # Attached USB drive
    device = "/dev/disk/by-label/AlecHomelabDrive";
    fsType = "ext4";
    options = [ "nofail" ];
  };
  system.stateVersion = "25.11";

  /*
  # For proper boot
  kernel=u-boot-rpi3.bin
  arm_64bit=1
  enable_uart=1

  # Turn on spi & i2c and gpio buttons
  dtparam=spi=on
  dtparam=i2c_arm=on
  gpio=6,19,5,26,13,21,20,16=pu

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
