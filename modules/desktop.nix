{ inputs, pkgs, ... }: {

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.alec.imports = [ ../home-manager/home.nix ];
    useGlobalPkgs = true; # Faster eval
  };

  environment = {
    systemPackages = with pkgs; [
      # Desktop services
      libnotify # Astal internal notifications
      mpc # CLI for Astal media player
      cifs-utils # Needed for mounting Samba NAS drive
      rsync # Quickly pull files from NAS drive
      brightnessctl # Screen brightness CLI for Astal
      adwaita-icon-theme # Icons for GTK apps
      hyprshot # Screenshot tool
      wl-clipboard # Astal clipboard utils

      # Desktop applications
      gthumb # Image & video viewer & editor
      gnome-text-editor # Simple text editor
      gnome-system-monitor # Task manager
      nemo-with-extensions # File manager
      nemo-fileroller # Create archives in nemo
      file-roller # Open archives in nemo
      discord # Voice & video chat app
      filezilla # FTP client
      prismlauncher # Minecraft launcher

      # Scripts
      (writeScriptBin "fetch" (builtins.readFile ../scripts/fetch.fish))
      (writeScriptBin "sys-sync" (builtins.readFile ../scripts/sys-sync.fish))
      (writeScriptBin "nx-gc" (builtins.readFile ../scripts/nx-gc.fish))
      (writeScriptBin "screenshot" (builtins.readFile ../scripts/screenshot.fish))
    ];
    sessionVariables.NIXOS_OZONE_WL = "1"; # For Electron
  };

  fonts.packages = with pkgs; [
    iosevka # Programming
    wqy_zenhei # Chinese
  ];

  programs = {
    hyprland.enable = true; # WM
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
          classicui.globalSection."Theme" = "Nord-Dark"; # Theme
        };
      };
    };
  };

  services = {
    gvfs.enable = true; # For nemo trash & NAS autodiscov
    devmon.enable = true; # Automatic drive mount/unmount
    logind.settings.Login.HandlePowerKey = "ignore"; # Don't turn off computer on power key press

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
        command = "start-hyprland";
        user = "alec";
      };
    };
  };
  security.pam.services.hyprlock = {}; # Hyprlock hm package requires this

  # Bluetooth
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false; # Don't start bluetooth until its needed
  };
}