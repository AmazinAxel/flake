{ modulesPath, pkgs, lib, ... }:
let
  key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICh1nH79rMAd7qEySygClFNsnGRsHRabisFZCD7nKYEz axel@amazinaxel.com";
in {
  imports = [
    ../mcscripts.nix
    ../common.nix
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];

  proxmoxLXC = {
    privileged = false; # unprivileged container
    manageNetwork = false; # Proxmox handles network
    manageHostName = true; # keep networking.hostName
  };

  networking.wireless.iwd.enable = false; # no wifi in a container
  boot.loader.systemd-boot.enable = false; # fix boot eval
  zramSwap.enable = false; # cant use in proxmox

  services = {
    fstrim.enable = false; # Proxmox handles this
    minecraft-server = {
      enable = true;
      dataDir = "/var/lib/mcserver";
      package = pkgs.papermc;
      jvmOpts = "-Xmx1567M -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=15 -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -XX:G1NewSizePercent=30 -XX:G1MaxNewSizePercent=40 -XX:G1HeapRegionSize=8M -XX:G1ReservePercent=20 -Djava.net.preferIPv6Addresses=true"; # jar is ran with --nogui
      openFirewall = true;
      eula = true;
    };
    openssh = {
      openFirewall = true;
      # settings.PermitRootLogin = "prohibit-password";
      settings.AllowTcpForwarding = true; # VSC Remote-SSH support
      extraConfig = ''
        Match User alec
          PasswordAuthentication yes
      '';
    };
  };

  users.users.root.openssh.authorizedKeys.keys = [ key ];
  users.users.alec.openssh.authorizedKeys.keys = [ key ]; # login key for fast access
  environment.sessionVariables.LD_LIBRARY_PATH = lib.makeLibraryPath [ pkgs.systemd ]; # fix MC startup warning

  programs.nix-ld.enable = true; # for vsc
  users.users.alec.extraGroups = [ "minecraft" ];
  systemd.services.minecraft-server.serviceConfig.UMask = lib.mkForce "0007"; # sudo chmod -R g+rwX /var/lib/mcserver

  nix.settings.sandbox = false; # fix builds on the vps
  fileSystems = lib.mkForce {}; # no need for noatime
  nixpkgs.hostPlatform = "x86_64-linux";

  # Networking
  networking.hostName = "alecvps";
  systemd.network.networks."20-default".matchConfig.Type = lib.mkForce "wlan";
  system.stateVersion = "25.11";
}
