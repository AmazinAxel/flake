{ pkgs, lib, ... }:

let
  mainlinePatches = map (p: ./mainline-patches/${p})
    (builtins.filter (f: lib.hasSuffix ".patch" f)
      (builtins.attrNames (builtins.readDir ./mainline-patches)));

  devicePatches = map (p: ./patches/${p})
    (builtins.filter (f: lib.hasSuffix ".patch" f)
      (builtins.attrNames (builtins.readDir ./patches)));

  armMissingOptions = [ "DMIID" ];

  # extra firmware for working wifi and display
  extraFirmwareFiles = pkgs.runCommand "kernel-extra-firmware" {} ''
    mkdir -p $out/rtl_bt $out/rtw88 $out/panels
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8821cs_config.bin $out/rtl_bt/
    cp ${pkgs.linux-firmware}/lib/firmware/rtl_bt/rtl8821cs_fw.bin $out/rtl_bt/
    cp ${pkgs.linux-firmware}/lib/firmware/rtw88/rtw8821c_fw.bin $out/rtw88/
    cp ${./panels}/anbernic,rg35xx-plus-panel.panel $out/panels/
    cp ${./panels}/anbernic,rg35xx-plus-rev6-panel.panel $out/panels/
  '';

  baseKernel = pkgs.linuxManualConfig {
    inherit (pkgs.linux_6_19) version src modDirVersion;
    configfile = ./rocknix-linux.conf;
    kernelPatches = map (p: {
      name = builtins.baseNameOf p;
      patch = p;
    }) (mainlinePatches ++ devicePatches);
    allowImportFromDerivation = true;
  };

  # fix? todo
  customKernel = baseKernel.overrideAttrs (old: {
    passthru = old.passthru // {
      config = old.passthru.config // {
        isEnabled = opt:
          if builtins.elem opt armMissingOptions then true
          else old.passthru.config.isEnabled opt;
        isYes = opt:
          if builtins.elem opt armMissingOptions then true
          else old.passthru.config.isYes opt;
        isSet = opt:
          if builtins.elem opt armMissingOptions then true
          else old.passthru.config.isSet opt;
      };
    };

    postPatch = (old.postPatch or "") + ''
      mkdir -p external-firmware/rtl_bt external-firmware/rtw88 external-firmware/panels
      cp ${extraFirmwareFiles}/rtl_bt/* external-firmware/rtl_bt/
      cp ${extraFirmwareFiles}/rtw88/* external-firmware/rtw88/
      cp ${extraFirmwareFiles}/panels/* external-firmware/panels/
    '';
  });

  customLinuxPackages = pkgs.linuxPackagesFor customKernel;
  rocknixJoypad = customLinuxPackages.callPackage ./rocknix-joypad.nix { };
in {
  boot.kernelPackages = customLinuxPackages;
  boot.extraModulePackages = [ rocknixJoypad ];
}
