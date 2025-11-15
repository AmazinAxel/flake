{ lib, pkgs, ... }:

let
  kernel = pkgs.linuxManualConfig rec {
    version = "6.16";
    src = fetchTarball {
      url = "https://mirrors.edge.kernel.org/pub/linux/kernel/v6.x/linux-${version}.tar.xz";
      sha256 = "sha256:0j9a4hhlx7a1w8q3h2rhv5iz30xxai1kkrwia855r8d81kpfmmpc";
    };
    configfile = ./kernel.config;
    allowImportFromDerivation = true;
  };
in {
  boot.kernelPackages = lib.mkForce (pkgs.linuxPackagesFor kernel);
}
