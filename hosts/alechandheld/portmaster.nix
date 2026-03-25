{ pkgs, lib, ... }:
let
  portmasterVersion = "2026.03.09-2312";

  portmasterZip = pkgs.fetchurl {
    url = "https://github.com/PortsMaster/PortMaster-GUI/releases/download/${portmasterVersion}/PortMaster.zip";
    hash = "sha256-AC0iqbSYWO/zYJ/PgOuOp1ucbPycY66gXDGJVlKS1KQ=";
  };

  # Unpack the release zip into the Nix store (read-only reference copy)
  portmasterStore = pkgs.runCommand "portmaster-${portmasterVersion}-src" {
    nativeBuildInputs = [ pkgs.unzip ];
  } ''
    mkdir -p "$out"
    cd "$out"
    unzip ${portmasterZip}
  '';

  # AlecHandheld platform mod — sourced automatically by PortMaster when CFW_NAME=AlecHandheld
  alecHandheldMod = pkgs.writeText "mod_AlecHandheld.txt" ''
    #!/bin/bash
    # AlecHandheld-specific PortMaster configuration
    # Auto-sourced by PortMaster.sh when CFW_NAME=AlecHandheld

    # Store ports on the SD card
    export directory="mnt/AlecContent"

    # No sudo — running as user alec
    export ESUDO=""
    export ESUDOKILL="-1"
    export ESUDOKILL2="-1"

    # Use Wayland (cage compositor)
    export SDL_VIDEODRIVER=wayland
  '';

  # Strip any file capabilities from bwrap — capabilities on the binary cause it to
  # abort when executed by an unprivileged user (user namespaces handle sandboxing instead)
  bubblewrapClean = pkgs.runCommand "bubblewrap-clean" {
    nativeBuildInputs = [ pkgs.libcap ];
  } ''
    mkdir -p $out/bin
    cp ${pkgs.bubblewrap}/bin/bwrap $out/bin/bwrap
    chmod +w $out/bin/bwrap
    setcap -r $out/bin/bwrap || true
  '';

  # FHS environment so PortMaster's pre-compiled aarch64 binaries can run
  portmaster = (pkgs.buildFHSEnv.override { bubblewrap = bubblewrapClean; }) {
    name = "portmaster";

    targetPkgs = pkgs: with pkgs; [
      # SDL2 stack — pugwash UI and most port games use SDL2
      SDL2
      SDL2_image
      SDL2_mixer
      SDL2_ttf
      # Python3 — pugwash and harbourmaster are Python scripts
      python3
      # Network — port downloads
      curl
      wget
      # Shell utilities used by port scripts
      bash
      coreutils
      gnused
      gawk
      findutils
      gnugrep
      # Archives
      zip
      unzip
      # Squashfs for PortMaster runtime packages (.squashfs runtimes)
      squashfuse
      # x86_64 emulation — Stardew Valley (Steam Linux build is x86_64)
      box64
      # Love2D engine — Balatro uses Love2D
      love
      # OpenGL ES / Mesa for games
      libGL
      # Wayland client libs — SDL2 loads these at runtime for Wayland backend
      wayland
      # Audio
      alsa-lib
      openal
      libvorbis
      libtheora
      flac
      libopus
      mpg123
      # Input (gptokeyb needs udev)
      udev
      # Image libs
      libpng
      libjpeg
      zlib
      # Fonts
      fontconfig
      freetype
    ];

    extraBwrapArgs = [
      # Wayland socket lives under /run/user — bwrap puts a tmpfs on /run so
      # we must explicitly expose it, otherwise SDL2 can't connect to cage
      "--bind" "/run/user" "/run/user"
      # udev socket — SDL2 joystick/gamecontroller subsystem calls udev_new()
      # which crashes (NULL deref) if /run/udev is missing inside the sandbox
      "--bind" "/run/udev" "/run/udev"
      # SD card — ports and game files live here
      "--bind" "/mnt" "/mnt"
      # tty0 access for PortMaster.sh console switching (best-effort)
      "--bind" "/dev/tty0" "/dev/tty0"
    ];

    runScript = pkgs.writeTextFile {
      name = "portmaster-run";
      executable = true;
      text = ''
        #!/bin/sh
      PMDIR="/var/lib/portmaster/PortMaster"

      # ── First-run initialisation ───────────────────────────────────────────
      if [ ! -f "$PMDIR/.nix-initialized-${portmasterVersion}" ]; then
        echo "Initializing PortMaster ${portmasterVersion}..."

        # Copy from read-only Nix store into writable state directory
        cp -r ${portmasterStore}/PortMaster/. "$PMDIR/"

        # Nix store files are read-only — make everything user-writable first
        chmod -R u+rw "$PMDIR"

        # Mark scripts and pre-compiled aarch64 binaries executable
        for f in \
          PortMaster.sh pugwash harbourmaster oga_controls mapper.py tasksetter \
          gptokeyb gptokeyb2 \
          7zzs.aarch64 sdl2imgshow.aarch64 sdl_resolution.aarch64 \
          innoextract.aarch64 astcenc.aarch64 xdelta3; do
          [ -f "$PMDIR/$f" ] && chmod +x "$PMDIR/$f"
        done

        # pylibs.zip bundles Python packages (exlibs/) and resources (pylibs/)
        # pugwash adds these to sys.path at startup
        if [ -f "$PMDIR/pylibs.zip" ]; then
          echo "Extracting Python libraries..."
          (cd "$PMDIR" && unzip -o -q pylibs.zip)
        fi

        # Install AlecHandheld platform overrides
        install -m 644 ${alecHandheldMod} "$PMDIR/mod_AlecHandheld.txt"

        # Ports live on the SD card
        mkdir -p /mnt/AlecContent/ports

        # Remove old version markers, write new one
        rm -f "$PMDIR"/.nix-initialized-*
        touch "$PMDIR/.nix-initialized-${portmasterVersion}"
        echo "PortMaster initialised."
      fi

      # ── Launch ────────────────────────────────────────────────────────────
      export HOME=/home/alec
      export SDL_VIDEODRIVER=wayland
      export SDL_JOYSTICK_HIDAPI=0
      export PYTHONFAULTHANDLER=1
      # Custom controller mapping for H700 Gamepad (Bus=0x0019 VID=0x484b PID=0x14df)
      # Maps physical labels: A(btn0)=east/back → SDL b, B(btn1)=south/confirm → SDL a
      # X(btn2)=north → SDL y, Y(btn3)=west → SDL x  (Nintendo layout)
      export SDL_GAMECONTROLLERCONFIG="190000004b480000df14000000010000,H700 Gamepad,platform:Linux,a:b1,b:b0,x:b3,y:b2,back:b8,start:b9,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,leftstick:b11,rightstick:b12,dpup:b13,dpdown:b14,dpleft:b15,dpright:b16,leftx:a0,lefty:a1,rightx:a3,righty:a4,"

      # Patch control.txt so PortMaster.sh reads CFW_NAME=AlecHandheld
      if [ -f "$PMDIR/control.txt" ]; then
        if grep -q "^CFW_NAME=" "$PMDIR/control.txt"; then
          sed -i "s/^CFW_NAME=.*/CFW_NAME=AlecHandheld/" "$PMDIR/control.txt"
        else
          echo "CFW_NAME=AlecHandheld" >> "$PMDIR/control.txt"
        fi
      else
        echo "CFW_NAME=AlecHandheld" > "$PMDIR/control.txt"
      fi

      # Always keep mod files current
      install -m 644 ${alecHandheldMod} "$PMDIR/mod_AlecHandheld.txt"
      # mod_.txt is sourced when CFW detection returns empty — belt-and-suspenders
      install -m 644 ${alecHandheldMod} "$PMDIR/mod_.txt"

      # Dump environment for debugging (remove once working)
      env | grep -E 'WAYLAND|SDL|XDG|DISPLAY' > /tmp/portmaster-bwrap-env.txt

      cd "$PMDIR"
      exec bash PortMaster.sh
      '';
    };
  };
in {
  environment.systemPackages = [ portmaster ];

  # Stub service so PortMaster's "systemctl restart oga_events.service" succeeds
  systemd.services.oga_events = {
    description = "OGA Events (AlecHandheld stub for PortMaster compatibility)";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.coreutils}/bin/true";
      RemainAfterExit = true;
    };
  };

  # ── Writable state directory for PortMaster ────────────────────────────────
  # PortMaster needs to write logs, download runtimes, install ports, etc.
  systemd.tmpfiles.rules = [
    "d /var/lib/portmaster                0755 alec users -"
    "d /var/lib/portmaster/PortMaster     0755 alec users -"
    # PortMaster.sh checks /opt/system/Tools/PortMaster/ as one of its known
    # controlfolder locations — symlink it to our writable state dir.
    "d /opt/system                        0755 root root  -"
    "d /opt/system/Tools                  0755 root root  -"
    "L /opt/system/Tools/PortMaster       -    -    -     - /var/lib/portmaster/PortMaster"
  ];
}
