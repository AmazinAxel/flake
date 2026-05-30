{ pkgs, lib, ... }: {
  imports = [
    #./scripts.nix # todo add some helper scripts to change server and pull/push
    ../common.nix
    ./hardware-configuration.nix
  ];

  environment.systemPackages = [
    (pkgs.writeScriptBin "fetch" (builtins.readFile ../../scripts/fetch.fish)) # called by fish
    (pkgs.writeScriptBin "nx-gc" (builtins.readFile ../../scripts/nx-gc.fish))
  ];

  users.users.alec.shell = pkgs.fish; # default ssh shell
  programs.fish.enable = true; # fix eval ^

  # We don't import desktop.nix (and therefore home.nix) so the home-manager configuration is minimal here
  home-manager.users.alec = {
    imports = [
      ../../home-manager/helix.nix
      ../../home-manager/fish.nix
    ];
    home.stateVersion = "26.05";
  };

  services.minecraft-server = {
    enable = true;
    dataDir = "/var/lib/mcserver";
    package = pkgs.papermc;
    jvmOpts = "-Xms2048M -Xmx2048M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20"; # jar is ran with --nogui
    openFirewall = true;
    eula = true;
  };
  environment.sessionVariables.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.systemd ]; # fix MC startup warning

  # Networking
  networking.hostName = "alecvps";
  system.stateVersion = "25.11";
}