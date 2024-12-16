{ inputs, pkgs, ... }: {
  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ swayidle swww brightnessctl gammastep ];
    #xwayland.enable = false;
  };

  environment.systemPackages = with pkgs; [
    # Icon packs
    morewaita-icon-theme
    icon-library
    font-awesome # For Swappy

    polkit_gnome
    gsettings-desktop-schemas
    xdg-desktop-portal-gtk
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-wlr
    adwaita-icon-theme # Icon theme
    gnome-bluetooth # Bluetooth service
  ];

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

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  services = {
    devmon.enable = true; # Automatically mounts/unmounts attached drives
    #udisks2.enable = true; # For getting info about drives
    #gnome.gnome-keyring.enable = true; # TODO learn how to properly set up keyring
    #greetd = {
    #  enable = true;
    #  settings.default_session = {
    #    command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --cmd dbus-run-session ${pkgs.swayfx}/bin/sway";
    #    user = "greeter"; # Probably not required
    #  };
    #};
  };
}