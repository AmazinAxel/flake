{ pkgs, lib, ... }:
let
  portmasterVersion = "2026.03.09-2312";

  # Nintendo-layout mapping (A=east/confirm) for the handheld-inputd uinput
  # clone.  Two GUID spellings of the same device: SDL >= 2.26 includes a
  # crc16 of the name (f6a2) in bytes 2-3; older SDLs statically linked into
  # port binaries (gmloadernext, gptokeyb) leave them zero.
  sdlButtonMap = "H700 Gamepad,platform:Linux,a:b1,b:b0,x:b3,y:b2,back:b8,start:b9,leftshoulder:b4,rightshoulder:b5,lefttrigger:b6,righttrigger:b7,leftstick:b11,rightstick:b12,dpup:b13,dpdown:b14,dpleft:b15,dpright:b16,leftx:a0,lefty:a1,rightx:a2,righty:a3,";
  sdlControllerConfig = ''
    0000f6a2483730302047616d65706100,${sdlButtonMap}
    00000000483730302047616d65706100,${sdlButtonMap}'';

  portmasterZip = pkgs.fetchurl {
    url = "https://github.com/PortsMaster/PortMaster-GUI/releases/download/${portmasterVersion}/PortMaster.zip";
    hash = "sha256-AC0iqbSYWO/zYJ/PgOuOp1ucbPycY66gXDGJVlKS1KQ=";
  };

  # Unpack the release zip into the Nix store; first-run init copies it into
  # the writable state dir at /var/lib/portmaster/PortMaster.
  portmasterStore = pkgs.runCommand "portmaster-${portmasterVersion}-src" {
    nativeBuildInputs = [ pkgs.unzip ];
  } ''
    mkdir -p "$out"
    cd "$out"
    unzip ${portmasterZip}
  '';

  alecHandheldMod = pkgs.writeText "mod_AlecHandheld.txt" ''
    #!/bin/bash

    # ports on SD card
    export directory="mnt/AlecContent"

    # No sudo inside the sandbox
    export ESUDO=""
    export ESUDOKILL="-1"
    export ESUDOKILL2="-1"

    # Port scripts run `export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"`
    # with whatever control.txt's get_controls detected — clobbering the
    # environment set by the FHS run script (which is how Undertale ended up
    # with Xbox layout while pure-SDL games were fine).  This file is sourced
    # after control.txt, so redefine get_controls to force our mapping.
    get_controls() {
      ANALOGSTICKS=2
      LOWRES="N"
      DEVICE="0000f6a2483730302047616d65706100"
      param_device="alechandheld"
      sdl_controllerconfig="${sdlControllerConfig}"
      export SDL_GAMECONTROLLERCONFIG_FILE="$controlfolder/alec_controls.txt"
    }
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
        cache="/mnt/AlecContent/portmaster/squash-cache/$(basename "$source")"
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

  # Classic SDL2, built from source (nixpkgs' pkgs.SDL2 is now sdl2-compat, an
  # SDL3-based shim).  Port binaries that link libSDL2 dynamically — Undertale
  # and other gmloadernext GameMaker ports — got sdl2-compat's audio path,
  # which stutters badly on this CPU; games bundling real SDL2 (Love2D,
  # dotnet/FNA runtimes) were unaffected.  This goes first in targetPkgs so
  # /usr/lib/libSDL2-2.0.so.0 is the real thing.
  sdl2Classic = pkgs.stdenv.mkDerivation {
    pname = "SDL2-classic";
    version = "2.32.8";
    src = pkgs.fetchurl {
      url = "https://github.com/libsdl-org/SDL/releases/download/release-2.32.8/SDL2-2.32.8.tar.gz";
      hash = "sha256-DKg+nJsx4YKIx+yBEQjli6wfG7XsZXetOGgw6sUceH4=";
    };
    nativeBuildInputs = with pkgs; [ cmake pkg-config ];
    # kmsdrm video (libdrm+gbm via mesa), ALSA+Pulse audio, udev joysticks,
    # dbus for rtkit realtime audio threads.  No X11/Wayland on this device.
    # libglvnd: provides egl.pc — cmake silently disables KMSDRM without it
    buildInputs = with pkgs; [ alsa-lib libpulseaudio systemdLibs libdrm mesa libgbm libglvnd dbus ];
    cmakeFlags = [
      "-DSDL_X11=OFF"
      "-DSDL_WAYLAND=OFF"
      "-DSDL_KMSDRM=ON"
      "-DSDL_ALSA=ON"
      "-DSDL_PULSEAUDIO=ON"
      "-DSDL_HIDAPI_LIBUSB=OFF"
      # Link backends directly (SDL dlopens them by default; libdrm/libgbm
      # aren't in the sandbox's /usr/lib, so dlopen fails → "kmsdrm not
      # available" crash).  Direct DT_NEEDED entries resolve via the Nix
      # store RPATH regardless of the sandbox environment.
      "-DSDL_KMSDRM_SHARED=OFF"
      "-DSDL_ALSA_SHARED=OFF"
      "-DSDL_PULSEAUDIO_SHARED=OFF"
    ];
    # Only the runtime lib is needed; the dev files trip nixpkgs' absolute-path
    # check on SDL's .pc/.cmake templates (nixpkgs#144170)
    postInstall = "rm -rf $out/lib/cmake $out/lib/pkgconfig $out/bin";
  };

  # LLVM-free Mesa build.  Mesa 26's monolithic libgallium hard-links libLLVM,
  # and LLVM crashes in TLS init when dlopen'd late into a Mono process on this
  # Cortex-A53 (Stardew/Celeste SIGSEGV via gbm_create_device → libgallium →
  # libLLVM).  Building with -Dllvm=disabled removes the DT_NEEDED entirely;
  # Panfrost hardware acceleration is unaffected (Bifrost compiler ≠ LLVM).
  # The run script points LIBGL_DRIVERS_PATH/GBM_BACKENDS_PATH at this build.
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

  # bwrap must run setuid-root so it can create mount namespaces WITHOUT a user
  # namespace (user namespaces trigger the LLVM/Panfrost crash above).  NixOS
  # security.wrappers can't do this (its wrapper execs the real bwrap without
  # setresuid, so bwrap's is_setuid check fails), so a boot service installs a
  # chmod-4755 copy at /run/portmaster/bwrap and this shim redirects to it.
  setuidBwrap = pkgs.writeShellScriptBin "bwrap" ''
    exec /run/portmaster/bwrap "$@"
  '';

  # FHS environment so PortMaster's pre-compiled aarch64 binaries can run
  portmaster = (pkgs.buildFHSEnv.override { bubblewrap = setuidBwrap; }) {
    name = "portmaster";

    targetPkgs = pkgs: with pkgs; [
      # SDL2 stack — pugwash UI and most port games use SDL2.
      # sdl2Classic FIRST so /usr/lib/libSDL2-2.0.so.0 is real SDL2, not
      # sdl2-compat (see comment above — audio stutter in GameMaker ports).
      sdl2Classic
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
      # D-Bus system bus — rtkit lives here; without it game audio threads
      # can't get realtime priority and starve (stutter in GameMaker ports)
      "--bind" "/run/dbus" "/run/dbus"
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
      # All PortMaster state lives on the game card (the root fs is ephemeral)
      PMDIR="/mnt/AlecContent/portmaster/PortMaster"
      mkdir -p "$PMDIR" /mnt/AlecContent/portmaster/squash-cache \
               /mnt/AlecContent/home /mnt/AlecContent/ports /mnt/AlecContent/tools

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
      # Ensure helper scripts that ship with PortMaster are executable on every
      # launch (the first-run chmod block is gated on a version marker, so newly
      # added helpers in port releases would otherwise stay unexecutable).
      for f in batocera_say.sh muos_say.sh \
               PortMaster.sh pugwash harbourmaster oga_controls; do
        [ -f "$PMDIR/$f" ] && chmod +x "$PMDIR/$f" 2>/dev/null || true
      done

      # Replace PortMaster's ask_password with a no-op stub. The bundled script
      # calls systemd-ask-password, which inotify-watches the ask-password dir
      # under XDG_RUNTIME_DIR — that path doesn't exist inside the bwrap
      # sandbox, so the watch fails and the port script aborts. With ESUDO=""
      # no password is ever needed, so a stub is safe.
      # (printf, not a heredoc: an indented heredoc terminator is not
      # recognized by bash, and the unterminated heredoc used to swallow the
      # entire rest of this script — no game ever launched.)
      printf '#!/bin/sh\nexit 0\n' > "$PMDIR/ask_password"
      chmod +x "$PMDIR/ask_password"

      # Put mount/umount shims first so port scripts' squashfs mounts go
      # through squashfuse instead of mount(8) (which requires root).
      export PATH="${mountShimDir}/bin:$PATH"
      # Also expose the PortMaster dir on PATH so port scripts that call
      # `ask_password` (or other PM helpers) without a full path can find it.
      export PATH="$PMDIR:$PATH"
      # Game saves/configs (Balatro, love, Mono/FNA dotfiles…) all land on the
      # game card — the real home is on the ephemeral tmpfs root.
      export HOME=/mnt/AlecContent/home
      # Derive the runtime dir from the real UID — it is NOT stable across
      # installs (currently 1000; an old hardcoded 1001 silently broke audio).
      export XDG_RUNTIME_DIR="/run/user/$(id -u)"
      export PULSE_SERVER="unix:$XDG_RUNTIME_DIR/pulse/native"
      # Force SDL through PulseAudio so games follow the default sink (incl. Bluetooth).
      # Without this, SDL2 may pick the ALSA backend and bind directly to hw:0,
      # bypassing PipeWire's BT routing.
      export SDL_AUDIODRIVER=pulseaudio
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
      # Controller mapping — Nintendo layout (A=east/confirm, B=south) for ALL
      # SDL apps: PortMaster UI, gptokeyb, Love2D, gmloader, FNA/MonoGame.
      # Only the handheld-inputd uinput CLONE is mapped (zeroed input_id →
      # GUID 0000f6a2483730302047616d65706100; f6a2 = crc16 of the name).
      # The grabbed physical device (VID 0x484b PID 0x14df) is ignored outright:
      # it emits no events, and SDL's bundled DB entry for it has the wrong
      # layout — games binding it got inverted buttons (Undertale) or no input
      # at all (Stardew).  RetroArch is unaffected (raw udev indices, hm.nix).
      # Nintendo-layout mapping under both GUID spellings (see sdlButtonMap);
      # ignore the grabbed physical device so only the clone is a controller.
      # get_controls in mod_AlecHandheld.txt forces the same mapping for port
      # scripts that overwrite this env var.
      export SDL_GAMECONTROLLER_IGNORE_DEVICES="0x484b/0x14df"
      export SDL_GAMECONTROLLERCONFIG="${sdlControllerConfig}"
      # …and as a file, for port scripts that use SDL_GAMECONTROLLERCONFIG_FILE
      printf '%s\n' "$SDL_GAMECONTROLLERCONFIG" > "$PMDIR/alec_controls.txt"

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

      # Stardew Valley: borderless-windowed makes FNA use FULLSCREEN_DESKTOP so
      # its backbuffer matches the 640x480 KMS display (plain windowed mode
      # defaults to 1280x720 and clips to a corner of the screen).
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

  # PortMaster.sh checks /opt/system/Tools/PortMaster/ as one of its known
  # controlfolder locations — symlink it to the state dir on the game card.
  # (State/cache dirs themselves are mkdir'd by the run script so nothing
  # touches the automounted card at boot.)
  systemd.tmpfiles.rules = [
    "d /opt/system                  0755 root root -"
    "d /opt/system/Tools            0755 root root -"
    "L /opt/system/Tools/PortMaster -    -    -    - /mnt/AlecContent/portmaster/PortMaster"
  ];
}
