{ inputs, config, lib, pkgs, makeDesktopItem, ... }:

let
  makeWebappLib = import ../lib/makeWebapp.nix { inherit pkgs; };
  makeWebapp = makeWebappLib.makeWebapp;

  textConvert = makeWebappLib.makeWebapp {
    name = "Text Converter";
    url = "amazinaxel.com/tools/textconverter";
    icon = "insert-text-symbolic";
    comment = "Minecraft small text converter";
  };
in
{
  imports = [
    ./hyprland.nix # Hyprland-specific config
    ./sway.nix
  ];

  environment.systemPackages = with pkgs; [
    ags # Widget system & desktop overlay
    foot # Terminal
    nordic # GTK theme - must add it here to apply system-wide
    bun # Fast all-in-one JS toolkit 
    dart-sass # Ags Desktop dependency
    fd # Ags Desktop dependency
    sassc # Ags Sass compiler
    mpd # Music daemon for the Ags music player
    mpc # CLI for the Ags music player
    copyq # Clipboard manager (TODO: replace with Ags clipboard system)
    emote # Emoji picker (TODO: replace with Ags emoji picker)
    #swww # Background manager w/ cool transitions - - remove when done migrating to sway
    hyprlock # Lockscreen system (TODO: replace with Ags lockscreen system)
    jre # For Minecraft - uses the latest stable Java runtime version
    jdk23 # Java JDK version 23 for compling & running jars
    #brightnessctl # Controls laptop brightness - remove when done migrating to sway
    wl-screenrec # Fast screen recorder
    grimblast # Screenshotting tool (TODO: replace with Grim)
    slurp # Screen selection tool for screenshots & screenrecording
    swappy # Quick screenshot editor
    wl-clipboard # Neovim clipboard dependency
    tree-sitter # Neovim parser dependency
    celluloid # Fast, simple GTK video player using mpv
    gnome-text-editor # Clean, tabbed, GTK text editor
    amberol # Lightweight GTK music player
    nemo-with-extensions # Simple file manager
    nemo-fileroller # File manager archive feature
    file-roller # File manager archive feature part 2
    nodejs_22 # Slow JS runtime
    python3 # Python
    python312Packages.pip # Temporary way to install non-declarative pip deps
    steam-run # Used for running some games
    wrangler # Local Workers development
    fish # Better shell
    starship # Fish prompt theme

    # Normal user apps
    microsoft-edge # Web browser
    neovide # GUI-based Neovim
    vscodium # Backup IDE (Neovim is main)
    discord-canary # Voice & video chat app
    libsForQt5.kdenlive # Video editor
    lunar-client # PvP Minecraft client
    blockbench-electron # Minecraft 3D modeler
    jetbrains.idea-community # Jetbrains IDEA
    thunderbird # Best email/IRC client
    obs-studio # For better recording
    gnome-system-monitor # Task manager
    textConvert # AmazinAxel.com small text converter

    # Wayland MC
    (prismlauncher.override {
      glfw3-minecraft = glfw3-minecraft.overrideAttrs (prev: {
        patches = [ ../overlays/glfw/Key-Modifiers-Fix.patch ];
      });
    })

    (writeScriptBin "nx-gc" (builtins.readFile ../scripts/nx-gc.fish))
    (writeScriptBin "reminders" (builtins.readFile ../scripts/reminders.fish))
    (writeScriptBin "spotify-sync" (builtins.readFile ../scripts/spotify-sync.fish))

    gimp # GNU image manipulation program
    teams-for-linux # Unoffical MS Teams client
    libreoffice # Preview Word documents and Excel sheets
    spotdl # Download Spotify playlists

    # this needs to be removed after fixed https://github.com/russelltg/wl-screenrec/issues/50
    wf-recorder

    # Patched fetch program
    (microfetch.overrideAttrs ({ patches, ... }: {
      patches = [ ../overlays/microfetch/Microfetch.patch ];
    }))

    
    (pkgs.makeDesktopItem { # War Thunder
      comment = "The most comprehensive free-to-play, cross-platform, MMO military game with over 2000 vehicles.";
      desktopName = "War Thunder";
      exec =  "steam-run /home/alec/Desktop/WarThunder/launcher";
      genericName = "The most comprehensive free-to-play, cross-platform, MMO military game with over 2000 vehicles.";
      icon = "/home/alec/Desktop/WarThunder/launcher.ico";
      name = "warthunder";
      startupNotify = true;
      startupWMClass = "warthunder";
      terminal = false;
      type = "Application";
    })
  ];

  programs = {
    neovim = {
      enable = true;
      defaultEditor = true;
      withNodeJs = true;
    };
    git = {
      enable = true;
      config = {
        init.defaultBranch = "main";
        url."https://github.com/".insteadOf = [ "gh:" ];
        color.ui = true;
        core.editor = "codium";
        credential.helper = "store";
        github.user = "AmazinAxel"; # Github
        user.name = "AmazinAxel"; # Git
        push.autoSetupRemote = true;
      };
    };
  };

  # Keyboard layout & language (with Chinese support)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5"; 
    fcitx5 = {
      addons = with pkgs; [
        fcitx5-gtk # For frontend & configtool
        fcitx5-chinese-addons # Pinyin
        fcitx5-nord # Theme

        # Simplified Chinese
        fcitx5-rime
        fcitx5-mozc
      ];

      waylandFrontend = true; # Hide warnings on Wayland
      ignoreUserConfig = true; # Ignore .config options - only Nix config applies
      settings = {
        inputMethod = { # Options in 'fcitx5/profile'
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
    printing.enable = true; # Enables CUPS for printing
    logrotate.enable = false; # Don't need this

    # Sound support 
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      wireplumber = {
        enable = true;

        # Fix unnecessary power drain issue
        extraConfig = {
          "10-disable-camera" = {
            "wireplumber.profiles" = {
              main."monitor.libcamera" = "disabled";
            };
          };
        };
      };
    };
    xserver.desktopManager.runXdgAutostartIfNone = true; # Autostart fcitx5
  };
  
  # Bluetooth support
  hardware.bluetooth.enable = true;
}