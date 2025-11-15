{ lib, pkgs, ... }:

let
  kernel = pkgs.linuxManualConfig {
    inherit (pkgs) stdenv lib;
    version = "6.16.9";
    src = pkgs.fetchurl {
      url = "https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.16.9.tar.xz";
      sha256 = "13g59jvc6kvp8dzl6ysmzrpq4nh9xvy5va5avrsn6iq5ryiwij3s";
    };
    configfile = ./kernel.config;
  };

  h700KernelPackage = pkgs.linuxPackagesFor kernel;
in {
  boot.kernelPackages = lib.mkForce h700KernelPackage;
}
