{ lib, pkgs, ...}: {
  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.linux_latest.override {
    extraConfig = lib.readFile ./config.conf;
  }));
}