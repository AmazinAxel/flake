{ inputs, pkgs, ... }: {

  home-manager = {
    extraSpecialArgs = { inherit inputs; };
    users.alec.imports = [ ../home-manager/home.nix ];
    backupFileExtension = "backup2";
    useGlobalPkgs = true; # Faster eval
  };
  users.users.alec.shell = pkgs.fish; # default shell for ssh and foot

  environment = {
    systemPackages = with pkgs; [
      # Desktop services
      swaybg
      libnotify # Astal internal notifications
      mpc
      wayfreeze # Screenshot freeze
      grim
      slurp
      swappy # Annotation
      brightnessctl
      adwaita-icon-theme # Icons for GTK apps
      wl-clipboard # Astal clipboard utils
      wl-gammarelay-rs # Blue light filter
      gpu-screen-recorder
      cifs-utils # Needed for mounting Samba NAS drive
      rsync # Quickly pull files from NAS drive
      playerctl # mpris control from shell
      # killall
      pass # password management
      gnupg # GPG for passkeys
      xdg-terminal-exec # open in terminals

      # Desktop applications
      gthumb
      gnome-system-monitor
      nemo-with-extensions
      nemo-fileroller
      file-roller
      discord
      slack
      filezilla
      prismlauncher
      claude-code

      inputs.lightbrowse.packages.${pkgs.stdenv.hostPlatform.system}.default

      # Scripts
      (writeScriptBin "fetch" (builtins.readFile ../scripts/fetch.fish))
      (writeScriptBin "sys-sync" (builtins.readFile ../scripts/sys-sync.fish))
      (writeScriptBin "nx-gc" (builtins.readFile ../scripts/nx-gc.fish))
      (writeScriptBin "persist-prune" (builtins.readFile ../scripts/persist-prune.fish))
    ];
    persistence."/persist" = {
      directories = [
        "/var/lib/systemd" # backlight
        "/var/lib/bluetooth" # bt paired devices
      ];
      users.alec = {
        directories = [
          "Documents"
          "Downloads"
          "Pictures"
          "Videos"
          "Music"
          "Projects"

          # keys
          ".ssh"
          ".gnupg"
          ".password-store"

          # apps
          ".config/discord"
          ".config/Slack"
          ".config/filezilla"
          ".local/share/PrismLauncher"
          ".claude"
          ".config/zen"
          ".config/lightbrowse"
          ".cache/lightbrowse"
          ".config/spotify"
          ".cache/spotify"
          ".local/share/mpd"
          ".config/Code"
          ".local/share/ags-sideview"
          ".cache/ags-sideview"

          # GPU cache
          ".cache/mesa_shader_cache"
          ".cache/mesa_shader_cache_db"
          ".cache/radv_builtin_shaders"
          ".cache/qtshadercache-x86_64-little_endian-lp64"
        ];
        files = [ ".claude.json" ]; # claude login
      };
    };
    sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Electron apps still need this
      MOZ_DBUS_REMOTE = "1"; # fix zen screensharing
    };
    etc."xdg/fcitx5/addon/cloudpinyin.conf".text = ''
      [Addon]
      Enabled=False
    '';
  };

  fonts.packages = with pkgs; [
    nerd-fonts.iosevka # Programming
    wqy_zenhei # Chinese
  ];

  programs = {
    dconf.enable = true; # For hm
    nix-ld.enable = true; # For dynamic executables
    gpu-screen-recorder.enable = true; # Clipping & recording software
    fish.enable = true; # Managed by hm but need this for path
    gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-gnome3;
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
          pinyin.globalSection."FirstRun" = "False";
        };
      };
    };
  };

  console.colors = [ # TTY
    "000000" # black (background)
    "bf616a" # red
    "a3be8c" # green
    "ebcb8b" # yellow
    "81a1c1" # blue
    "b48ead" # magenta
    "88c0d0" # cyan
    "e5e9f0" # white
    "4c566a" # bright black
    "bf616a" # bright red
    "a3be8c" # bright green
    "ebcb8b" # bright yellow
    "81a1c1" # bright blue
    "b48ead" # bright magenta
    "8fbcbb" # bright cyan
    "eceff4" # bright white
  ];

  services = {
    gvfs.enable = true; # For nemo trash & NAS autodiscov
    devmon.enable = true; # Automatic drive mount/unmount
    logind.settings.Login.HandlePowerKey = "ignore"; # Don't turn off computer on power key press

    # Prevent crashes
    earlyoom = {
      enable = true;
      freeMemThreshold = 5; # 5%
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

  security = {
    rtkit.enable = true; # better audio latency
    pam.services.astal-auth = {}; # For astal lockscreen to work
    sudo.extraConfig = "Defaults lecture=never"; # lectures are on by default
  };

  # Bluetooth
  hardware = {
    graphics.enable = true; # this isn't set by sway hm by default for some reason?
    bluetooth = {
      enable = true;
      powerOnBoot = false; # Don't start bluetooth until its needed
      settings.General = {
        Experimental = true; # battery reporting
        FastConnectable = true;
      };
    };
  };

  # Since we dont use the sway nix module we have to set the portal explicitly for things like flatpak and screensharing to work
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config.sway = {
      default = [ "gtk" "wlr" ];
      "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
      "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
    };
  };
}
