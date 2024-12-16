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
        # Although we use Hyprcursor, GTK apps use their own cursor for some reason
        #cursorTheme = {
        #    name = "Bibata-Modern-Ice";
        #    package = pkgs.bibata-cursors;
        #    size = 24;
        #};
        iconTheme = {
            name = "MoreWaita";
            package = pkgs.morewaita-icon-theme;
        };
        theme = {
            name = "Graphite-Dark-nord";
            package = (pkgs.graphite-gtk-theme.override {
                tweaks = [ "nord" ];
                themeVariants = [ "default" ]; # default: grey | teal, blue
                colorVariants = [ "dark" ];
            });
        };

        gtk3.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
            gtk-im-module = "fcitx";
        };
        gtk4.extraConfig = {
            gtk-application-prefer-dark-theme = 1;
            gtk-im-module = "fcitx";
        };
    };

    home.pointerCursor = {
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
        size = 16;
        #x11.enable = true; # for sway maybe??
    };
}
