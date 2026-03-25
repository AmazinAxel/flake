{ pkgs, ... }:

let
  # Virtual keyboard so cage always advertises WL_SEAT_CAPABILITY_KEYBOARD.
  # Without a keyboard device, SDL2's Wayland backend crashes on init (NULL
  # deref in xkbcommon setup) — even if only a gamepad is present.
  virtualKbdSrc = pkgs.writeText "virtual-kbd.c" ''
    #include <fcntl.h>
    #include <linux/uinput.h>
    #include <string.h>
    #include <unistd.h>
    #include <signal.h>
    static int ufd = -1;
    static void cleanup(int sig) {
      (void)sig;
      if (ufd >= 0) { ioctl(ufd, UI_DEV_DESTROY, 0); close(ufd); }
      _exit(0);
    }
    int main(void) {
      struct uinput_setup s;
      memset(&s, 0, sizeof(s));
      ufd = open("/dev/uinput", O_WRONLY | O_NONBLOCK);
      if (ufd < 0) return 1;
      ioctl(ufd, UI_SET_EVBIT, EV_KEY);
      ioctl(ufd, UI_SET_KEYBIT, KEY_A);
      strncpy(s.name, "Virtual Keyboard", UINPUT_MAX_NAME_SIZE - 1);
      s.id.bustype = BUS_VIRTUAL;
      s.id.vendor  = 0x1234;
      s.id.product = 0x0001;
      s.id.version = 1;
      ioctl(ufd, UI_DEV_SETUP, &s);
      ioctl(ufd, UI_DEV_CREATE);
      signal(SIGTERM, cleanup);
      signal(SIGINT,  cleanup);
      while (1) pause();
    }
  '';

  virtualKbd = pkgs.stdenv.mkDerivation {
    name = "virtual-kbd";
    dontUnpack = true;
    buildPhase = "$CC -O2 -o virtual-kbd ${virtualKbdSrc}";
    installPhase = "install -Dm755 virtual-kbd $out/bin/virtual-kbd";
  };

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

    vol() {
      echo -n "$1" > /dev/udp/127.0.0.1/55355 2>/dev/null || true
      case "$1" in
        VOLUME_UP)   ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5% 2>/dev/null || true ;;
        VOLUME_DOWN) ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5% 2>/dev/null || true ;;
      esac
    }
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
    virtual-keyboard = {
      description = "Virtual keyboard device for Wayland seat capability";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        User = "alec";
        SupplementaryGroups = [ "uinput" ];
        ExecStart = "${virtualKbd}/bin/virtual-kbd";
        Restart = "always";
        RestartSec = "2s";
      };
    };

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

    # Hide the PHYSICAL H700 Gamepad from joystick enumeration so apps use the
    # evsieve virtual device instead.  DEVPATH!="*/virtual/*" ensures we only
    # match the real hardware node — the virtual uinput device lives under
    # /devices/virtual/... and must stay visible (ID_INPUT_JOYSTICK intact)
    # so SDL2-based apps like PortMaster can see it as a joystick.
    SUBSYSTEM=="input", ATTRS{name}=="H700 Gamepad", DEVPATH!="*/virtual/*", \
      ENV{ID_INPUT_JOYSTICK}="", ENV{ID_INPUT_ACCELEROMETER}="", \
      ENV{ID_INPUT_KEY}="", ENV{ID_INPUT_KEYBOARD}=""
  '';
}
