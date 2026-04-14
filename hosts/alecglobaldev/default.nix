{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [ ];

  services.minecraft-server = {
    enable = true;
    dataDir = "/home/alec/permafrost";
    package = pkgs.papermc;
    jvmOps = "-Xms4092M -Xmx4092M -XX:+UseG1GC -XX:+CMSIncrementalPacing -XX:+CMSClassUnloadingEnabled -XX:ParallelGCThreads=2 -XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10"; # jar ran with --nogui
    openFirewall = true;
    eula = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_rpi4;

  # Networking
  networking = {
    hostName = "alechomelab";
    firewall.allowedTCPPorts = [ 25565 ];
  };
}
