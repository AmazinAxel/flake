{ pkgs, lib, ... }: {
  boot.loader = { # Raspi boot
    systemd-boot.enable = false;
    grub.enable = false;
    generic-extlinux-compatible = {
      enable = true;
      configurationLimit = 2;
    };
  };

  services = {
    openssh.enable = true; # SSH support

    # IP resolve shorthand for .local address
    avahi = {
      enable = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true; # For HTTP IP
      };
    };
  };

  fileSystems."/" = { # Device SD card
    device = "/dev/disk/by-label/NIXOS_SD";
    fsType = "ext4";
    options = lib.mkForce [ "noatime" ]; # force to note include discard flag
  };

  services.journald.extraConfig = "Storage=volatile";
  nixpkgs.hostPlatform = "aarch64-linux";
}
