{ pkgs, ... }:

let
  retroarchCustom = pkgs.retroarch-bare.overrideAttrs (old: {
    # dbus is needed so retroarch's bluez D-Bus bluetooth driver compiles in
    # (the alternative — bluetoothctl driver — screen-scrapes CLI output and
    # broke when bluez 5.86 changed non-interactive output flushing).
    buildInputs = (old.buildInputs or []) ++ [ pkgs.dbus ];
    configureFlags = old.configureFlags ++ [
      "--enable-opengles" # Mali GPU on H700 supports GLES, not full desktop GL
      "--enable-opengles3"
      "--enable-kms"
      #"--enable-neon" # ARM NEON SIMD

      "--enable-threads" # audio
      "--enable-wifi" # wifi menu
      "--enable-bluetooth" # bt menu
      "--enable-dbus" # enables the bluez D-Bus bluetooth driver (avoids fragile bluetoothctl scraping)

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
    installPhase = "install -Dt $out/lib/retroarch/cores platform/libretro/fake08_libretro.so";
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
    openssh.enable = true;
    libinput.enable = true; # todo
    earlyoom = {
      enable = true;
      freeMemThreshold = 5;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
    # todo modularize
    avahi = {
      enable = true;
      nssmdns4 = true;
      openFirewall = true;
      publish = {
        enable = true;
        addresses = true;
        workstation = true;
      };
    };
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
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

  powerManagement.resumeCommands = ''
    ${pkgs.systemd}/bin/systemctl --user -M alec@ restart wireplumber pipewire pipewire-pulse
    ${pkgs.systemd}/bin/systemctl restart mnt-AlecContent.automount 2>/dev/null || true
  '';

  networking = {
    useNetworkd = false;
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
  systemd.network.enable = false; # no networkd
  services.resolved.settings.Resolve.MulticastDNS = "no"; # use avahi

  hardware.graphics.enable = true; # Mesa/OpenGL
  security.rtkit.enable = true; # realtime priority for pw
  powerManagement.cpuFreqGovernor = "schedutil";
  systemd.services.NetworkManager-wait-online.enable = false;
  boot.kernelParams = [
    "cma=256M" # default 32mb, for running more intensive games
    "nowatchdog"
    "nmi_watchdog=0"
  ];
  # rtw88 deep low-power state causes intermittent WiFi drops on RTL8821CS.
  boot.extraModprobeConfig = ''
    options rtw88_core disable_lps_deep=Y
  '';

  # RTL8821CS WiFi+BT combo: firmware LPS entry causes coex h2c timeouts spamming dmesg
  # ("coex request time out", "failed to send h2c command", "firmware failed to leave lps state").
  # disable_lps_deep alone isn't enough — regular LPS still triggers the bug. Force power_save off
  # via iw once wlan0 exists. Restart on wlan0 (re)appearance so it sticks across rfkill toggles.
  systemd.services.wifi-no-powersave = {
    description = "Disable WiFi power_save (RTL8821CS BT-coex workaround)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wifi-no-powersave" ''
        for _i in 1 2 3 4 5 6 7 8 9 10; do
          [ -d /sys/class/net/wlan0 ] && break
          sleep 1
        done
        ${pkgs.iw}/bin/iw dev wlan0 set power_save off || true
      '';
    };
  };
  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 0;
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
    "vm.vfs_cache_pressure" = 50;
  };

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" "gamemode" "bluetooth" "networkmanager" "video" "uinput" "tty" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  services.journald.extraConfig = "Storage=volatile"; # Extend SD card lifespan

  # WirePlumber: prefer A2DP (high-quality stereo output, no mic) over HFP/HSP.
  # bluez5.auto-connect: request A2DP profile first, then HFP as fallback.
  # Removing the wireplumber.settings block — bluetooth.autoswitch-to-headset-profile
  # is not a valid key in this WirePlumber version and causes the file to be ignored.
  services.pipewire.wireplumber.extraConfig."10-bluetooth" = {
    "monitor.bluez.properties" = {
      "bluez5.roles"            = [ "a2dp_sink" "a2dp_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
      "bluez5.codecs"           = [ "sbc_xq" "aac" "sbc" ];
      "bluez5.auto-connect"     = [ "a2dp_sink" "a2dp_source" "hsp_hs" "hfp_hf" ];
      "bluez5.enable-hw-volume" = true;
      "bluez5.enable-msbc"      = false;
    };
  };
}
