{ pkgs, ... }: {
  # sudo nixos-rebuild boot --flake .#alechandheld --target-host alec@10.0.0.169 --sudo --ask-sudo-password --no-reexec --option system "aarch64-linux"
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./customKernel.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    (retroarch.withCores (cores: with cores; [
      # eeeee todo
    ]))
  ];

  home-manager.users.alec.imports = [ ./hm.nix ];

  programs.gamemode.enable = true;

  zramSwap.enable = false; # Breaks boot if enabled

  services = {
    cage = {
      enable = true;
      user = "alec";
      program = "${pkgs.gamemode}/bin/gamemoderun ${pkgs.retroarch}/bin/retroarch";
      extraArguments = [ "-s" ]; # Allow TTY switching
    };
    sshd.enable = true;
    libinput.enable = true;
    earlyoom = {
      enable = true;
      freeMemThreshold = 5;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    triggerhappy = {
      enable = true;
      bindings = [
        { keys = [ "VOLUMEUP" ];   event = "press"; cmd = "XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.util-linux}/bin/runuser -u alec -- ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"; }
        { keys = [ "VOLUMEDOWN" ]; event = "press"; cmd = "XDG_RUNTIME_DIR=/run/user/1000 ${pkgs.util-linux}/bin/runuser -u alec -- ${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"; }
      ];
    };
  };

  networking = {
    wireless.iwd.enable = false; # todo switch to iwd?
    networkmanager.enable = true;
    hostName = "alechandheld";
    firewall.enable = false; # causes errors
  };

  hardware.graphics.enable = true; # Mesa/OpenGL
  security.rtkit.enable = true; # realtime priority for pw

  powerManagement.cpuFreqGovernor = "schedutil"; # idk what this does

  systemd.services.NetworkManager-wait-online.enable = false; # not needed

  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 0;
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
  };

  #nixpkgs.overlays = [(final: prev: {
  #  retroarch-bare = prev.retroarch-bare.overrideAttrs (old: {
  #    configureFlags = old.configureFlags ++ [
  #      "--enable-opengles"
  #      "--enable-opengles3"
  #      "--enable-opengles3_1"
  #      "--disable-v4l2" # no camera
  #      "--disable-microphone" # no mic
  #    ];
  #  });
  #})];

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" "gamemode" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  services.journald.extraConfig = "Storage=volatile"; # Extend SD card lifespan
}
