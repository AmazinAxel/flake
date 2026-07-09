{ inputs, pkgs, ... }: {
  imports = [
    ./sway/keybinds.nix
    ./sway/sway.nix

    ./fish.nix
    ./foot.nix
    ./gtk.nix
    ./helix.nix
    ./mpd.nix
    ./spicetify.nix
    ./swappy.nix
    ./vscode.nix
    ./zen.nix

    inputs.ags.homeManagerModules.default
  ];

  # WebKit's a11y bus probe has no disable knob (GTK_A11Y/NO_AT_BRIDGE don't
  # reach it); drop the harmless connect warnings at the journal instead
  # systemd.user.services.ags.Service.LogFilterPatterns = "~Can't connect to a11y bus";

  programs = {
    home-manager.enable = true;
    ags = {
      enable = true;
      configDir = ../ags;
      systemd.enable = true;

      extraPackages = with inputs.astal.packages.x86_64-linux; [
        apps # App launcher
        auth
        battery
        bluetooth
        mpris
        notifd
        wireplumber

        pkgs.webkitgtk_6_0 # webview
        pkgs.glib-networking # TLS stuff for webview
        pkgs.gst_all_1.gst-plugins-base # webview media
        pkgs.brightnessctl
        pkgs.sway # swaymsg IPC
        pkgs.iwd # wifi control
        pkgs.mpc # MPD
        pkgs.cliphist
        pkgs.wl-clipboard # wl-copy
        pkgs.swappy
        pkgs.swaybg
        pkgs.procps # pkill for gpu-screenrec
      ];
    };
  };
  systemd.user.startServices = "sd-switch"; # Better system unit reloads

  home = {
    stateVersion = "26.05";
    username = "alec";
    homeDirectory = "/home/alec";

    # Global cursor
    pointerCursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
      gtk.enable = true;
      sway.enable = true;
    };
  };

  # Astal clipboard management
  services.cliphist = {
    enable = true;
    extraOptions = [ "-preview-width" "200" "-max-items" "20" "-max-dedupe-search" "5" ];
  };

  xdg = {
    configFile."xdg-terminals.list".text = "footclient.desktop\n"; # open in Terminal
    mimeApps = {
      enable = true;
      defaultApplications = { # open in lightbrowse by default
        "x-scheme-handler/http" = "com.amazinaxel.lightbrowse.desktop";
        "x-scheme-handler/https" = "com.amazinaxel.lightbrowse.desktop";
        "text/html" = "com.amazinaxel.lightbrowse.desktop";
      };
    };


    dataFile."fonts" = { # Symlink fonts
      target = "./fonts";
      source = ./fonts;
    };

    userDirs = {
      enable = true;
      createDirectories = true; # Auto-creates all directories
      desktop = "/home/alec"; # don't want this folder
      publicShare = null;
      templates = null;
      extraConfig = {
        PROJECTS = "/home/alec/Projects";
        CAPTURES = "/home/alec/Videos/Captures";
        CLIPS = "/home/alec/Videos/Clips";
      };
    };
  };
}
