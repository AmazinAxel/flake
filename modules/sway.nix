{ inputs, pkgs, ... }: {

  environment.systemPackages = with pkgs; [
    # Icon packs
    morewaita-icon-theme
    icon-library
    font-awesome # For Swappy

    polkit_gnome
    gsettings-desktop-schemas
    adwaita-icon-theme # Icon theme
    gnome-bluetooth # Bluetooth service
  ];

  environment.sessionVariables = {
    QT_QPA_PLATFORM = "wayland";
    XDG_CURRENT_DESKTOP = "sway";
    GDK_BACKEND = "wayland";
    NIXOS_OZONE_WL = "1";
  };

  # Enable custom fonts
  fonts.fontconfig.enable = true;
  fonts.packages = with pkgs; [ 
    corefonts
    iosevka # Best Neovim coding font
    minecraftia # Awesome Minecraft font
    morewaita-icon-theme
    #icon-library # Extra icons, remove if not used by future ags
    font-awesome
    wqy_zenhei # Chinese font for generally clearer chars
  ];

  services = {
    devmon.enable = true; # Automatically mounts/unmounts attached drives
    #udisks2.enable = true; # For getting info about drives
    #gnome.gnome-keyring.enable = true; # TODO learn how to properly set up keyring
    greetd = {
      enable = true;
      settings.default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --cmd 'dbus-run-session sway'";
    };
  };
}
