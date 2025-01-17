{ inputs, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # Icon packs
    morewaita-icon-theme
    icon-library
    font-awesome # For Swappy

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
    iosevka # Best coding font
    minecraftia # Awesome Minecraft font
    morewaita-icon-theme
    font-awesome
    wqy_zenhei # Chinese font for generally cleaner chars
  ];
  
  programs.hyprland.enable = true;

  xdg.autostart.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ 
      xdg-desktop-portal-gtk
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-wlr
    ];
  };

  # Set all Electron apps to use Wayland by default 
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  environment.sessionVariables.WLR_NO_HARDWARE_CURSORS = "1";

  security.polkit.enable = true;
  
  services = {
    devmon.enable = true; # Automatically mounts/unmounts attached drives
    udisks2.enable = true; # For getting info about drives
    gnome.gnome-keyring.enable = true; # TODO learn how to properly set up keyring & polkit
    greetd = {
      enable = true;
      settings.default_session = {
        command = "Hyprland";
        user = "alec";
      };
    };
  };
}
