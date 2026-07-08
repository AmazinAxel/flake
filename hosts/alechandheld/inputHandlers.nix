{ pkgs, ... }:

let
  # Single evdev daemon for volume keys and FN+volume brightness (inputd.c).
  # Grabs the physical gamepad and re-emits it through a uinput clone so the
  # FN button can be swallowed while adjusting brightness; volume keys are
  # watched without grabbing.
  inputd = pkgs.runCommandCC "handheld-inputd" {} ''
    mkdir -p $out/bin
    $CC -O2 -Wall -Wextra -DPACTL='"${pkgs.pulseaudio}/bin/pactl"' \
      -o $out/bin/handheld-inputd ${./inputd.c}
  '';
in {
  systemd.services.handheld-inputd = {
    description = "Volume/brightness key daemon";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "alec";
      SupplementaryGroups = [ "input" "uinput" "video" ];
      ExecStart = "${inputd}/bin/handheld-inputd";
      Restart = "always";
      RestartSec = "2s";
    };
  };

  services.udev.extraRules = ''
    # Let the daemon (group video) write the backlight level
    ACTION=="add", SUBSYSTEM=="backlight", \
      RUN+="${pkgs.coreutils}/bin/chgrp video /sys/class/backlight/%k/brightness", \
      RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/backlight/%k/brightness"

    # Hide the PHYSICAL H700 Gamepad from joystick enumeration — it is grabbed
    # by handheld-inputd, so apps must use the uinput clone instead.  The clone
    # lives under /devices/virtual/... which is how the two are distinguished
    # (same name and IDs otherwise, so SDL GUIDs and button indices match).
    SUBSYSTEM=="input", ATTRS{name}=="H700 Gamepad", DEVPATH!="*/virtual/*", \
      ENV{ID_INPUT_JOYSTICK}="", ENV{ID_INPUT_ACCELEROMETER}="", \
      ENV{ID_INPUT_KEY}="", ENV{ID_INPUT_KEYBOARD}=""

    # Force the clone to always be tagged as a joystick — udev hwdb may
    # suppress ID_INPUT_JOYSTICK for virtual devices, breaking RetroArch's
    # udev input driver.
    SUBSYSTEM=="input", DEVPATH=="*/virtual/*", ATTRS{name}=="H700 Gamepad", \
      ENV{ID_INPUT_JOYSTICK}="1"
  '';
}
