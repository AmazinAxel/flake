{ pkgs, ... }:

let
  retroarchCustom = pkgs.retroarch-bare.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [
      "--enable-wifi"
      "--enable-bluetooth"
    ];
  });

  volUp = pkgs.writeShellScript "vol-up" ''
    if [ -f /tmp/fn-held ]; then
      ${pkgs.brightnessctl}/bin/brightnessctl set +10%
    else
      echo -n "VOLUME_UP" > /dev/udp/127.0.0.1/55355 || true
    fi
  '';

  volDown = pkgs.writeShellScript "vol-down" ''
    if [ -f /tmp/fn-held ]; then
      pct=$(${pkgs.brightnessctl}/bin/brightnessctl -m | cut -d, -f4 | tr -d '%')
      [ "''${pct:-100}" -gt 10 ] && ${pkgs.brightnessctl}/bin/brightnessctl set 10%-
    else
      echo -n "VOLUME_DOWN" > /dev/udp/127.0.0.1/55355 || true
    fi
  '';
in {
  # sudo nixos-rebuild boot --flake .#alechandheld --target-host alec@10.0.0.169 --sudo --ask-sudo-password --no-reexec --option system "aarch64-linux"
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./customKernel.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    retroarchCustom
    brightnessctl
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

  services.triggerhappy = {
    enable = true;
    user = "alec";
    bindings = [
      # Track function key (BTN_MODE) state via flag file
      { keys = [ "BTN_MODE" ]; event = "press";   cmd = "${pkgs.coreutils}/bin/touch /tmp/fn-held"; }
      { keys = [ "BTN_MODE" ]; event = "release"; cmd = "${pkgs.coreutils}/bin/rm -f /tmp/fn-held"; }
      # Press: route to brightness (if fn held) or volume
      { keys = [ "KEY_VOLUMEUP" ];   event = "press"; cmd = "${volUp}"; }
      { keys = [ "KEY_VOLUMEDOWN" ]; event = "press"; cmd = "${volDown}"; }
      # Hold (autorepeat): volume only, never brightness regardless of fn state
      { keys = [ "KEY_VOLUMEUP" ];   event = "hold"; cmd = "[ ! -f /tmp/fn-held ] && echo -n VOLUME_UP > /dev/udp/127.0.0.1/55355 || true"; }
      { keys = [ "KEY_VOLUMEDOWN" ]; event = "hold"; cmd = "[ ! -f /tmp/fn-held ] && echo -n VOLUME_DOWN > /dev/udp/127.0.0.1/55355 || true"; }
    ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';

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
    wireless.iwd.enable = false; # todo switch to iwd?
    networkmanager.enable = true;
    hostName = "alechandheld";
    firewall.enable = false; # causes errors
  };

  hardware.graphics.enable = true; # Mesa/OpenGL
  security.rtkit.enable = true; # realtime priority for pw

  powerManagement.cpuFreqGovernor = "schedutil"; # idk what this does

  systemd.services.NetworkManager-wait-online.enable = false; # waiting not needed

  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 0;
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
  };

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" "gamemode" "bluetooth" "networkmanager" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  services.journald.extraConfig = "Storage=volatile"; # Extend SD card lifespan
}
