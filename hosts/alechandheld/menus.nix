{ pkgs, lib, ... }:
let
  # ── Launcher libretro core (C) ──────────────────────────────────────────
  launcherCSrc = pkgs.writeText "launcher_libretro.c" ''
    #include <stdio.h>
    #include <string.h>
    #include <libgen.h>
    #include <stdint.h>
    #include <stddef.h>
    #include <stdbool.h>

    #define RETRO_API_VERSION 1
    #define RETRO_ENVIRONMENT_SHUTDOWN 7

    struct retro_game_info   { const char *path; const void *data; size_t size; const char *meta; };
    struct retro_system_info { const char *library_name; const char *library_version;
                               const char *valid_extensions; bool need_fullpath; bool block_extract; };
    struct retro_game_geometry { unsigned base_width, base_height, max_width, max_height; float aspect_ratio; };
    struct retro_system_av_info { struct retro_game_geometry geometry;
                                  struct { double fps; double sample_rate; } timing; };

    typedef void (*retro_environment_t)(unsigned, void*);
    typedef void (*retro_video_refresh_t)(const void*, unsigned, unsigned, size_t);
    typedef void (*retro_audio_sample_t)(int16_t, int16_t);
    typedef size_t (*retro_audio_sample_batch_t)(const int16_t*, size_t);
    typedef void (*retro_input_poll_t)(void);
    typedef int16_t (*retro_input_state_t)(unsigned, unsigned, unsigned, unsigned);

    static retro_environment_t env_cb;
    static char content_path[4096];

    void retro_set_environment(retro_environment_t cb) { env_cb = cb; }
    void retro_set_video_refresh(retro_video_refresh_t cb) {}
    void retro_set_audio_sample(retro_audio_sample_t cb) {}
    void retro_set_audio_sample_batch(retro_audio_sample_batch_t cb) {}
    void retro_set_input_poll(retro_input_poll_t cb) {}
    void retro_set_input_state(retro_input_state_t cb) {}
    void retro_init(void) { content_path[0] = 0; }
    void retro_deinit(void) {}
    unsigned retro_api_version(void) { return RETRO_API_VERSION; }
    void retro_get_system_info(struct retro_system_info *info) {
      *info = (struct retro_system_info){ .library_name = "Launcher", .library_version = "1.0",
                                          .valid_extensions = "launch", .need_fullpath = true };
    }
    void retro_get_system_av_info(struct retro_system_av_info *info) {
      *info = (struct retro_system_av_info){
        .geometry = { .base_width=320, .base_height=240, .max_width=320, .max_height=240,
                      .aspect_ratio=4.0f/3.0f },
        .timing   = { .fps=60.0, .sample_rate=44100.0 } };
    }
    void retro_set_controller_port_device(unsigned p, unsigned d) {}
    void retro_reset(void) {}
    bool retro_load_game(const struct retro_game_info *game) {
      if (game && game->path)
        strncpy(content_path, game->path, sizeof(content_path)-1);
      return true;
    }
    void retro_run(void) {
      if (!content_path[0]) return;
      FILE *f = fopen("/tmp/launch-request", "w");
      if (f) {
        char tmp[4096]; strncpy(tmp, content_path, sizeof(tmp)-1);
        char *base = basename(tmp);
        char *dot  = strrchr(base, '.');
        if (dot) *dot = 0;
        fputs(base, f); fclose(f);
      }
      content_path[0] = 0;
      env_cb(RETRO_ENVIRONMENT_SHUTDOWN, (void*)0);
    }
    size_t retro_serialize_size(void) { return 0; }
    bool retro_serialize(void *d, size_t s) { return false; }
    bool retro_unserialize(const void *d, size_t s) { return false; }
    void retro_cheat_reset(void) {}
    void retro_cheat_set(unsigned i, bool e, const char *c) {}
    bool retro_load_game_special(unsigned t, const struct retro_game_info *i, size_t n) { return false; }
    void retro_unload_game(void) {}
    unsigned retro_get_region(void) { return 0; }
    void *retro_get_memory_data(unsigned id) { return NULL; }
    size_t retro_get_memory_size(unsigned id) { return 0; }
  '';

  launcherCore = pkgs.stdenv.mkDerivation {
    pname = "libretro-launcher";
    version = "1.0";
    dontUnpack = true;
    buildPhase = "$CC -shared -fPIC -O2 -o launcher_libretro.so ${launcherCSrc}";
    installPhase = "install -Dm755 launcher_libretro.so $out/lib/retroarch/cores/launcher_libretro.so";
  };

  # ── Launcher .launch marker files ───────────────────────────────────────
  launcherFiles = pkgs.runCommand "launcher-files" {} ''
    mkdir -p $out/share/retroarch/launchers
    touch $out/share/retroarch/launchers/portmaster.launch
  '';

  # ── Main session loop script ─────────────────────────────────────────────
  gameLauncher = pkgs.writeShellScript "game-launcher" ''
    export PATH=${lib.makeBinPath [ pkgs.gamemode pkgs.cage ]}:/run/current-system/sw/bin:$PATH
    while true; do
      rm -f /tmp/launch-request
      cage -- gamemoderun retroarch &
      CAGE_PID=$!
      # Poll for a launch request; kill cage when one appears
      while kill -0 "$CAGE_PID" 2>/dev/null; do
        if [ -f /tmp/launch-request ]; then
          kill "$CAGE_PID"
          wait "$CAGE_PID" 2>/dev/null
          break
        fi
        sleep 0.2
      done
      wait "$CAGE_PID" 2>/dev/null
      if [ -f /tmp/launch-request ]; then
        app=$(cat /tmp/launch-request)
        rm -f /tmp/launch-request
        case "$app" in
          portmaster)
            cage -- portmaster > /tmp/portmaster.log 2>&1
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
    description = "Alechandheld Gaming Session (KMS/DRM)";
    after     = [ "multi-user.target" "gamepad-handler.service" "vol-handler.service" "virtual-keyboard.service" "systemd-logind.service" ];
    wants     = [ "systemd-logind.service" ];
    wantedBy  = [ "multi-user.target" ];
    # Prevent getty from racing for tty1 — without this the login prompt wins
    conflicts = [ "getty@tty1.service" "autovt@tty1.service" ];
    environment = {
      HOME             = "/home/alec";
      USER             = "alec";
      XDG_RUNTIME_DIR  = "/run/user/1001";
      XDG_SEAT         = "seat0";
      XDG_VTNR         = "1";
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
      Restart             = "always";
      RestartSec          = 2;
      # Drop all capabilities — cage uses libseat/logind (D-Bus) for device
      # access so no process capabilities are needed, and inherited caps break bwrap
      CapabilityBoundingSet = "";
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
