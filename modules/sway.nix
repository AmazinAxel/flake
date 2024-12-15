{ inputs, pkgs, ... }: {
  sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ swayidle swww brightnessctl ];
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
    bibata-cursors # Custom cursor (for GTK & xwayland apps) - unrelated to Hyprcursor
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
    wqy_zenhei # Chinese font for generally cleaner chars
  ];

  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  services = {
    devmon.enable = true; # Automatically mounts/unmounts attached drives
    #udisks2.enable = true; # For getting info about drives
    #gnome.gnome-keyring.enable = true; # TODO learn how to properly set up keyring
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --cmd Hyprland";
        user = "greeter"; # Probably not required
      };
    };
  };
}