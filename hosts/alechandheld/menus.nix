{ pkgs, ... }:
let
  # ── Launcher libretro core (launcher_libretro.c) ─────────────────────────
  # Loading a .launch playlist entry writes its basename to /tmp/launch-request;
  # the session loop below picks it up and runs the real program.
  launcherCore = pkgs.stdenv.mkDerivation {
    pname = "libretro-launcher";
    version = "1.0";
    dontUnpack = true;
    buildPhase = "$CC -shared -fPIC -O2 -o launcher_libretro.so ${./launcher_libretro.c}";
    installPhase = "install -Dm755 launcher_libretro.so $out/lib/retroarch/cores/launcher_libretro.so";
  };

  # ── Launcher .launch marker files ───────────────────────────────────────
  launcherFiles = pkgs.runCommand "launcher-files" {} ''
    mkdir -p $out/share/retroarch/launchers
    touch $out/share/retroarch/launchers/portmaster.launch
  '';

  # ── Main session loop script ─────────────────────────────────────────────
  gameLauncher = pkgs.writeShellScript "game-launcher" ''
    export PATH=/run/current-system/sw/bin:$PATH
    # UID is not stable across installs — never hardcode /run/user/<uid>
    export XDG_RUNTIME_DIR="/run/user/$(id -u)"

    LAUNCHER_CORE="${launcherCore}/lib/retroarch/cores/launcher_libretro.so"
    LAUNCHERS_DIR="$HOME/.config/retroarch/launchers/ports"
    PORTS_PLAYLIST="$HOME/.config/retroarch/playlists/ports.lpl"

    # RetroArch's writable dirs live on the game card (retroarch.cfg, hm.nix)
    mkdir -p /mnt/AlecContent/retroarch/saves /mnt/AlecContent/retroarch/states \
             /mnt/AlecContent/retroarch/system /mnt/AlecContent/retroarch/remaps \
             /mnt/AlecContent/retroarch/screenshots

    # Scan /mnt/AlecContent/ports/*.sh and write a RetroArch playlist so
    # installed ports appear as direct launcher entries (no PortMaster UI needed).
    scan_ports() {
      mkdir -p "$LAUNCHERS_DIR"
      items=""
      for script in /mnt/AlecContent/ports/*.sh; do
        [ -f "$script" ] || continue
        name=$(basename "$script" .sh)
        launch_file="$LAUNCHERS_DIR/''${name}.launch"
        touch "$launch_file"
        esc_name=$(printf '%s' "$name" | sed 's/\\/\\\\/g; s/"/\\"/g')
        esc_launch=$(printf '%s' "$launch_file" | sed 's/\\/\\\\/g; s/"/\\"/g')
        items="''${items},{\"path\":\"''${esc_launch}\",\"label\":\"''${esc_name}\",\"core_path\":\"$LAUNCHER_CORE\",\"core_name\":\"Launcher\",\"crc32\":\"00000000|crc\",\"db_name\":\"ports.lpl\"}"
      done
      printf '{"version":"1.4","items":[%s]}\n' "''${items#,}" > "$PORTS_PLAYLIST"
    }

    # Wait for PipeWire to start, then sleep 3 s to let WirePlumber start and
    # finish restoring ALSA mixer state from its database.  If we run amixer
    # before WirePlumber finishes its restore it will override us with the
    # saved (off) state.
    for _i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15; do
      [ -S "$XDG_RUNTIME_DIR/pipewire-0" ] && break
      sleep 1
    done
    sleep 3
    ${pkgs.alsa-utils}/bin/amixer -D hw:0 cset numid=6 on,on > /dev/null 2>&1 || true

    while true; do
      printf '\033c'  # clear TTY so boot text doesn't show through
      scan_ports      # rebuild ports playlist from SD card before each RA launch
      rm -f /tmp/launch-request
      retroarch >/tmp/retroarch.log 2>&1 &
      RA_PID=$!
      # Block until a launch request appears (or RA exits on its own).
      # inotifywait can exit spuriously in the service context, so re-arm it
      # with a timeout — the file check on each pass makes missed events harmless.
      while kill -0 "$RA_PID" 2>/dev/null && [ ! -f /tmp/launch-request ]; do
        ${pkgs.inotify-tools}/bin/inotifywait -qq -t 5 -e close_write,moved_to \
          --include 'launch-request' /tmp || true
      done
      if [ -f /tmp/launch-request ]; then
        # RA eats a SIGTERM that lands during its core-unload transition
        # (the quit flag is lost when it falls back to the menu), so keep
        # signalling until it actually dies.
        for _i in 1 2 3 4 5 6 7 8 9 10; do
          kill "$RA_PID" 2>/dev/null || true
          sleep 0.3
          case "$(ps -o stat= -p "$RA_PID" 2>/dev/null)" in
            ""|Z*) break ;;
          esac
        done
        case "$(ps -o stat= -p "$RA_PID" 2>/dev/null)" in
          ""|Z*) ;;
          *) kill -9 "$RA_PID" 2>/dev/null || true ;;
        esac
      fi
      wait "$RA_PID" 2>/dev/null
      if [ -f /tmp/launch-request ]; then
        app=$(cat /tmp/launch-request)
        rm -f /tmp/launch-request
        case "$app" in
          portmaster)
            printf '\033c'
            # Give the kernel time to release DRM master after RetroArch exits
            sleep 1
            portmaster > /tmp/portmaster.log 2>&1
            ;;
          *)
            # Look for a matching port script on the SD card
            port_script=""
            for _p in \
              "/mnt/AlecContent/ports/''${app}.sh" \
              "/mnt/AlecContent/ports/''${app}/''${app}.sh"; do
              [ -f "$_p" ] && port_script="$_p" && break
            done
            if [ -n "$port_script" ]; then
              printf '\033c'
              sleep 1
              portmaster "$port_script" > /tmp/portmaster.log 2>&1
            else
              printf '[%s] unrecognised launch request: [%s]\n' "$(date -Iseconds)" "$app" >> /tmp/launcher.log
            fi
            ;;
        esac
      fi
    done
  '';
in {
  environment.systemPackages = [ launcherCore launcherFiles ];

  # Minimal PAM service — avoids the broken pam_lastlog2 module in the full
  # "login" stack while still creating a logind session for KMS/DRM access.
  security.pam.services.alechandheld.startSession = true;

  # ── alechandheld service (replaces cage.service) ─────────────────────────
  systemd.services.alechandheld = {
    description = "alechandheld";
    # after handheld-inputd so the virtual gamepad exists when RetroArch starts
    after     = [ "multi-user.target" "systemd-logind.service" "handheld-inputd.service" ];
    wants     = [ "systemd-logind.service" "handheld-inputd.service" ];
    wantedBy  = [ "multi-user.target" ];
    conflicts = [ "getty@tty1.service" "autovt@tty1.service" ];
    environment = {
      HOME             = "/home/alec";
      USER             = "alec";
      XDG_SEAT         = "seat0";
      XDG_VTNR         = "1";
      EGL_PLATFORM          = "gbm"; # KMS/GBM path for GLES on Mali GPU
      XDG_SESSION_TYPE      = "tty"; # logind session type; "drm" is not a valid value
    };
    serviceConfig = {
      Type           = "simple";
      User           = "alec";
      PAMName        = "alechandheld";
      TTYPath        = "/dev/tty1";
      TTYReset       = true;
      TTYVHangup     = true;
      StandardInput  = "tty";
      StandardOutput = "tty";
      StandardError  = "journal";
      UtmpIdentifier = "tty1";
      UtmpMode       = "user";
      ExecStart           = "${gameLauncher}";
      ExecStopPost        = "${pkgs.alsa-utils}/bin/amixer -D hw:0 cset numid=6 off,off";
      Restart             = "always";
      RestartSec          = 2;
      # No ambient caps — the game-launcher shell script runs unprivileged.
      # The bounding set must include the caps that setuid bwrap (/run/portmaster/bwrap)
      # needs: SYS_ADMIN for mount namespaces (no user-ns → LLVM/Panfrost works),
      # SETUID/SETGID to drop from eUID=0 to alec after sandbox setup, SETPCAP to
      # manipulate capability sets.  Children inherit the bounding set; without these
      # entries, permitted = all_caps ∩ ∅ = ∅ and bwrap's mount() calls fail EPERM.
      CapabilityBoundingSet = "CAP_SYS_ADMIN CAP_SETUID CAP_SETGID CAP_SETPCAP";
      AmbientCapabilities   = "";
    };
  };

  # ── RetroArch playlist (home-manager) ────────────────────────────────────
  home-manager.users.alec.xdg.configFile."retroarch/playlists/portmaster.lpl".text =
    builtins.toJSON {
      version = "1.4";
      items = [{
        path      = "${launcherFiles}/share/retroarch/launchers/portmaster.launch";
        label     = "Portmaster";
        core_path = "${launcherCore}/lib/retroarch/cores/launcher_libretro.so";
        core_name = "Launcher";
        crc32     = "00000000|crc";
        db_name   = "portmaster.lpl";
      }];
    };
}
