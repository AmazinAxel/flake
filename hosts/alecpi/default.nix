{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix # Hardware-specific settings
    ../common.nix
  ];

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    git
  ];

  networking.hostName = "alecpi"; # Hostname

  # SSH IP resolve shorthand by publishing its address on the network
  services.avahi = {
    enable = true;
    publish = {
      enable = true;
      addresses = true;
    };
  };

  # Raspi boot
  boot.loader = {
    generic-extlinux-compatible.enable = true;
    grub.enable = false;
    systemd-boot.enable = false;
  };

  # Enable SSH support
  services.openssh = {
    enable = true;
    startWhenNeeded = true;
  };
}
