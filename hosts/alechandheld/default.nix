{ pkgs, ... }: {
  imports = [
    #./hardware-configuration.nix
    ../common.nix
  ];

  networking.hostName = "alechandheld";
  #home-manager.users.alec.imports = [ ./hm.nix ];

  # Host-specific packages
  environment.systemPackages = with pkgs; [
    pegasus-frontend
    emulationstation-de
  ];
}