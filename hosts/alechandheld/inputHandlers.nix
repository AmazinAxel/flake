{ pkgs, ... }:

let
  findDev = ''
    find_dev() {
      for f in /sys/class/input/event*/device/name; do
        [ "$(cat "$f" 2>/dev/null)" = "$1" ] || continue
        num="''${f%/device/name}"; num="''${num##*/}"
        echo "/dev/input/$num"; return 0
      done
      return 1
    }
  '';

  gamepadHandler = pkgs.writeShellScript "gamepad-handler" ''
    ${findDev}
    PAD_DEV=$(find_dev "H700 Gamepad") || exit 1
    rm -f /tmp/fn-held
    exec ${pkgs.evsieve}/bin/evsieve \
      --input "$PAD_DEV" grab \
      --hook btn:%316:1 exec-shell="${pkgs.coreutils}/bin/touch /tmp/fn-held" \
      --hook btn:%316:0 exec-shell="${pkgs.coreutils}/bin/rm -f /tmp/fn-held" \
      --output
  '';

  brightnessDaemon = pkgs.writeShellScript "brightness-daemon" ''
    PIPE=/tmp/brightness-cmd
    [ -p "$PIPE" ] || mkfifo "$PIPE"
    exec 3<>"$PIPE"
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

  volHandler = pkgs.writeShellScript "vol-handler" ''
    trap ''' PIPE
    ${findDev}
    VOL_DEV=$(find_dev "gpio-keys-volume") || exit 1

    while [ ! -p /tmp/brightness-cmd ]; do
      ${pkgs.coreutils}/bin/sleep 0.5
    done
    exec 3>/tmp/brightness-cmd

    vol()    { echo -n "$1" > /dev/udp/127.0.0.1/55355 2>/dev/null || true; }
    bright() {
      [ "$bright_cd" -lt 5 ] && bright_cd=$((bright_cd + 1))
      [ "$bright_cd" -ge 5 ] || return
      echo "$1" >&3 2>/dev/null && bright_cd=0 || true
    }
    act() { if [ -e /tmp/fn-held ]; then bright "$1"; else vol "$2"; fi; }

    bright_cd=5 vol_up=0 vol_dn=0

    while true; do
      if IFS= read -r -t 0.1 line; then
        case "$line" in
          *KEY_VOLUMEUP*"value 1"*)   vol_up=1; act 1 VOLUME_UP ;;
          *KEY_VOLUMEUP*"value 2"*)   act 1 VOLUME_UP ;;
          *KEY_VOLUMEUP*"value 0"*)   vol_up=0 ;;
          *KEY_VOLUMEDOWN*"value 1"*) vol_dn=1; act -1 VOLUME_DOWN ;;
          *KEY_VOLUMEDOWN*"value 2"*) act -1 VOLUME_DOWN ;;
          *KEY_VOLUMEDOWN*"value 0"*) vol_dn=0 ;;
        esac
      else
        [ $? -gt 128 ] || break
        if [ "$vol_up" -eq 1 ]; then act 1 VOLUME_UP
        elif [ "$vol_dn" -eq 1 ]; then act -1 VOLUME_DOWN
        fi
      fi
    done < <(${pkgs.evtest}/bin/evtest "$VOL_DEV" 2>/dev/null)
  '';
in {
  hardware.uinput.enable = true;

  systemd.services = {
    gamepad-handler = {
      wantedBy = [ "multi-user.target" ];
      #before = [ "cage.service" ];
      serviceConfig = {
        User = "alec";
        SupplementaryGroups = [ "input" "uinput" ];
        ExecStart = gamepadHandler;
        Restart = "always";
        RestartSec = "2s";
      };
    };

    brightness-daemon = {
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "alec";
        SupplementaryGroups = [ "video" ];
        ExecStart = brightnessDaemon;
        Restart = "always";
        RestartSec = "1s";
      };
    };

    vol-handler = {
      wantedBy = [ "multi-user.target" ];
      after = [ "brightness-daemon.service" ];
      wants = [ "brightness-daemon.service" ];
      #before = [ "cage.service" ];
      serviceConfig = {
        User = "alec";
        SupplementaryGroups = [ "input" ];
        ExecStart = volHandler;
        Restart = "always";
        RestartSec = "2s";
      };
    };

    dac-enable = {
      #description = "Enable H616 DAC output";
      wantedBy = [ "multi-user.target" ];
      after = [ "sound.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${pkgs.alsa-utils}/bin/amixer -D hw:0 cset numid=6 on,on";
        ExecStop = "${pkgs.alsa-utils}/bin/amixer -D hw:0 cset numid=6 off,off";
      };
    };
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
}
