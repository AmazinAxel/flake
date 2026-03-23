{ pkgs, ... }:

let
  retroarchCustom = pkgs.retroarch-bare.overrideAttrs (old: {
    configureFlags = old.configureFlags ++ [
      "--enable-wifi"
      "--enable-bluetooth"
      #"--enable-opengles"
      #"--enable-opengles3"
      #"--enable-opengles3_1"
      #"--disable-v4l2" # no camera
      #"--disable-microphone" # no mic
    ];
  });

  # Runs before cage; grabs the gamepad, tracks fn (BTN_MODE) state,
  # and re-exports a virtual gamepad that RetroArch uses normally.
  gamepadHandler = pkgs.writeShellScript "gamepad-handler" ''
    find_dev() {
      for f in /sys/class/input/event*/device/name; do
        [ "$(cat "$f" 2>/dev/null)" = "$1" ] || continue
        num="''${f%/device/name}"; num="''${num##*/}"
        echo "/dev/input/$num"; return 0
      done
      return 1
    }

    PAD_DEV=$(find_dev "H700 Gamepad") || exit 1

    # Clear stale fn flag in case the service crashed while fn was held
    rm -f /tmp/fn-held

    exec ${pkgs.evsieve}/bin/evsieve \
      --input "$PAD_DEV" grab \
      --hook btn:%316:1 exec-shell="${pkgs.coreutils}/bin/touch /tmp/fn-held" \
      --hook btn:%316:0 exec-shell="${pkgs.coreutils}/bin/rm -f /tmp/fn-held" \
      --output
  '';

  # Isolated brightness writer — no input device fds, no connection to the
  # input subsystem. Reads "+1" or "-1" from a named pipe and writes to
  # sysfs. Keeping this in a separate process avoids the Allwinner H700
  # kernel deadlock triggered by concurrent gpio/backlight driver access.
  brightnessDaemon = pkgs.writeShellScript "brightness-daemon" ''
    PIPE=/tmp/brightness-cmd
    [ -p "$PIPE" ] || mkfifo "$PIPE"
    exec 3<>"$PIPE"  # hold both ends open so vol-handler's open() doesn't block

    # Read device path, max, and starting brightness once at startup.
    # We track cur ourselves afterwards — no cat subprocess in the hot path.
    bl=""
    for d in /sys/class/backlight/*/; do
      max=$(cat "$d/max_brightness" 2>/dev/null) || continue
      cur=$(cat "$d/brightness" 2>/dev/null) || continue
      bl="''${d%/}"
      break
    done
    [ -n "$bl" ] || exit 1

    while IFS= read -r delta <&3; do
      new=$((cur + delta * max / 10))
      [ "$new" -gt "$max" ] && new=$max
      [ "$new" -lt 1 ] && new=1
      echo "$new" > "$bl/brightness" 2>/dev/null
      cur=$new
    done
  '';

  # Vol/brightness input handler. Reads vol keys via evtest, sends UDP
  # commands to RetroArch for volume, and signals brightness-daemon via
  # named pipe for brightness (never writes sysfs directly).
  volHandler = pkgs.writeShellScript "vol-handler" ''
    trap ''' PIPE  # ignore SIGPIPE if brightness-daemon restarts

    find_dev() {
      for f in /sys/class/input/event*/device/name; do
        [ "$(cat "$f" 2>/dev/null)" = "$1" ] || continue
        num="''${f%/device/name}"; num="''${num##*/}"
        echo "/dev/input/$num"; return 0
      done
      return 1
    }

    VOL_DEV=$(find_dev "gpio-keys-volume") || exit 1

    # Wait for brightness-daemon to create the pipe, then open write end.
    # brightness-daemon holds both ends open so this open() won't block.
    while [ ! -p /tmp/brightness-cmd ]; do
      ${pkgs.coreutils}/bin/sleep 0.5
    done
    exec 3>/tmp/brightness-cmd

    do_vol_up()   { echo -n "VOLUME_UP"   > /dev/udp/127.0.0.1/55355 2>/dev/null || true; }
    do_vol_down() { echo -n "VOLUME_DOWN" > /dev/udp/127.0.0.1/55355 2>/dev/null || true; }

    # Send brightness command to daemon. Cooldown (5 ticks = 0.5s) prevents
    # back-to-back writes from simultaneous or rapid button presses.
    try_bright() {
      [ "$bright_cd" -ge 5 ] || return
      echo "$1" >&3 2>/dev/null && bright_cd=0 || true
    }

    vol_up_held=0
    vol_down_held=0
    bright_cd=5

    while true; do
      if IFS= read -r -t 0.1 line; then
        case "$line" in
          *KEY_VOLUMEUP*"value 1"*)
            vol_up_held=1
            if [ -e /tmp/fn-held ]; then try_bright 1; else do_vol_up; fi ;;
          *KEY_VOLUMEUP*"value 2"*)
            if [ -e /tmp/fn-held ]; then
              [ "$bright_cd" -lt 5 ] && bright_cd=$((bright_cd + 1))
              try_bright 1
            else
              do_vol_up
            fi ;;
          *KEY_VOLUMEUP*"value 0"*)
            vol_up_held=0 ;;
          *KEY_VOLUMEDOWN*"value 1"*)
            vol_down_held=1
            if [ -e /tmp/fn-held ]; then try_bright -1; else do_vol_down; fi ;;
          *KEY_VOLUMEDOWN*"value 2"*)
            if [ -e /tmp/fn-held ]; then
              [ "$bright_cd" -lt 5 ] && bright_cd=$((bright_cd + 1))
              try_bright -1
            else
              do_vol_down
            fi ;;
          *KEY_VOLUMEDOWN*"value 0"*)
            vol_down_held=0 ;;
        esac
      else
        [ $? -gt 128 ] || break  # EOF/error: exit, systemd will restart
        [ "$bright_cd" -lt 5 ] && bright_cd=$((bright_cd + 1))
        if [ "$vol_up_held" -eq 1 ]; then
          if [ -e /tmp/fn-held ]; then try_bright 1; else do_vol_up; fi
        elif [ "$vol_down_held" -eq 1 ]; then
          if [ -e /tmp/fn-held ]; then try_bright -1; else do_vol_down; fi
        fi
      fi
    done < <(${pkgs.evtest}/bin/evtest "$VOL_DEV" 2>/dev/null)
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

  hardware.uinput.enable = true; # allows non-root to create virtual input devices

  # Grabs the gamepad exclusively and re-exposes it as a virtual device.
  # Tracks fn (BTN_MODE) state via /tmp/fn-held for the vol-handler.
  systemd.services.gamepad-handler = {
    wantedBy = [ "multi-user.target" ];
    before = [ "cage.service" ];
    serviceConfig = {
      User = "alec";
      SupplementaryGroups = [ "input" "uinput" ];
      ExecStart = gamepadHandler;
      Restart = "always";
      RestartSec = "2s";
    };
  };

  # Writes brightness to sysfs in isolation — no input device fds.
  systemd.services.brightness-daemon = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "alec";
      SupplementaryGroups = [ "video" ];
      ExecStart = brightnessDaemon;
      Restart = "always";
      RestartSec = "1s";
    };
  };

  # Grabs the volume buttons and dispatches to vol or brightness-daemon.
  systemd.services.vol-handler = {
    wantedBy = [ "multi-user.target" ];
    after = [ "brightness-daemon.service" ];
    wants = [ "brightness-daemon.service" ];
    before = [ "cage.service" ];
    serviceConfig = {
      User = "alec";
      SupplementaryGroups = [ "input" ];
      ExecStart = volHandler;
      Restart = "always";
      RestartSec = "2s";
    };
  };

  # Ensure both input handlers have grabbed their devices and the virtual
  # gamepad exists before RetroArch scans for input devices.
  systemd.services.cage = {
    after = [ "gamepad-handler.service" "vol-handler.service" ];
    wants = [ "gamepad-handler.service" "vol-handler.service" ];
  };

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"

    # Hide the physical gamepad from RetroArch's joypad enumeration so it
    # uses the virtual device (created by gamepad-handler) as joypad index 0.
    SUBSYSTEM=="input", ATTRS{name}=="H700 Gamepad", \
      ENV{ID_INPUT_JOYSTICK}="", ENV{ID_INPUT_ACCELEROMETER}="", \
      ENV{ID_INPUT_KEY}="", ENV{ID_INPUT_KEYBOARD}=""
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
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
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

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" "gamemode" "bluetooth" "networkmanager" "video" "uinput" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  services.journald.extraConfig = "Storage=volatile"; # Extend SD card lifespan
}
