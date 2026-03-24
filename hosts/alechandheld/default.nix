{ pkgs, lib, ... }:

let
  retroarchCustom = pkgs.retroarch-bare.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [
      "--enable-opengl" # enables opengl support
      #"--enable-opengles" # ???
      #"--enable-opengles3" # ???
      "--enable-kms"

      #"--enable-alsa" # audio
      #"--enable-threads" # audio
      "--enable-wifi" # wifi menu
      "--enable-bluetooth" # bt menu

      # unused
      "--disable-v4l2" # camera
      "--disable-microphone" # no mic
      #"--disable-x11"
      #"--disable-vulkan" # probably fine
      #"--disable-wayland"
    ];
  });

  fake08Core = pkgs.stdenv.mkDerivation {
    pname = "libretro-fake-08";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "jtothebell";
      repo = "fake-08";
      rev = "f6bab5a7ba521ce440e45d1aeef6122674be6ee9";
      hash = "sha256-ngnZdo7bQFLcwLOM+J+7CZiTCjz+tgszdwePE6Ek/Jg=";
      fetchSubmodules = true;
    };
    buildPhase = "make -C platform/libretro platform=unix";
    installPhase = ''
      install -Dt $out/lib/retroarch/cores platform/libretro/fake08_libretro.so
    '';
    passthru.libretroCore = "/lib/retroarch/cores";
    passthru.core = "fake08";
  };
in {
  # sudo nixos-rebuild boot --flake .#alechandheld --target-host alec@10.0.0.169 --sudo --ask-sudo-password --no-reexec --option system "aarch64-linux"
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./customKernel.nix
    ./inputHandlers.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    retroarchCustom
    brightnessctl
    fake08Core
    libretro.mgba
    libretro-core-info # has fake-08 core info too
  ];

  home-manager.users.alec.imports = [ ./hm.nix ];
  programs.gamemode.enable = true;
  zramSwap.enable = false; # Breaks boot if enabled

  services = {
    cage = {
      enable = true;
      user = "alec";
      program = "${pkgs.gamemode}/bin/gamemoderun ${retroarchCustom}/bin/retroarch";
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
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user !== "alec") return;
      if (action.id.startsWith("org.bluez") ||
          action.id === "org.freedesktop.login1.power-off" ||
          action.id === "org.freedesktop.login1.reboot" ||
          action.id === "org.freedesktop.login1.suspend" ||
          action.id === "org.freedesktop.login1.hibernate") {
        return polkit.Result.YES;
      }
    });
  '';

  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl --user -M alec@ restart wireplumber pipewire pipewire-pulse
  '';

  networking = {
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
    hostName = "alechandheld";
    firewall.enable = false; # causes errors
  };

  hardware.graphics.enable = true; # Mesa/OpenGL
  security.rtkit.enable = true; # realtime priority for pw
  powerManagement.cpuFreqGovernor = "schedutil";
  systemd.services.NetworkManager-wait-online.enable = false;
  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 0;
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
  };

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" "gamemode" "bluetooth" "networkmanager" "video" "uinput" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  services.journald.extraConfig = "Storage=volatile"; # Extend SD card lifespan
}
