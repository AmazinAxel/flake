{ pkgs, lib, ... }:

let
  retroarchCustom = pkgs.retroarch-bare.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [
      "--enable-opengles" # Mali GPU on H700 supports GLES, not full desktop GL
      "--enable-opengles3"
      "--enable-kms"
    #  "--enable-neon" # ARM NEON SIMD

      "--enable-threads" # audio
      "--enable-wifi" # wifi menu
      "--enable-bluetooth" # bt menu

      # unused
      "--disable-v4l2" # camera
      "--disable-microphone" # no mic
      "--disable-x11"
      "--disable-vulkan" # not supported on this gpu
      "--disable-wayland"
      "--disable-qt" # no desktop ui needed
      "--disable-cdrom" # guh
      "--disable-discord" # rich presence
      "--disable-cheevos" # retroarchievements
      "--disable-langextra"
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
    ./menus.nix
    ./portmaster.nix
  ];

  environment.systemPackages = with pkgs; [
    retroarchCustom
    fake08Core
    libretro.mgba
    libretro-core-info # has fake-08 core info too
  ];

  home-manager.users.alec.imports = [ ./hm.nix ];
  programs.gamemode.enable = true;
  zramSwap.enable = false; # Breaks boot if enabled

  services = {
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
          action.id === "org.freedesktop.login1.hibernate" ||
          (action.id === "org.freedesktop.systemd1.manage-units" &&
           (action.lookup("unit") === "oga_events.service" ||
            action.lookup("unit") === "gamepad-handler.service"))) {
        return polkit.Result.YES;
      }
    });
  '';

  services.logind.settings.Login = {
    HandlePowerKey = "suspend";
    HandlePowerKeyLongPress = "poweroff";
  };

  powerManagement.powerDownCommands = ''
    ${pkgs.util-linux}/bin/sync
  '';

  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl --user -M alec@ restart wireplumber pipewire pipewire-pulse
    # Restart SD card automount unit so the card remounts after wake
    ${pkgs.systemd}/bin/systemctl restart mnt-AlecContent.automount 2>/dev/null || true
  '';

  networking = {
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = false; # Stop network drops
      };
    };
    hostName = "alechandheld";
    firewall.enable = false; # causes errors
  };

  hardware.graphics.enable = true; # Mesa/OpenGL
  security.rtkit.enable = true; # realtime priority for pw
  powerManagement.cpuFreqGovernor = "schedutil";
  systemd.services.NetworkManager-wait-online.enable = false;
  boot.kernelParams = [
    # Panfrost (Mali-G31) uses CMA for GPU buffer objects.  The compiled-in
    # default is 32 MB which is exhausted by Celeste's texture load.
    # ROCKNIX targets reserve 256 MB on the same H700 hardware.
    "cma=256M"
    "nowatchdog"    # disable hardware watchdog timer
    "nmi_watchdog=0"
  ];
  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 0;
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
    "vm.vfs_cache_pressure" = 50;   # keep VFS/dentry caches in RAM longer
  };

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" "gamemode" "bluetooth" "networkmanager" "video" "uinput" "tty" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  services.journald.extraConfig = "Storage=volatile"; # Extend SD card lifespan

  # WirePlumber: prefer A2DP (high-quality stereo output) over HFP/HSP when
  # Bluetooth earbuds connect.  Prevents the mic profile from activating and
  # auto-switches PipeWire's default sink so RetroArch/PortMaster follow.
  services.pipewire.wireplumber.extraConfig."10-bluetooth" = {
    "monitor.bluez.properties" = {
      "bluez5.roles"            = [ "a2dp_sink" "hsp_hs" "hfp_hf" "hfp_ag" "hsp_ag" ];
      "bluez5.codecs"           = [ "sbc_xq" "aac" "sbc" ];
      "bluez5.auto-connect"     = [ "a2dp_sink" ];
      "bluez5.enable-msbc"      = false;
      "bluez5.enable-hw-volume" = true;
    };
    "wireplumber.settings" = {
      # Do not switch to headset profile (HFP/HSP) when earbuds connect — keep A2DP
      "bluetooth.autoswitch-to-headset-profile" = false;
    };
  };
}
