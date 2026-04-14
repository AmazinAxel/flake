{ pkgs, lib, ... }: {
  environment.systemPackages = with pkgs; [ bun spotdl jq fish ];

  hardware = {
    firmware = [ pkgs.raspberrypiWirelessFirmware ];
    i2c.enable = true;
    enableRedistributableFirmware = false; # Causes build fail for .iso otherwise

    deviceTree = { # spi for display output
      enable = true;
      filter = "*rpi-zero-2*.dtb";
      overlays = [{ name = "spi0"; dtsFile = ./spi0.dts; }];
    };
  };

  boot = { # Zero 2W boot
    #kernelPackages = pkgs.linuxPackages_rpi02w;
    kernelModules = [ "gpiochip" "spidev" ];
  };

  fonts.packages = [(pkgs.stdenv.mkDerivation { # Planning fonts
    name = "fonts";
    src = ./fonts;
    installPhase = ''
      mkdir -p $out/share/fonts/truetype
      cp -r $src/* $out/share/fonts/truetype/
    '';
  })];

    # Networking
  networking = {
    hostName = "alechomelab";
    firewall.allowedTCPPorts = [ 80 9000 8000 ];
    #networkmanager = {
      #enable = true; # For nmtui
      #wifi.powersave = false; # Stop network drops
    #};
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
        "admin users" = [ "alec" ]; # Full read & write access
      };
    };
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
}
