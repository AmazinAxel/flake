{ lib, ...}: {
  boot.kernelPatches = [{
    patch = null;
    extraConfig = lib.readFile ./config.conf;
  }];
}