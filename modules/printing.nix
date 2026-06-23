{ pkgs, ... }: {
  # Printing with CUPS
  services = {
    printing = {
      enable = true;
      drivers = [ pkgs.hplip
      pkgs.mfcj880dwlpr pkgs.mfcj880dwcupswrapper pkgs.mfcj470dw-cupswrapper pkgs.mfcj470dwlpr ]; # HP + Brother MFC inkjet, might not need all these TODO
      allowFrom = [ "all" ];
      browsing = true;
      defaultShared = true;
      openFirewall = true;
    };

    avahi = {
      enable = true;
      nssmdns4 = true; # .local resolution
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true; # publish .local
        userServices = true;
      };
    };
    resolved.settings.Resolve.MulticastDNS = "no"; # no resolved
  };
}
