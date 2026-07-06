{ pkgs, ... }:

let
  # Single evdev daemon for volume keys and FN+volume brightness (inputd.c).
  # Reads the gamepad and gpio-keys-volume devices without grabbing them, so
  # RetroArch/SDL keep seeing the physical "H700 Gamepad" directly — no
  # virtual clone device or udev hiding rules needed.
  inputd = pkgs.runCommandCC "handheld-inputd" {} ''
    mkdir -p $out/bin
    $CC -O2 -Wall -Wextra -DPACTL='"${pkgs.pulseaudio}/bin/pactl"' \
      -o $out/bin/handheld-inputd ${./inputd.c}
  '';
in {
  systemd.services.handheld-inputd = {
    description = "Volume/brightness key daemon";
    wantedBy = [ "multi-user.target" ];
    environment = {
      # pactl needs these to reach the PipeWire-pulse socket;
      # system services don't get XDG_RUNTIME_DIR automatically
      XDG_RUNTIME_DIR = "/run/user/1001";
      PULSE_SERVER    = "unix:/run/user/1001/pulse/native";
    };
    serviceConfig = {
      User = "alec";
      SupplementaryGroups = [ "input" "video" ];
      ExecStart = "${inputd}/bin/handheld-inputd";
      Restart = "always";
      RestartSec = "2s";
    };
  };

  # Let the daemon (group video) write the backlight level
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="backlight", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"
  '';
}
