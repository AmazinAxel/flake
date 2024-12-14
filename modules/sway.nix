{ inputs, pkgs, ... }: {
  sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [ swayidle swww brightnessctl ];
    #xwayland.enable = false;
  };

  services = {
    devmon.enable = true; # Automatically mounts/unmounts attached drives
    udisks2.enable = true; # For getting info about drives
    gnome.gnome-keyring.enable = true; # TODO learn how to properly set up keyring
    greetd = {
      enable = true;
      settings.default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --asterisks --cmd Hyprland";
        user = "greeter"; # Probably not required
      };
    };
  };
}