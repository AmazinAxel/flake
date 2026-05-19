{ pkgs, lib, ... }: {
  users.users.alec = { # Default user
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "dialout" ];
    initialPassword = "nixos";
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = 2; # Save space in /boot
        editor = false;
      };
      efi.canTouchEfiVariables = true;
      timeout = lib.mkForce 0; # Hold down space on boot to access
    };
    tmp.useTmpfs = true;
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    kernelParams = [ "nowatchdog" "nmi_watchdog=0" ];
    kernelModules = [ "tcp_bbr" ];
    kernel.sysctl = { # faster network
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq"; # goes with BBR
      "net.ipv4.tcp_fastopen" = 3; # saves a round-trip
      "net.ipv4.tcp_slow_start_after_idle" = 0; # don't reset cwnd after idle
      "net.ipv4.tcp_mtu_probing" = 1; # reduces fragmentation
    };
    initrd.systemd.enable = lib.mkDefault true; # Faster parallel boot
  };

  networking = {
    dhcpcd.enable = false;
    useNetworkd = true; # newer
    wireless.iwd = {
      enable = lib.mkDefault true;
      settings = {
        IPv6.Enabled = true;
        Settings.AutoConnect = true;
        General.EnableNetworkConfiguration = false; # networkd handles DHCP now
        Network.NameResolvingService = "systemd";
        Scan.InitialPeriodicScanInterval = 10;
        Scan.MaximumPeriodicScanInterval = 30;
        #Scan.DisablePeriodicScan = true; # not needed
      };
    };
  };

  systemd.network = {
    enable = true;
    networks."20-wireless" = {
      matchConfig.Type = "wlan";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
        IgnoreCarrierLoss = "5s";
      };
      dhcpV4Config.UseMTU = true; # honor MTU from router to avoid fragmentation
    };
    wait-online = {
      anyInterface = true; # only need one interface up, todo probably redundant
      timeout = 10; # dont prolong boot for too long
    };
  };

  programs = {
    git = {
      enable = true;
      package = pkgs.gitMinimal;
      config = {
        init.defaultBranch = "main";
        color.ui = true;
        core.editor = "code";
        credential.helper = "store";
        github.user = "AmazinAxel"; # Github
        user.name = "AmazinAxel"; # Git
        push.autoSetupRemote = true;
      };
    };
    command-not-found.enable = false;
  };

  time.timeZone = "America/Los_Angeles"; # lang also set to en_US
  zramSwap.enable = lib.mkDefault true; # Compress ram for better performance

  nixpkgs.config.allowUnfree = true;
  nix.settings = {
    experimental-features = "nix-command flakes";
    auto-optimise-store = true;
    warn-dirty = false;
    trusted-users = [ "alec" ]; # for remote deployments
  };

  services = {
    journald.extraConfig = "SystemMaxUse=20M";
    fstrim.enable = true; # weekly SSD trim
    resolved = {
      enable = true;
      settings.Resolve = {
        MulticastDNS = "no"; # avahi handles mDNS
        DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com";
        #FallbackDNS = "8.8.8.8#dns.google 8.8.4.4#dns.google";
        DNSOverTLS = "opportunistic";
        Domains = "~."; # override DHCP-provided DNS (ISP)
      };
    };
  };
  fileSystems."/".options = [ "noatime" ];
  documentation.enable = false;
  environment.defaultPackages = lib.mkForce [];

  system.stateVersion = lib.mkDefault "24.05";
}
