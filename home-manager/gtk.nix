{ pkgs, config, ... }: {
    gtk = {
        enable = true;
        gtk3.bookmarks = let
            home = config.home.homeDirectory;
        in [
            "file:///${home}/Desktop"
            "file:///${home}/Downloads"
            "file:///${home}/Documents"
            "file:///${home}/Music"
            "file:///${home}/Pictures"
            "file:///${home}/Projects"
            "file:///${home}/Other"
            "file:///${home}/Videos"
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
        theme.name = "Graphite-Dark-nord"; # or -hdpi or -xhdpi for high-res screens

        gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
            gtk-im-module = "fcitx";
        };
        gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
            gtk-im-module = "fcitx";
        };
    };
}
