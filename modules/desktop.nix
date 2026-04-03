{ inputs, pkgs, ... }: {

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.alec.imports = [ ../home-manager/home.nix ];
    useGlobalPkgs = true; # Faster eval
  };

  environment = {
    systemPackages = with pkgs; [
      # Desktop services
      swaybg
      libnotify # Astal internal notifications
      mpc
      wayfreeze # Screenshot freeze
      grim
      slurp
      satty # Annotation
      brightnessctl
      adwaita-icon-theme # Icons for GTK apps
      wl-clipboard # Astal clipboard utils
      wl-gammarelay-rs # Blue light filter
      gpu-screen-recorder
      samba # Planning app sync
      cifs-utils # Needed for mounting Samba NAS drive
      rsync # Quickly pull files from NAS drive
      playerctl
      killall

      # Desktop applications
      gthumb
      gnome-text-editor
      gnome-system-monitor
      nemo-with-extensions
      nemo-fileroller
      file-roller
      discord
      slack
      filezilla
      (prismlauncher.override {
        additionalLibs = [ pkgs.libxkbcommon ]; # TODO remove temp fix
      })
      #claude-code

      inputs.planning.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Scripts
      (writeScriptBin "fetch" (builtins.readFile ../scripts/fetch.fish))
      (writeScriptBin "sys-sync" (builtins.readFile ../scripts/sys-sync.fish))
      (writeScriptBin "nx-gc" (builtins.readFile ../scripts/nx-gc.fish))
    ];
    sessionVariables.NIXOS_OZONE_WL = "1"; # For Electron
    etc."samba/smb.conf".text = "[global]"; # Workaround to make samba work without needing to enable the service
  };

  fonts.packages = with pkgs; [
    iosevka # Programming
    wqy_zenhei # Chinese
  ];

  programs = {
    dconf.enable = true; # For hm
    nix-ld.enable = true; # For dynamic executables
    gpu-screen-recorder.enable = true; # Clipping & recording software

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
  };

  # Chinese input support
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [ qt6Packages.fcitx5-chinese-addons fcitx5-nord ];
      waylandFrontend = true;

      settings = {
        inputMethod = {
          "Groups/0" = {
            Name = "Default";
            "Default Layout" = "us";
            DefaultIM = "pinyin";
          };
          "Groups/0/Items/0".Name = "keyboard-us";
          "Groups/0/Items/1".Name = "pinyin";
        };
        globalOptions."Hotkey/TriggerKeys"."0" = "Control+Super+space";

        addons = {
          clipboard.globalSection."TriggerKey" = ""; # Disable clipboard
          classicui.globalSection."Theme" = "Nord-Dark";
        };
      };
    };
  };

  services = {
    gvfs.enable = true; # For nemo trash & NAS autodiscov
    devmon.enable = true; # Automatic drive mount/unmount
    logind.settings.Login.HandlePowerKey = "ignore"; # Don't turn off computer on power key press

    # Prevent crashes
    earlyoom = {
      enable = true;
      freeMemThreshold = 5; # 5%
    };

    # .local resolution for homelab
    avahi = {
      enable = true;
      nssmdns4 = true;
    };

    # Sound
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };

    greetd = { # Autologin
      enable = true;
      settings.default_session = {
        command = "sway";
        user = "alec";
      };
    };
  };

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # Don't start bluetooth until its needed
  };

  security.pam.services.astal-auth = {}; # For astal lockscreen to work

  # Since we dont use the sway nix module we have to set the portal explicitly for things like flatpak and screensharing to work
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.common.default = "*";
  };
}
