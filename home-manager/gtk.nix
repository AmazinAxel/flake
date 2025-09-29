{ pkgs, ... }: {
  gtk = {
    enable = true;
    gtk3.bookmarks = [
      "file:///home/alec/Downloads"
      "file:///home/alec/Documents"
      "file:///home/alec/Music"
      "file:///home/alec/Pictures"
      "file:///home/alec/Projects"
      "file:///home/alec/Videos"
    ];

    font = {
      name = "Ubuntu Nerd Font Propo Medium";
      package = pkgs.nerd-fonts.ubuntu-sans;
      size = 11;
    };
    iconTheme = {
      name = "MoreWaita";
      package = pkgs.morewaita-icon-theme;
    };
    theme = {
      name = "Graphite-Dark-nord";
      package = (pkgs.graphite-gtk-theme.override {
        tweaks = [ "nord" ];
        themeVariants = [ "default" ];
        colorVariants = [ "dark" ];
      });
    };
    gtk3.extraConfig.gtk-im-module = "fcitx";
    gtk4.extraConfig.gtk-im-module = "fcitx";
  };

  dconf = {
    enable = true;
    settings = {
      # Force dark mode on all apps
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";

      # Gnome text editor config
      "org/gnome/TextEditor" = {
        custom-font = "Iosevka 12";
        highlight-current-line = true;
        restore-session = true;
        show-line-numbers = true;
        style-scheme = "Adwaita";
        style-variant = "dark";
        use-system-font = false;
      };

      # Gnome sound recorder default audio output
      "org/gnome/SoundRecorder".audio-profile = "mp3";
    };
  };
}
