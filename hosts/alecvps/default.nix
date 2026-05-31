{ modulesPath, pkgs, lib, ... }:
let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICh1nH79rMAd7qEySygClFNsnGRsHRabisFZCD7nKYEz axel@amazinaxel.com";
in {
  imports = [
    #./scripts.nix # todo add some helper scripts to change server and pull/push
    ../common.nix
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  proxmoxLXC = {
    privileged = false; # unprivileged container
    manageNetwork = false; # Proxmox handles network
    manageHostName = true; # keep networking.hostName
  };

  # needed for ssh keys?? not sure
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  networking.wireless.iwd.enable = lib.mkForce false; # no wifi in a container todo use mkdefault

  boot.loader.systemd-boot.enable = false; # fix boot eval
  zramSwap.enable = false; # cant use in proxmox

  services.openssh = {
    enable = true; # todo remove its redundant
    openFirewall = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  users.users.root.openssh.authorizedKeys.keys = [ key ];

  services.minecraft-server = {
    enable = true;
    dataDir = "/var/lib/mcserver";
    package = pkgs.papermc;
    jvmOpts = "-Xmx1567M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20"; # jar is ran with --nogui
    openFirewall = true;
    eula = true;
  };
  environment.sessionVariables.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.systemd ]; # fix MC startup warning

  # cache DNS lookups TODO add to common.nix??
  services.resolved.settings.Resolve = {
    Cache = "yes";
    CacheFromLocalhost = true;
  };

  boot.kernel.sysctl."net.ipv4.tcp_notsent_lowat" = 16384; # lower latency?

  nix.settings = {
    download-buffer-size = 268435456; # 256 MiB TODO move to common.nix
    sandbox = false;
  };

  services.fstrim.enable = lib.mkForce false; # Proxmox handles this

  fileSystems = lib.mkForce {};

  nixpkgs.hostPlatform = "x86_64-linux";

  # Networking
  networking.hostName = "alecvps";
  system.stateVersion = "25.11";
}
