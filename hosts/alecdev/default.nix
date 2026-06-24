{ pkgs, inputs, ... }: {
  imports = [
    ../mcscripts.nix
    ../common.nix
    ../../modules/pi.nix
  ];

  systemd.tmpfiles.rules = [
    "w /sys/class/leds/ACT/trigger - - - - none"
    "w /sys/class/leds/PWR/trigger - - - - none"
  ]; # no power or act LEDs

  environment.systemPackages = [
    (pkgs.writeScriptBin "fetch" (builtins.readFile ../../scripts/fetch.fish)) # called by fish
    (pkgs.writeScriptBin "nx-gc" (builtins.readFile ../../scripts/nx-gc.fish))
  ];

  users.users.alec.shell = pkgs.fish; # default ssh shell
  programs.fish.enable = true; # ^

  # We don't import desktop.nix (and therefore home.nix) so the home-manager configuration is minimal here
  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.users.alec = {
    imports = [
      ../../home-manager/fish.nix
      ../../home-manager/helix.nix
    ];
    home.stateVersion = "26.05";
  };

  services.minecraft-server = {
    enable = true;
    dataDir = "/var/lib/permafrost";
    package = pkgs.papermc;
    jvmOpts = "-Xms2048M -Xmx2048M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20"; # jar is ran with --nogui
    openFirewall = true;
    eula = true;
  };

  # Networking
  networking.hostName = "alecdev";
  system.stateVersion = "26.05";


  /*
  [all]
  # Pi 4
  kernel=u-boot-rpi4.bin
  enable_gic=1
  armstub=armstub8-gic.bin
  arm_boost=1

  # For proper boot
  arm_64bit=1
  enable_uart=1

  # Disable hdmi output
  gpu_mem=16
  disable_fw_kms_setup=1
  disable_overscan=1
  hdmi_force_hotplug=0
  hdmi_blanking=2

  # Faster boot
  boot_delay=0
  disable_splash=1
  avoid_warnings=1
  */
}
