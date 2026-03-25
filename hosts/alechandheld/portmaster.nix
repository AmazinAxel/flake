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

    # Store ports in the user's home directory
    export directory="home/alec"

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
      # Audio
      alsa-lib
      openal
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

    extraBwrapArgs = [ "--bind" "/dev/tty0" "/dev/tty0" ];

    runScript = pkgs.writeShellScript "portmaster-run" ''
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
          (cd "$PMDIR" && unzip -q pylibs.zip)
        fi

        # Install AlecHandheld platform overrides
        cp ${alecHandheldMod} "$PMDIR/mod_AlecHandheld.txt"

        # Ports live here — create if absent
        mkdir -p /home/alec/ports

        # Remove old version markers, write new one
        rm -f "$PMDIR"/.nix-initialized-*
        touch "$PMDIR/.nix-initialized-${portmasterVersion}"
        echo "PortMaster initialised."
      fi

      # ── Launch ────────────────────────────────────────────────────────────
      export HOME=/home/alec
      export CFW_NAME=AlecHandheld
      export SDL_VIDEODRIVER=wayland

      cd "$PMDIR"
      exec bash PortMaster.sh
    '';
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
    # Ports directory (Stardew Valley, Balatro, etc. install here)
    "d /home/alec/ports                   0755 alec users -"
  ];
}
