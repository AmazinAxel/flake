{ inputs, pkgs, ... }: {
  imports = [ ./hyprland.nix ]; # Hyprland-specific config

  # Home-manager primary desktop entrance
  home-manager = {
    backupFileExtension = "backup2";
    extraSpecialArgs = { inherit inputs; };
    users.alec.imports = [ ../home-manager/home.nix ];
  };

  environment.systemPackages = with pkgs; [
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
    swappy # Screenshot editor
    gthumb # Image & video viewer & lightweight editor
    gnome-text-editor # Simple text editor
    gnome-system-monitor # Task manager
    nemo-with-extensions # File manager
    nemo-fileroller # Create archives in nemo
    file-roller # Open archives in nemo
    discord # Voice & video chat app
    filezilla # FTP client

    # For shell keybinds
    inputs.astal.packages.${pkgs.system}.io

    # Wayland MC w/ key modifiers patch
    (prismlauncher.override {
      glfw3-minecraft = glfw3-minecraft.overrideAttrs (prev: {
        patches = [ ../overlays/glfw-key-modifiers.patch ];
      });
    })

    # Scripts
    (writeScriptBin "fetch" (builtins.readFile ../scripts/fetch.fish))
    (writeScriptBin "sys-sync" (builtins.readFile ../scripts/sys-sync.fish))
    (writeScriptBin "nx-gc" (builtins.readFile ../scripts/nx-gc.fish))
    (writeScriptBin "screenshot" (builtins.readFile ../scripts/screenshot.fish))
  ];

  # Custom fonts
  fonts.packages = with pkgs; [
    iosevka # Coding font
    font-awesome # For Swappy
    wqy_zenhei # Chinese font
  ];

  programs = {
    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        color.ui = true;
        core.editor = "codium";
        credential.helper = "store";
        github.user = "AmazinAxel"; # Github
        user.name = "AmazinAxel"; # Git
        push.autoSetupRemote = true;
      };
    };
    nix-ld.enable = true; # For dynamic executables
  };

  # Chinese input support
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5 = {
      addons = with pkgs; [ fcitx5-chinese-addons fcitx5-nord ];
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
          classicui.globalSection."Theme" = "Nord-Dark"; # Enable theme
        };
      };
    };
  };

  services = {
    gvfs.enable = true; # For nemo trash & NAS autodiscovery support
    devmon.enable = true; # Automatically mounts/unmounts drives

    # .local resolution for homelab
    avahi = {
      enable = true;
      nssmdns = true;
    };

    # Sound support
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber.enable = true;
    };
  };

  # Bluetooth support
  hardware.bluetooth.enable = true;
}