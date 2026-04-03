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
  '';

  # mount/umount shims — port scripts call mount(8) to attach .squashfs runtimes.
  # These shims intercept squashfs mounts and extract to a persistent cache instead
  # of using FUSE mounts (which fail inside bwrap because user namespaces disable
  # setuid on fusermount3).  Cache persists across launches so extraction only
  # happens once per squashfs file.
  mountShim = pkgs.writeShellScript "mount" ''
    skip= source= target=
    for _a in "$@"; do
      if [ -n "$skip" ]; then skip=; continue; fi
      case "$_a" in
        -o|-t|-T|-L) skip=yes ;;
        -*)          ;;
        *) if   [ -z "$source" ]; then source="$_a"
           elif [ -z "$target" ]; then target="$_a"
           fi ;;
      esac
    done
    case "$source" in
      *.squashfs|*.sqsh|*.sfs)
        cache="/var/lib/portmaster/squash-cache/$(basename "$source")"
        if [ ! -f "$cache/.ok" ]; then
          rm -rf "$cache"
          mkdir -p "$cache"
          unsquashfs -f -d "$cache" "$source" >/dev/null 2>&1 && touch "$cache/.ok"
        fi
        # After extracting a love runtime, symlink libtheoradec.so.1 into the
        # runtime dir so love.aarch64 (DT_RPATH=$ORIGIN) finds it.  Do this
        # here — after extraction but before the port script launches the binary
        # — to avoid the race where runScript symlinks run before runtimes exist.
        case "$source" in *love_*)
          for _p in /usr/lib/libtheoradec.so.1 /usr/lib/aarch64-linux-gnu/libtheoradec.so.1; do
            [ -f "$_p" ] || continue
            [ -e "$cache/libtheoradec.so.1" ] || ln -sf "$_p" "$cache/libtheoradec.so.1"
            break
          done
        esac
        # Point target at the cached extraction (no FUSE, no mount syscall needed)
        rm -rf "$target"
        ln -sf "$cache" "$target"
        exit 0 ;;
    esac
    exit 0
  '';

  umountShim = pkgs.writeShellScript "umount" ''
    for _a in "$@"; do
      case "$_a" in
        -*) ;;
        # If target is a symlink to our cache, just remove the symlink; keep the cache
        *)  [ -L "$_a" ] && rm -f "$_a" 2>/dev/null || fusermount -u "$_a" 2>/dev/null
            exit 0 ;;
      esac
    done
    exit 0
  '';

  mountShimDir = pkgs.runCommand "mount-shims-dir" {} ''
    mkdir -p $out/bin
    ln -s ${mountShim} $out/bin/mount
    ln -s ${umountShim} $out/bin/umount
  '';

  # Mesa 26 ships a single monolithic libgallium-*.so that all DRI drivers
  # (panfrost, swrast, etc.) link against.  libgallium has libLLVM.so as a hard
  # DT_NEEDED for its llvmpipe/draw-llvm path.  On Cortex-A53 (ARMv8.0-A),
  # LLVM 21.x crashes during TLS initialization when dlopen'd late into a Mono
  # process (Stardew Valley / MonoGame) — SIGSEGV in mono code during
  # gbm_create_device → libdril_dri.so → libgallium → libLLVM.
  #
  # Fix: build a copy of Mesa with -Dllvm=disabled so libgallium has no LLVM
  # DT_NEEDED.  GBM_BACKENDS_PATH redirects libgbm's backend (dri_gbm.so) to the
  # LLVM-free version; LIBGL_DRIVERS_PATH redirects EGL/GL DRI driver search.
  # Panfrost hardware acceleration is preserved: Bifrost shader compiler is
  # independent of LLVM.
  mesaNoLLVM = pkgs.mesa.overrideAttrs (old: {
    # mesa-clc=system: provide pre-built mesa_clc/vtn_bindgen2 from the LLVM-enabled
    # mesa so panfrost can use them without needing LLVM in the build itself.
    # With rusticl disabled, mesa-clc=system sets with_clc=false → LLVM not required.
    nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.mesa.cross_tools ];
    # All optional outputs must exist even if empty; moveToOutput is a no-op when
    # the source files don't exist (-Dtools=, rusticl disabled, no spirv2dxil).
    postInstall = "mkdir -p $cross_tools $spirv2dxil $opencl\n" + (old.postInstall or "");
    # postFixup unconditionally runs patchelf on libRusticlOpenCL.so, which doesn't
    # exist when rusticl is disabled.  Strip that reference out.
    postFixup = builtins.replaceStrings
      [" $opencl/lib/libRusticlOpenCL.so"]
      [""]
      (old.postFixup or "");
    mesonFlags =
      (lib.filter (f:
        # Drop all LLVM-dependent features and options renamed/removed in Mesa 26
        !lib.hasPrefix "-Dllvm=" f &&
        !lib.hasPrefix "-Dteflon=" f &&
        !lib.hasPrefix "-Dgallium-rusticl=" f &&
        !lib.hasPrefix "-Dgallium-rusticl-enable-drivers=" f &&
        !lib.hasPrefix "-Dintel-rt=" f &&
        !lib.hasPrefix "-Dgallium-va=" f &&
        !lib.hasPrefix "-Dgallium-vdpau=" f &&   # removed in Mesa 26
        !lib.hasPrefix "-Dgallium-xa=" f &&
        !lib.hasPrefix "-Damdgpu-virtio=" f &&
        !lib.hasPrefix "-Dgallium-drivers=" f && # replaced below (remove llvmpipe)
        !lib.hasPrefix "-Dvulkan-drivers=" f &&  # replaced below (minimal set)
        !lib.hasPrefix "-Dvulkan-layers=" f &&   # drop intel-nullhw etc
        !lib.hasPrefix "-Dtools=" f &&
        !lib.hasPrefix "-Dmesa-clc=" f &&
        !lib.hasPrefix "-Dinstall-mesa-clc=" f &&
        !lib.hasPrefix "-Dinstall-precomp-compiler=" f &&
        !lib.hasPrefix "-Dclang-libdir=" f
      ) (old.mesonFlags or []))
      ++ [
        "-Dllvm=disabled"
        # system: use pre-built mesa_clc binary; with rusticl=false → with_clc=false → no LLVM needed
        "-Dmesa-clc=system"
        "-Dteflon=false"
        "-Dgallium-rusticl=false"
        "-Dintel-rt=disabled"
        "-Dgallium-va=disabled"
        "-Damdgpu-virtio=false"
        # panfrost (hardware, Bifrost compiler) + softpipe (pure-C SW, no LLVM)
        "-Dgallium-drivers=panfrost,softpipe"
        # Panfrost Vulkan (no LLVM runtime dep; CLC handled via system mesa_clc above)
        "-Dvulkan-drivers=panfrost"
        "-Dtools="
        "-Dinstall-mesa-clc=false"
        "-Dinstall-precomp-compiler=false"
      ];
  });

  # bwrap needs to run setuid so it can create mount namespaces WITHOUT a user
  # namespace.  User namespaces trigger an LLVM/Panfrost crash on this AArch64
  # system.  The NixOS security.wrappers setuid trick doesn't work because that
  # wrapper calls execve(real_bwrap) without setresuid, so the real bwrap starts
  # with rUID=eUID=1001 and bwrap's is_setuid check returns false.
  #
  # Solution: a root-owned oneshot service copies bwrap to /run/portmaster/bwrap
  # and sets chmod 4755 (setuid root) directly on the binary.  /run is a tmpfs
  # that supports suid, so Linux applies the setuid bit, giving bwrap eUID=0
  # (is_setuid=true) → privileged mode → no user namespace → LLVM works.
  #
  # The shell-script shim below is what buildFHSEnv calls; it just redirects to
  # the runtime-installed setuid binary.
  setuidBwrap = pkgs.writeShellScriptBin "bwrap" ''
    exec /run/portmaster/bwrap "$@"
  '';

  # FHS environment so PortMaster's pre-compiled aarch64 binaries can run
  portmaster = (pkgs.buildFHSEnv.override { bubblewrap = setuidBwrap; }) {
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
      # unsquashfs extracts runtimes to a cache dir (FUSE mounts fail in bwrap)
      squashfsTools
      # x86_64 emulation — Stardew Valley (Steam Linux build is x86_64)
      box64
      # Love2D engine — Balatro uses Love2D
      love
      # FFmpeg 4.x — gmloadernext.aarch64 (GameMaker runner used by Deltarune etc.)
      # links against libavcodec.so.58 which is the FFmpeg 4.x soname
      ffmpeg_4
      # OpenGL ES / Mesa for games
      libGL
      # Audio
      alsa-lib
      libpulseaudio  # PulseAudio client — SDL2 uses this to connect to PipeWire-pulse
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
      # 2D graphics — love.aarch64 bundles in ports link against libcairo
      cairo
      # XML parsing — love.aarch64 and some ports need libexpat
      expat
      # libuuid — love.aarch64 and some ports link against libuuid
      util-linux
    ];

    extraBwrapArgs = [
      # PulseAudio/PipeWire socket lives under /run/user — bwrap puts a tmpfs
      # on /run so we must explicitly expose it
      "--bind" "/run/user" "/run/user"
      # udev socket — SDL2 joystick/gamecontroller subsystem calls udev_new()
      # which crashes (NULL deref) if /run/udev is missing inside the sandbox
      "--bind" "/run/udev" "/run/udev"
      # Input devices — must use --dev-bind (not --bind) for character devices;
      # plain --bind mounts the directory but blocks open() on device nodes
      "--dev-bind" "/dev/input" "/dev/input"
      # DRI nodes — SDL2 kmsdrm backend needs these to open the display
      "--dev-bind" "/dev/dri" "/dev/dri"
      # ALSA sound devices — needed for audio fallback and SDL2_mixer
      "--dev-bind" "/dev/snd" "/dev/snd"
      # Map /dev/tty0 to /dev/null inside the sandbox.
      # SDL2 KMS/DRM opens tty0 for VT management (KDSETMODE, VT_SETMODE ioctls).
      # With a real TTY here, SDL2 briefly closes and reopens fd 0 as part of VT
      # ownership transfer, causing a mono_fdhandle_insert duplicate fd 0 abort in
      # any Mono game (Celeste, etc.) that opens a file during SDL2 init.
      # Mapping to /dev/null makes all TTY ioctls return ENOTTY (SDL2 handles this
      # gracefully); KMS/DRM display still works via /dev/dri/card0 unchanged.
      "--dev-bind" "/dev/null" "/dev/tty0"
      # FUSE device — required for squashfuse to mount .squashfs runtime archives
      "--dev-bind" "/dev/fuse" "/dev/fuse"
      # uinput — gptokeyb creates a virtual keyboard/mouse via /dev/uinput.
      # Without this bind, gptokeyb can't open uinput inside bwrap and produces
      # no output events, so gamepad buttons do nothing in port scripts.
      "--dev-bind" "/dev/uinput" "/dev/uinput"
      # PortMaster state directory
      "--bind" "/var/lib/portmaster" "/var/lib/portmaster"
      # /opt symlink (PortMaster.sh checks /opt/system/Tools/PortMaster)
      "--bind" "/opt" "/opt"
      # SD card — ports and game files live here
      "--bind" "/mnt" "/mnt"
      # harbourmaster detects device as rg35xx-h and expects ports at /roms/ports.
      # Create a symlink inside the sandbox so those paths resolve to our SD card.
      "--symlink" "/mnt/AlecContent" "/roms"
    ];

    runScript = pkgs.writeTextFile {
      name = "portmaster-run";
      executable = true;
      text = ''
        #!/bin/sh
      PMDIR="/var/lib/portmaster/PortMaster"

      # ── First-run initialisation ───────────────────────────────────────────
      if [ ! -f "$PMDIR/.nix-initialized-${portmasterVersion}" ]; then
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
          (cd "$PMDIR" && unzip -o -q pylibs.zip)
        fi

        # Install AlecHandheld platform overrides
        install -m 644 ${alecHandheldMod} "$PMDIR/mod_AlecHandheld.txt"

        # Ports live on the SD card
        mkdir -p /mnt/AlecContent/ports

        rm -f "$PMDIR"/.nix-initialized-*
        touch "$PMDIR/.nix-initialized-${portmasterVersion}"
      fi

      # ── Launch ────────────────────────────────────────────────────────────
      # Put mount/umount shims first so port scripts' squashfs mounts go
      # through squashfuse instead of mount(8) (which requires root).
      export PATH="${mountShimDir}/bin:$PATH"
      export HOME=/home/alec
      export XDG_RUNTIME_DIR=/run/user/1001
      export PULSE_SERVER=unix:/run/user/1001/pulse/native
      export SDL_VIDEODRIVER=kmsdrm
      export SDL_VIDEO_DRIVER=kmsdrm
      export LIBSEAT_BACKEND=direct
      export SDL_JOYSTICK_HIDAPI=0
      export PYTHONFAULTHANDLER=1
      # Disable SDL vsync so Love2D/port games aren't capped at 30fps on slow GPU
      export SDL_VIDEO_SYNC_TO_VBLANK=0
      # LLVM-free Mesa — see mesaNoLLVM comment above for why.
      # LIBGL_DRIVERS_PATH: EGL/GL DRI driver search; GBM_BACKENDS_PATH: GBM backend.
      export LIBGL_DRIVERS_PATH=${mesaNoLLVM}/lib/dri
      export GBM_BACKENDS_PATH=${mesaNoLLVM}/lib/gbm
      # Pre-compiled handheld binaries (love.aarch64, gptokeyb, etc.) may have
      # been built against Debian multiarch paths.  Expose both so they find libs
      # whether they use /usr/lib or /usr/lib/aarch64-linux-gnu RPATH.
      export LD_LIBRARY_PATH=/usr/lib:/usr/lib/aarch64-linux-gnu''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
      # Controller mappings for H700 Gamepad — two entries:
      #   1. Physical device  (Bus=0x0019 VID=0x484b PID=0x14df)
      #   2. Virtual device   (Bus=0x0006 BUS_VIRTUAL — created by evsieve; same VID/PID)
      # SDL convention: A=South(confirm), B=East(cancel), X=West, Y=North.
      # Physical evdev indices: b0=East, b1=South, b2=North, b3=West.
      # Therefore: a:b1, b:b0, x:b3, y:b2.
      # RetroArch uses raw udev button indices (hm.nix) so this only affects SDL apps
      # (PortMaster UI, gptokeyb2, Love2D, etc).
      # SDL GUIDs for the H700 Gamepad, confirmed via sdl-jstest at runtime.
      # SDL2 2.26+ GUID format: bus(LE16) | crc16(name)(LE16) | vendor... or name bytes
      # Virtual device (evsieve output, bus=0, vendor=0, product=0):
      #   GUID = 0000 f6a2 "H700 Gamepa\0" = 0000f6a2483730302047616d65706100
      # Physical device (bus=0x0019, vendor=0x484b, product=0x14df):
      #   GUID = 1900 f6a2 4b48 0000 df14 0000 0001 0000 = 1900f6a24b480000df14000000010000
      # Mapping confirmed by sdl-jstest auto-detection (BTN_SOUTH=b0, axes a0-a3).
      # Both entries included: physical device may be visible via /dev/input/js* even
      # though our udev rule suppresses its ID_INPUT_JOYSTICK via evdev enumeration.
      export SDL_GAMECONTROLLERCONFIG="0000f6a2483730302047616d65706100,H700 Gamepad,platform:Linux,a:b1,b:b0,x:b3,y:b2,back:b8,start:b9,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,leftstick:b11,rightstick:b12,dpup:b13,dpdown:b14,dpleft:b15,dpright:b16,leftx:a0,lefty:a1,rightx:a2,righty:a3,
1900f6a24b480000df14000000010000,H700 Gamepad,platform:Linux,a:b1,b:b0,x:b3,y:b2,back:b8,start:b9,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,leftstick:b11,rightstick:b12,dpup:b13,dpdown:b14,dpleft:b15,dpright:b16,leftx:a0,lefty:a1,rightx:a2,righty:a3,"

      # Patch control.txt so PortMaster.sh reads CFW_NAME=AlecHandheld.
      patch_ctrl() {
        local key="$1" val="$2"
        if grep -q "^$key=" "$PMDIR/control.txt" 2>/dev/null; then
          sed -i "s|^$key=.*|$key=$val|" "$PMDIR/control.txt"
        else
          echo "$key=$val" >> "$PMDIR/control.txt"
        fi
      }
      [ -f "$PMDIR/control.txt" ] || touch "$PMDIR/control.txt"
      patch_ctrl CFW_NAME AlecHandheld

      # Stardew Valley: force borderless windowed so FNA uses SDL_WINDOW_FULLSCREEN_DESKTOP.
      # SDL2 kmsdrm returns the display size (640x480) from SDL_GetWindowSize() in this mode,
      # so FNA sets PreferredBackBufferWidth/Height=640x480 and rendering matches the KMS buffer.
      # Windowed mode (windowMode:0) skips this and uses FNA's internal 1280x720 default,
      # clipping to the bottom-left corner of a 1280x720 canvas on a 640x480 display.
      _prefs="/mnt/AlecContent/ports/stardewvalley/savedata/startup_preferences"
      if [ -d "/mnt/AlecContent/ports/stardewvalley" ]; then
        mkdir -p "$(dirname "$_prefs")"
        chmod 644 "$_prefs" 2>/dev/null || true
        cat > "$_prefs" <<'XMLEOF'
<?xml version="1.0" encoding="utf-8"?>
<StartupPreferences>
  <playerLimit>-1</playerLimit>
  <windowWidth>640</windowWidth>
  <windowHeight>480</windowHeight>
  <fullscreen>false</fullscreen>
  <windowedBorderless>true</windowedBorderless>
  <windowMode>1</windowMode>
</StartupPreferences>
XMLEOF
      fi

      # Always keep mod files current
      install -m 644 ${alecHandheldMod} "$PMDIR/mod_AlecHandheld.txt"
      # mod_.txt is sourced when CFW detection returns empty — belt-and-suspenders
      install -m 644 ${alecHandheldMod} "$PMDIR/mod_.txt"

      # Disable gl4es for AlecHandheld — Panfrost provides native GLES 3.1 directly.
      # The pre-compiled gl4es bundled with ports crashes on Panfrost during EGL
      # extension probing (GetHardwareExtensions segfault).  With LIBGL_ES unset,
      # port scripts skip setting SDL_VIDEO_GL_DRIVER to gl4es and use system Mesa.
      # Port scripts source libgl_\$\{CFW_NAME}.txt; with empty CFW_NAME → libgl_.txt
      printf 'export LIBGL_ES=\n' > "$PMDIR/libgl_.txt"
      printf 'export LIBGL_ES=\n' > "$PMDIR/libgl_AlecHandheld.txt"

      # Port scripts look for runtimes at $controlfolder/libs/ (=/var/lib/portmaster/PortMaster/libs/)
      # but PortMaster downloads them to the SD card at /mnt/AlecContent/tools/PortMaster/libs/.
      # Migrate any files that landed in the state dir, then symlink so both paths resolve.
      mkdir -p /mnt/AlecContent/tools/PortMaster/libs
      if [ -d "$PMDIR/libs" ] && [ ! -L "$PMDIR/libs" ]; then
        cp -rn "$PMDIR/libs/." /mnt/AlecContent/tools/PortMaster/libs/ 2>/dev/null || true
        rm -rf "$PMDIR/libs"
        ln -sf /mnt/AlecContent/tools/PortMaster/libs "$PMDIR/libs"
      elif [ ! -e "$PMDIR/libs" ]; then
        ln -sf /mnt/AlecContent/tools/PortMaster/libs "$PMDIR/libs"
      fi

      # love.aarch64 uses DT_RPATH=$ORIGIN — symlink libtheoradec into each
      # love runtime dir so the binary finds it without LD_LIBRARY_PATH lookup.
      link_theora() {
        local _lib= _ldir
        for _p in /usr/lib/libtheoradec.so.1 /usr/lib/aarch64-linux-gnu/libtheoradec.so.1; do
          [ -f "$_p" ] && _lib="$_p" && break
        done
        [ -n "$_lib" ] || return
        for _ldir in "$PMDIR"/runtimes/love_*/; do
          [ -d "$_ldir" ] && [ ! -e "$_ldir/libtheoradec.so.1" ] && \
            ln -sf "$_lib" "$_ldir/libtheoradec.so.1"
        done
      }
      link_theora

      # Balatro zoom: pre-set scale to 1.5x on first run so the 640x480 screen
      # is legible.  Balatro (Love2D) stores settings in ~/.local/share/Balatro/1/settings.jkr.
      # Only writes the file if it doesn't already exist, preserving any in-game changes.
      _balatro_save="$HOME/.local/share/Balatro"
      if [ -d "/mnt/AlecContent/ports/balatro" ] && [ ! -f "$_balatro_save/1/settings.jkr" ]; then
        mkdir -p "$_balatro_save/1"
        printf 'return {["scale"]=1.5,["language"]="en_us",["screenshake"]="High",["colourblind"]="Off",["shadows"]="On"}\n' \
          > "$_balatro_save/1/settings.jkr"
      fi

      # If a port script was passed as an argument, run it directly inside
      # this FHS environment instead of launching the PortMaster UI.
      if [ -n "$1" ]; then
        # Re-run in case runtimes were downloaded after startup
        link_theora
        cd "$(dirname "$1")"
        # Redirect stdin to /dev/null to prevent Mono games from inheriting the
        # service's TTY as fd 0.  Mono registers fd 0 in its fdhandle table during
        # init; if it's a TTY the table can get a duplicate entry which corrupts
        # subsequent file operations and triggers a fatal abort().
        exec bash "$1" </dev/null
      fi

      cd "$PMDIR"
      exec bash PortMaster.sh
      '';
    };
  };
in {
  environment.systemPackages = [ portmaster ];

  # Install a setuid-root bwrap binary on the tmpfs /run so PortMaster's FHS
  # sandbox can enter privileged mode without a user namespace.
  systemd.services.portmaster-bwrap-setup = {
    wantedBy  = [ "alechandheld.service" ];
    before    = [ "alechandheld.service" ];
    serviceConfig = {
      Type             = "oneshot";
      RemainAfterExit  = true;
      ExecStart = pkgs.writeShellScript "portmaster-bwrap-setup" ''
        install -d -m 755 /run/portmaster
        install -m 4755 -o root -g root ${pkgs.bubblewrap}/bin/bwrap /run/portmaster/bwrap
      '';
    };
  };

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
    "d /var/lib/portmaster/squash-cache   0755 alec users -"
    # PortMaster.sh checks /opt/system/Tools/PortMaster/ as one of its known
    # controlfolder locations — symlink it to our writable state dir.
    "d /opt/system                        0755 root root  -"
    "d /opt/system/Tools                  0755 root root  -"
    "L /opt/system/Tools/PortMaster       -    -    -     - /var/lib/portmaster/PortMaster"
    # SD card content directory — ensure alec owns it so PortMaster can write ports/
    "d /mnt/AlecContent                   0755 alec users -"
    "d /mnt/AlecContent/ports             0755 alec users -"
    "d /mnt/AlecContent/tools             0755 alec users -"
  ];
}
