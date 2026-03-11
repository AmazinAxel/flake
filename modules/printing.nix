{ pkgs, ... }: {
  # Printing with CUPS
  services = {
    printing = {
      enable = true;
      drivers = [ pkgs.hplip ]; # HP
      listenAddresses = [ "*:631" ];
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
      openFirewall = true;
    };

    avahi = {
      openFirewall = true;
      publish = {
        enable = true;
        userServices = true;
      };
    };
  };
}
