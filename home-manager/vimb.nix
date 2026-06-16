{ pkgs, lib, config, osConfig, ... }:
let
  # this file is vibecoded garbage and needs to be upstreamed. do not reference

  # System dark-mode follows xdg-desktop-portal's color-scheme via a tiny patch
  # (vimb doesn't natively read it). Written to disk via writeText (not heredocs)
  # because Nix ''-string indent-stripping breaks `<<EOF`-style terminators.
  vimbDarkModeHeader = pkgs.writeText "vimb_dark_mode.h" ''
    #pragma once
    #include <gtk/gtk.h>
    #include <gio/gio.h>

    static void vimb_apply_dark(gboolean dark) {
        GtkSettings *gs = gtk_settings_get_default();
        if (!gs) return;
        g_object_set(gs, "gtk-application-prefer-dark-theme", dark, NULL);
    }

    static void vimb_on_portal_setting_changed(GDBusConnection *c, const gchar *sender,
            const gchar *obj, const gchar *iface, const gchar *signal,
            GVariant *params, gpointer u) {
        const gchar *ns = NULL, *key = NULL; GVariant *value = NULL;
        g_variant_get(params, "(&s&sv)", &ns, &key, &value);
        if (g_strcmp0(ns, "org.freedesktop.appearance") == 0 &&
            g_strcmp0(key, "color-scheme") == 0) {
            vimb_apply_dark(g_variant_get_uint32(value) == 1);
        }
        if (value) g_variant_unref(value);
    }

    static guint32 vimb_query_portal_color_scheme(GDBusConnection *bus) {
        GVariant *res = g_dbus_connection_call_sync(bus,
            "org.freedesktop.portal.Desktop",
            "/org/freedesktop/portal/desktop",
            "org.freedesktop.portal.Settings", "Read",
            g_variant_new("(ss)", "org.freedesktop.appearance", "color-scheme"),
            G_VARIANT_TYPE("(v)"), G_DBUS_CALL_FLAGS_NONE, -1, NULL, NULL);
        if (!res) return 0;
        GVariant *vv = NULL; g_variant_get(res, "(v)", &vv);
        GVariant *inner = g_variant_is_of_type(vv, G_VARIANT_TYPE_VARIANT) ? g_variant_get_variant(vv) : g_variant_ref(vv);
        guint32 v = g_variant_get_uint32(inner);
        g_variant_unref(inner); g_variant_unref(vv); g_variant_unref(res);
        return v;
    }

    static void vimb_dark_mode_init(void) {
        GDBusConnection *bus = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, NULL);
        if (!bus) return;
        g_dbus_connection_signal_subscribe(bus,
            "org.freedesktop.portal.Desktop",
            "org.freedesktop.portal.Settings",
            "SettingChanged", "/org/freedesktop/portal/desktop",
            NULL, G_DBUS_SIGNAL_FLAGS_NONE,
            vimb_on_portal_setting_changed, NULL, NULL);
        vimb_apply_dark(vimb_query_portal_color_scheme(bus) == 1);
    }
  '';

  # Filter list ingredients. Fetched without a hash via `builtins.fetchurl` so
  # we don't have to chase the upstream every few hours. Requires `--impure`
  # evaluation, which this flake already uses.
  filterLists = lib.mapAttrs (_: url: builtins.fetchurl url) {
    easylist        = "https://easylist.to/easylist/easylist.txt";
    easyprivacy     = "https://easylist.to/easylist/easyprivacy.txt";
    ublock-filters  = "https://ublockorigin.github.io/uAssets/filters/filters.txt";
    ublock-badware  = "https://ublockorigin.github.io/uAssets/filters/badware.txt";
    ublock-privacy  = "https://ublockorigin.github.io/uAssets/filters/privacy.txt";
    ublock-unbreak  = "https://ublockorigin.github.io/uAssets/filters/unbreak.txt";
  };

  # uBO-bypass + ad-skipper userscript by TheRealJoelmatic (6 k★, MIT).
  # Loaded by `scripts.js` only on youtube.com (the userscript's IIFE checks
  # location internally; we ALSO wrap it so unrelated pages skip entirely).
  ytAdblockScript = builtins.fetchurl
    "https://raw.githubusercontent.com/TheRealJoelmatic/RemoveAdblockThing/main/Youtube-Ad-blocker-Reminder-Remover.user.js";

  # EasyList + EasyPrivacy + the uBO core filter set, concatenated into one
  # blob. ephy-uri-tester reads a single file at a time; this is the file.
  combinedFilters = pkgs.runCommand "wyebadblock-combined.txt" {} ''
    cat ${lib.concatMapStringsSep " " (n: filterLists.${n}) [
      "easylist" "easyprivacy"
      "ublock-filters" "ublock-badware" "ublock-privacy" "ublock-unbreak"
    ]} > $out
  '';

  # wyebadblock ported to webkitgtk-6.0. Upstream targets webkit2gtk-4.x; the
  # webextension-side renames `WebKitWebExtension` to `WebKitWebProcessExtension`
  # and switches headers/pkg-config. We ALSO hardcode the filter-list path to
  # the immutable nix store location of `combinedFilters` — WebKit 6 enforces
  # a sandbox on the web process (no API to disable in 6.0), which silently
  # remaps $HOME and breaks ephy-uri-tester's `$XDG_CONFIG_HOME/wyebadblock/
  # easylist.txt` lookup. /nix/store is bind-mounted into the sandbox for
  # libwebkitgtk dlopen, so it's reachable from the sandboxed wyebab too.
  wyebadblock = pkgs.stdenv.mkDerivation {
    pname = "wyebadblock";
    version = "unstable-2026-05-30-webkit6";
    src = builtins.fetchTarball
      "https://github.com/jun7/wyebadblock/archive/529a5eedafacca9cd4ba78bf15d3a2bb565b821a.tar.gz";
    nativeBuildInputs = [ pkgs.pkg-config ];
    buildInputs = [ pkgs.glib pkgs.webkitgtk_6_0 ];
    postPatch = ''
      substituteInPlace ab.c \
        --replace-fail '#include <webkit2/webkit-web-extension.h>' \
                       '#include <webkit/webkit-web-process-extension.h>' \
        --replace-fail 'static void pageinit(WebKitWebExtension *ex, WebKitWebPage *kp)' \
                       'static void pageinit(WebKitWebProcessExtension *ex, WebKitWebPage *kp)' \
        --replace-fail 'G_MODULE_EXPORT void webkit_web_extension_initialize_with_user_data(
		WebKitWebExtension *ex, const GVariant *v)' \
                       'G_MODULE_EXPORT void webkit_web_process_extension_initialize_with_user_data(
		WebKitWebProcessExtension *ex, const GVariant *v)'

      # BLOCK-only stderr diagnostic. Quiet on allowed requests so the log
      # isn't a wall of noise. Run `vimb 2>&1 | grep wyebab` while browsing —
      # you should see one line per blocked request. No output at all on a
      # page that ought to have ads means wyebab isn't being called.
      substituteInPlace ab.c \
        --replace-fail 'if (check(webkit_uri_request_get_uri(req),
				webkit_web_page_get_uri(kp))) return false;
	return true;' \
                       '{
		const char *u = webkit_uri_request_get_uri(req);
		if (check(u, webkit_web_page_get_uri(kp))) return false;
		g_printerr("[wyebab] BLOCK %s\n", u);
		return true;
	}'

      # Replace the XDG-based filter-list lookup with a fixed /nix/store path.
      # Falls back to the original XDG search only if the hardcoded file is
      # somehow missing (it can't be, since the path lives in the closure).
      substituteInPlace ab.c \
        --replace-fail 'static void init()
{
	DD(wyebad init)
	if (tryload(g_get_user_config_dir())) return;' \
                       'static void init()
{
	const char *hardpath = "${combinedFilters}";
	if (g_file_test(hardpath, G_FILE_TEST_EXISTS)) {
		filter_file = g_file_new_for_path(hardpath);
		tester = ephy_uri_tester_new("/foo/bar");
		initt = g_thread_new("init", inittcb, NULL);
		return;
	}
	if (tryload(g_get_user_config_dir())) return;'
    '';
    buildPhase = ''
      runHook preBuild
      $CC $CFLAGS -c -o librun.o wyebrun.c -fPIC \
        $(pkg-config --cflags --libs glib-2.0)
      # Absolute path baked in: WebKit's web process doesn't inherit the user's
      # PATH, so G_SPAWN_SEARCH_PATH against bare "wyebab" fails. $out is set
      # during buildPhase, so the store path lands in EXENAME.
      $CC $CFLAGS -o adblock.so ab.c librun.o -shared -fPIC \
        $(pkg-config --cflags --libs webkitgtk-web-process-extension-6.0 glib-2.0) \
        -DISEXT -DEXENAME="\"$out/bin/wyebab\""
      $CC $CFLAGS -o wyebab ab.c librun.o \
        $(pkg-config --cflags --libs glib-2.0 gio-2.0) \
        -DDIRNAME='"wyebadblock"' -DLISTNAME='"easylist.txt"'
      runHook postBuild
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 wyebab     $out/bin/wyebab
      install -Dm644 adblock.so $out/lib/wyebadblock/adblock.so
      runHook postInstall
    '';
  };

  filterLists = lib.mapAttrs (_: { url, ... }: builtins.fetchurl url) {
    ublock-filters  = { url = "https://ublockorigin.github.io/uAssets/filters/filters.txt"; };
    ublock-badware  = { url = "https://ublockorigin.github.io/uAssets/filters/badware.txt"; };
    ublock-privacy  = { url = "https://ublockorigin.github.io/uAssets/filters/privacy.txt"; };
    ublock-unbreak  = { url = "https://ublockorigin.github.io/uAssets/filters/unbreak.txt"; };
  };

  # wyebab only opens the single file named `easylist.txt` (LISTNAME), so
  # the additional lists are concatenated into one blob it reads as a whole.
  combinedFilters = pkgs.runCommand "wyebadblock-combined.txt" {} ''
    cat ${lib.concatMapStringsSep " " (n: filterLists.${n}) [
      # "easylist" "easyprivacy"
      "ublock-filters" "ublock-badware" "ublock-privacy" "ublock-unbreak"
    ]} > $out
  '';

  # Extract every cosmetic / element-hiding rule that ephy-uri-tester parses
  # from the combined list. The extension never applies these in-process;
  # vimb's user-stylesheet does — that gets us back the visibility-blocking
  # half of uBO's coverage.
  cosmeticStylesheet = pkgs.runCommand "vimb-adblock.css" {} ''
    ${wyebadblock}/bin/wyebab --css > $out
  '';

  vimb-master = (pkgs.vimb-unwrapped.override {
    gtk3 = pkgs.gtk4;
    webkitgtk_4_1 = pkgs.webkitgtk_6_0;
  }).overrideAttrs (old: {
    version = "master";
    src = builtins.fetchTarball
      "https://github.com/fanglingsu/vimb/archive/30b61203649010066d1cbd438b0c630d6d44c1a4.tar.gz";

    patches = (old.patches or []) ++ [
      # Upstream PR #810: webviews must be created with network-session,
      # otherwise cookies aren't persisted across runs.
      (builtins.fetchurl
        "https://github.com/fanglingsu/vimb/commit/b873b0dd0fab931f48158ee9b61c277f10012d48.patch")
    ];

    buildInputs = (old.buildInputs or []) ++ (with pkgs.gst_all_1; [
      gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad
    ]);

    postPatch = ''
      # --- tab close crash fixes ---------------------------------------------
      substituteInPlace src/ex.c \
        --replace-fail 'case EX_TABCLOSE:
            vb_tab_close(c);
            return CMD_SUCCESS;' 'case EX_TABCLOSE:
            vb_quit(c, FALSE);
            return CMD_SUCCESS;'

      substituteInPlace src/main.c \
        --replace-fail 'static void on_webview_close(WebKitWebView *webview, Client *c)
{
    /* Close the tab instead of destroying window */
    vb_tab_close(c);
}' 'static void on_webview_close(WebKitWebView *webview, Client *c)
{
    /* Deferred to avoid UAF: WebKit still touches the webview after this returns. */
    vb_quit(c, FALSE);
}'

      substituteInPlace src/main.c \
        --replace-fail '    /* Find page number */
    page_num = gtk_notebook_page_num(GTK_NOTEBOOK(vb.notebook), c->tab_box);' '    if (c->webview) {
        webkit_web_view_stop_loading(c->webview);
        g_signal_handlers_disconnect_by_data(c->webview, c);
    }
    if (c->finder) {
        g_signal_handlers_disconnect_by_data(c->finder, c);
    }
    if (vb.input_buffer) {
        g_signal_handlers_disconnect_by_data(vb.input_buffer, c);
    }
    if (c->map.timout_id) {
        g_source_remove(c->map.timout_id);
        c->map.timout_id = 0;
    }
    if (c->state.input_timer > 0) {
        g_source_remove(c->state.input_timer);
        c->state.input_timer = 0;
    }

    /* Find page number */
    page_num = gtk_notebook_page_num(GTK_NOTEBOOK(vb.notebook), c->tab_box);'

      # --- :tabbar-toggle ex command -----------------------------------------
      substituteInPlace src/ex.c \
        --replace-fail '    EX_TABLAST,
} ExCode;' '    EX_TABLAST,
    EX_TABTOGGLE,
} ExCode;'

      substituteInPlace src/ex.c \
        --replace-fail '{"tablast",          EX_TABLAST,     ex_tabcmd,     EX_FLAG_NONE},' \
                       '{"tablast",          EX_TABLAST,     ex_tabcmd,     EX_FLAG_NONE},
    {"tabbar-toggle",    EX_TABTOGGLE,   ex_tabcmd,     EX_FLAG_NONE},'

      substituteInPlace src/ex.c \
        --replace-fail '        case EX_TABLAST:
            vb_tab_goto(vb_get_tab_count() - 1);
            return CMD_SUCCESS;' '        case EX_TABLAST:
            vb_tab_goto(vb_get_tab_count() - 1);
            return CMD_SUCCESS;

        case EX_TABTOGGLE:
            if (vb.notebook) {
                gboolean s = gtk_notebook_get_show_tabs(GTK_NOTEBOOK(vb.notebook));
                gtk_notebook_set_show_tabs(GTK_NOTEBOOK(vb.notebook), !s);
            }
            return CMD_SUCCESS;'

      # --- follow system dark-mode (xdg-desktop-portal) ----------------------
      cp ${vimbDarkModeHeader} src/vimb_dark_mode.h
      chmod +w src/vimb_dark_mode.h

      substituteInPlace src/main.c \
        --replace-fail '#include <webkit/webkit.h>' '#include <webkit/webkit.h>
#include "vimb_dark_mode.h"'

      substituteInPlace src/main.c \
        --replace-fail '    /* initialize GTK+ */
    gtk_init();' '    /* initialize GTK+ */
    gtk_init();
    vimb_dark_mode_init();'
    '';

    # Drop the ported wyebadblock extension alongside vimb's own webext_main.so.
    # vimb tells WebKit to scan $out/lib/vimb/ for .so files, so WebKit picks
    # it up automatically — no vimb-side changes needed.
    postInstall = (old.postInstall or "") + ''
      install -Dm644 ${wyebadblock}/lib/wyebadblock/adblock.so $out/lib/vimb/adblock.so
    '';
  });

  settings = {
    intelligent-tracking-prevention = true;
    media-stream = true;
    mediasource = true;
    print-backgrounds = false;
    webaudio = true;
    webgl = true;
    webinspector = false;
    scroll-step = 80;
    home-page = "file:///home/alec/.config/vimb/homepage.html";
    history-max-items = 100;
    editor-command = "hx '%s'";
    user-agent = "Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0";
    show-titlebar = false;
    spell-checking = true;

    cursiv-font = "Iosevka";
    default-font = "Iosevka";
    monospace-font = "Iosevka";
    sans-serif-font = "Iosevka";
    serif-font = "Iosevka";
    notification = "never"; # no notification asking
    prevent-newwindow = true; # never open a new window, only use tabs!
    hint-keys-same-length = true; # delete if looks ugly

    site-specific-quirks = true; #only enable if broken sites
  } // lib.optionalAttrs (osConfig.networking.hostName or "" == "alecpc") {
    hardware-acceleration-policy = "always"; # TODO
  };

  formatValue = v:
    if builtins.isBool v then (if v then "on" else "off")
    else if builtins.isInt v then toString v
    else v;

  shortcuts = [
    "shortcut-add b=https://www.bing.com/search?q=$0"
    "shortcut-add nx=https://search.nixos.org/packages?query=$0"
    "shortcut-add gh=https://github.com/search?q=$0"
    "shortcut-default b"
  ];

  keybinds = [
    "nmap <C-t> t"
    "imap <C-t> <Esc>t"
    "nmap <C-w> :tabclose<CR>"
    "imap <C-w> <Esc>:tabclose<CR>"
    "nmap <C-l> o"
    "imap <C-l> <Esc>o"
    "nmap <C-o> o"
    "imap <C-o> <Esc>o"
    "nmap <C-r> r"
    "imap <C-r> <Esc>r"
    "nmap <C-f> /"
    "imap <C-f> <Esc>/"
    "nmap <C-[> <C-o>"
    "nmap <C-]> <C-i>"
    "nmap <C-d> Ma"
    "nmap <C-b> :tabbar-toggle<CR>"
    "imap <C-b> <Esc>:tabbar-toggle<CR>"
    "nmap <C-=> zi"
    "nmap <C-+> zi"
    "nmap <C--> zo"
    "nmap <C-0> zz"
    "imap <C-=> <Esc>zi"
    "imap <C-+> <Esc>zi"
    "imap <C--> <Esc>zo"
    "imap <C-0> <Esc>zz"
  ];

  configLines =
    (lib.mapAttrsToList (name: value: "set ${name}=${formatValue value}") settings)
    ++ shortcuts
    ++ keybinds;
in {
  home.packages = [ vimb-master ];

  xdg.mimeApps = {
    enable = true;
    defaultApplications = let v = "vimb.desktop"; in {
      "text/html" = v;
      "x-scheme-handler/http" = v;
      "x-scheme-handler/https" = v;
    };
  };

  xdg.configFile = {
    "vimb/config".text = lib.concatStringsSep "\n" configLines + "\n";

    # Cosmetic element-hiding rules extracted from the filter lists, applied
    # globally as vimb's user-stylesheet. wyebab serves the network-blocking
    # half; this serves the visibility half.
    "vimb/style.css".source = cosmeticStylesheet;

    "vimb/scripts.js".text = ''
      // ---- YouTube ad / anti-adblock bypass --------------------------------
      // Imported verbatim from TheRealJoelmatic/RemoveAdblockThing (6 k★).
      // It's a Tampermonkey userscript whose IIFE assumes the page already
      // matches youtube.com; vimb runs scripts.js on every page, so we gate
      // it by hostname here.
      if (/(^|\.)youtube\.com$/.test(location.hostname)) {
        ${builtins.readFile ytAdblockScript}
      }
    '';
    "vimb/homepage.html".text = "<!DOCTYPE html><html style=background:#2e3440><title>Homepage</title>";
  };
}
