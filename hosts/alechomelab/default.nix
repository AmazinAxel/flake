{ pkgs, ... }: {
  imports = [
    ./services.nix
    ../common.nix
    ../../modules/pi.nix
  ];

  systemd.tmpfiles.rules = [ "w /sys/class/leds/ACT/trigger - - - - none" ]; # no LED

  users.extraGroups = {
    gpio = { };
    spi = { };
  };
  users.users.alec.extraGroups = [ "gpio" "spi" ];

  hardware = {
    i2c.enable = true;

    # custom spi dts for waveshare display output
    deviceTree = {
      enable = true;
      filter = "*rpi-zero-2*.dtb";
      overlays = [{ name = "spi0"; dtsFile = ./spi0.dts; }];
    };
  };
  boot = {
    kernelModules = [ "spidev" ];
    extraModprobeConfig = ''
      options spidev bufsiz=65536
    '';
    blacklistedKernelModules = [ "snd_bcm2835" "btbcm" "hci_uart" "bluetooth" ]; # dont need audio or bluetooth
  };

  # Networking
  networking = {
    hostName = "alechomelab";
    firewall.allowedTCPPorts = [ 80 ];

    networkmanager.connectionConfig."connection.mdns" = 0; # for avahi
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
    openssh.settings.Macs = [ "hmac-sha2-512" ]; # fix ios pass
    avahi = {
      enable = true;
      nssmdns4 = true; # let the Pi resolve other .local hosts too
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true; # publish .local
        userServices = true; # NAS
      };

      # todo?
      extraServiceFiles.smb = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
        </service-group>
      '';
    };
    resolved.settings.Resolve.MulticastDNS = "no";
    samba-wsdd = { # Auto-disovery
      enable = true;
      openFirewall = true;
    };
  };

  # systemd.services.samba-wsdd = {
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   serviceConfig = {
  #     Restart = "on-failure";
  #     RestartSec = 5;
  #   };
  # };

  fileSystems."/media" = { # Attached USB drive
    device = "/dev/disk/by-label/AlecHomelabDrive";
    fsType = "ext4";
    options = [ "nofail" ];
  };

  swapDevices = [{
    device = "/media/swapfile";
    size = 1024; # MB; lives on USB drive, not SD card
  }];
  system.stateVersion = "25.11";

  /*
  [all]
  kernel=u-boot-rpi3.bin
  arm_64bit=1
  enable_uart=1

  gpu_mem=16
  disable_fw_kms_setup=1
  disable_overscan=1
  hdmi_force_hotplug=0
  hdmi_blanking=2
  boot_delay=0
  disable_splash=1
  avoid_warnings=1
  */
}
