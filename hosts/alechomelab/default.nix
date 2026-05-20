{ pkgs, ... }: {
  imports = [
    ./services.nix
    ../common.nix
    ../../modules/pi.nix
  ];
  environment.systemPackages = with pkgs; [ bun jq fish ];
  systemd.tmpfiles.rules = [ "w /sys/class/leds/ACT/trigger - - - - none" ]; # no LED

  users.extraGroups = {
    gpio = { };
    spi = { };
  };
  users.users.alec.extraGroups = [ "gpio" "spi" ];

  hardware = {
    i2c.enable = true;

    deviceTree = { # spi for display output
      enable = true;
      filter = "*rpi-zero-2*.dtb";
      overlays = [{ name = "spi0"; dtsFile = ./spi0.dts; }];
    };
  };
  boot.kernelModules = [ "spidev" ];

  # Networking
  networking = {
    hostName = "alechomelab";
    firewall.allowedTCPPorts = [ 80 9000 8000 ];
  };

  # must run 'sudo smbpasswd -a alec' to log in!!
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
    services.openssh.settings.Macs = [ "hmac-sha2-512" ]; # fix ios pass
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
  [all]
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
