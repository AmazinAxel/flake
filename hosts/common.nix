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
      "net.core.default_qdisc" = "fq"; # pairs with BBR
    };
    initrd.systemd.enable = lib.mkDefault true; # Faster parallel boot
  };

  networking = {
    dhcpcd.enable = false;
    wireless.iwd = {
      enable = lib.mkDefault true;
      settings = {
        IPv6.Enabled = true;
        Settings.AutoConnect = true;
        General.EnableNetworkConfiguration = true;
        Network.NameResolvingService = "systemd";
      };
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
  };

  services = {
    journald.extraConfig = "SystemMaxUse=20M";
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
  fileSystems."/".options = [ "noatime" "discard" ]; # SSD trim
  documentation.enable = false;
  environment.defaultPackages = lib.mkForce [];

  system.stateVersion = lib.mkDefault "24.05";
}
