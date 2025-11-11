{ lib, pkgs, ...}: {
  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor (pkgs.linux_latest.override {
    configfile = ./config.conf;
    ignoreConfigErrors = true;
  }));
}