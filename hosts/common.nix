{ pkgs, lib, ... }: {
  users.users.alec = { # Default user
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "video" "dialout" ];
    initialPassword = "nixos"; # must be changed implicitly with passwd!!!
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
    blacklistedKernelModules = [ "sp5100_tco" ]; # speeds up shutdown on amd stop since it doesnt wait for watchdog
    kernelModules = [ "tcp_bbr" ];

    # faster networking
    kernel.sysctl = {
      "net.ipv4.tcp_congestion_control" = "bbr";
      "net.core.default_qdisc" = "fq"; # goes with BBR
      "net.ipv4.tcp_fastopen" = 3; # saves a round-trip
      "net.ipv4.tcp_slow_start_after_idle" = 0; # don't reset cwnd after idle
      "net.ipv4.tcp_mtu_probing" = 1; # reduces fragmentation
      "net.ipv4.tcp_notsent_lowat" = 16384; # reduce latency
    };
    initrd.systemd.enable = lib.mkDefault true; # Faster parallel boot
  };

  networking = {
    dhcpcd.enable = false;
    useNetworkd = true; # newer
    firewall.allowedUDPPorts = [ 5353 ]; # .local resolution
    wireless.iwd = {
      enable = lib.mkDefault true;
      settings = {
        IPv6.Enabled = true;
        Settings.AutoConnect = true;
        General.EnableNetworkConfiguration = false; # networkd handles DHCP now
        Network.NameResolvingService = "systemd";
        Scan.InitialPeriodicScanInterval = 10;
        Scan.MaximumPeriodicScanInterval = 30;
      };
    };
  };

  systemd.network = {
    enable = true;
    networks."20-default" = {
      matchConfig.Type = "ether wlan";
      networkConfig = {
        DHCP = "yes";
        IPv6AcceptRA = true;
        IgnoreCarrierLoss = "5s"; # tolerate short wifi drops
        MulticastDNS = true; # .local resolution and hostname publishing
      };
      dhcpV4Config.UseMTU = true; # avoid fragmentation
    };
    wait-online = {
      timeout = 10; # Dont prolong boot for too long
      extraArgs = [ "--operational-state=routable" ];
    };
  };

  programs = {
    git = {
      enable = true;
      package = pkgs.gitMinimal;
      config = {
        init.defaultBranch = "main";
        color.ui = true;
        core.editor = "hx";
        credential.helper = "store";
        github.user = "AmazinAxel"; # Github
        user.name = "AmazinAxel"; # Git
        push.autoSetupRemote = true;
      };
    };
    command-not-found.enable = false;
    nano.enable = false; # use Helix
  };

  time.timeZone = "America/Los_Angeles"; # lang also set to en_US
  zramSwap.enable = lib.mkDefault true; # Compress ram for better performance

  nixpkgs.config.allowUnfree = true;
  nix = {
    channel.enable = false; # we only use flakes

    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      warn-dirty = false;
      download-buffer-size = 268435456; # 256 MiB
      trusted-users = [ "alec" ]; # for remote deployments
    };
  };

  services = {
    journald.extraConfig = "SystemMaxUse=20M";
    resolved = {
      enable = true;
      settings.Resolve = {
        MulticastDNS = "yes"; # resolve and publish hostname on .local
        DNS = "1.1.1.1#cloudflare-dns.com 1.0.0.1#cloudflare-dns.com";
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
