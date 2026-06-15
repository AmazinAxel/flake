{ pkgs, lib, config, osConfig, ... }:
let
  # this file is vibecoded garbage and needs to be upstreamed. do not reference
  vimb-master = (pkgs.vimb-unwrapped.override {
    gtk3 = pkgs.gtk4;
    webkitgtk_4_1 = pkgs.webkitgtk_6_0;
  }).overrideAttrs (old: {
    version = "master-30b6120-tabclose-fix";
    src = pkgs.fetchFromGitHub {
      owner = "fanglingsu";
      repo = "vimb";
      rev = "30b61203649010066d1cbd438b0c630d6d44c1a4";
      hash = "sha256-ci0+fnIGqHw93z6qX0WsxQ8FUypSCC+boXFnYt7jvxc=";
    };

    # vb_tab_close() frees the Client synchronously, but :tabclose is reached
    # via ex_run_string() / input_activate() which keep using `c` (history_add,
    # vb_input_set_text) after it returns — instant UAF segfault. on_webview_close
    # has the same shape: WebKit dereferences the webview after the signal returns,
    # but vb_tab_close already destroyed the parent tab_box. vb_quit() already
    # defers via g_idle_add for exactly this reason; route both callers through it.
    postPatch = ''
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
    /* Close the tab instead of destroying window. Deferred to avoid use-after-free:
     * WebKit still touches the webview after this signal handler returns. */
    vb_quit(c, FALSE);
}'
    '';
    buildInputs = (old.buildInputs or []) ++ (with pkgs.gst_all_1; [
     gstreamer gst-plugins-base gst-plugins-good gst-plugins-bad
     gst-plugins-ugly gst-libav gst-vaapi
    ]);
#     postPatch = ''
#       substituteInPlace src/main.c \
#         --replace-fail 'void vb_tab_close(Client *c)
# {
#     int page_num;
#     Client *p;

#     if (!c || !c->tab_box) {
#         return;
#     }

#     /* Check for running downloads */
#     if (c->state.downloads) {
#         vb_echo_force(c, MSG_ERROR, TRUE,
#             "Can'\'''t close tab: there are running downloads. Use :q! to force");
#         return;
#     }

#     /* Write last URL to closed file */
#     if (c->state.uri && vb.config.closed_max && vb.files[FILES_CLOSED]) {
#         util_file_prepend_line(vb.files[FILES_CLOSED], c->state.uri, vb.config.closed_max);
#     }

#     /* Find page number */
#     page_num = gtk_notebook_page_num(GTK_NOTEBOOK(vb.notebook), c->tab_box);

#     /* Remove from notebook */
#     if (page_num >= 0) {
#         gtk_notebook_remove_page(GTK_NOTEBOOK(vb.notebook), page_num);
#     }

#     /* Remove from client list */
#     for (p = vb.clients; p && p->next != c; p = p->next);
#     if (p) {
#         p->next = c->next;
#     } else {
#         vb.clients = c->next;
#     }

#     /* Clean up client resources */
#     if (c->state.search.last_query) {
#         g_free(c->state.search.last_query);
#     }
#     if (c->state.hit_test_result) {
#         g_object_unref(c->state.hit_test_result);
#     }
#     if (c->state.uri) {
#         g_free(c->state.uri);
#     }
#     if (c->state.title) {
#         g_free(c->state.title);
#     }
#     completion_cleanup(c);
#     map_cleanup(c);
#     register_cleanup(c);
#     setting_cleanup(c);
# #ifdef FEATURE_AUTOCMD
#     autocmd_cleanup(c);
# #endif
#     handler_free(c->handler);
#     shortcut_free(c->config.shortcuts);
#     g_slice_free(Client, c);

#     /* If no more tabs, quit */
#     if (gtk_notebook_get_n_pages(GTK_NOTEBOOK(vb.notebook)) == 0) {
#         gtk_window_destroy(GTK_WINDOW(vb.main_window));
#     }
# }' 'void vb_tab_close(Client *c)
# {
#     int page_num;
#     Client *p;
#     GtkWidget *deferred_box;

#     if (!c || !c->tab_box) {
#         return;
#     }

#     if (c->state.downloads) {
#         vb_echo_force(c, MSG_ERROR, TRUE,
#             "Can'\'''t close tab: there are running downloads. Use :q! to force");
#         return;
#     }

#     if (c->state.uri && vb.config.closed_max && vb.files[FILES_CLOSED]) {
#         util_file_prepend_line(vb.files[FILES_CLOSED], c->state.uri, vb.config.closed_max);
#     }

#     /* --- heap-safe teardown ---
#      * Stop the page, cancel pending timers, and disconnect every signal
#      * handler that captures `c` BEFORE widgets get destroyed. Async
#      * WebKit / GStreamer events (audio decode, web-process IPC) firing
#      * on freed `c` is what corrupts the heap. */
#     if (c->webview) {
#         webkit_web_view_stop_loading(c->webview);
#         g_signal_handlers_disconnect_matched(c->webview,
#             G_SIGNAL_MATCH_DATA, 0, 0, NULL, NULL, c);
#     }
#     if (c->finder) {
#         g_signal_handlers_disconnect_matched(c->finder,
#             G_SIGNAL_MATCH_DATA, 0, 0, NULL, NULL, c);
#     }
#     if (vb.input_buffer) {
#         g_signal_handlers_disconnect_matched(vb.input_buffer,
#             G_SIGNAL_MATCH_DATA, 0, 0, NULL, NULL, c);
#     }
#     if (c->map.timout_id) {
#         g_source_remove(c->map.timout_id);
#         c->map.timout_id = 0;
#     }
#     if (c->state.input_timer > 0) {
#         g_source_remove(c->state.input_timer);
#         c->state.input_timer = 0;
#     }

#     /* Unlink from clients list before widget destruction so signal
#      * handlers iterating vb.clients cannot observe a half-freed Client. */
#     for (p = vb.clients; p && p->next != c; p = p->next);
#     if (p) {
#         p->next = c->next;
#     } else {
#         vb.clients = c->next;
#     }

#     /* Hold a ref on tab_box so notebook removal does NOT trigger widget
#      * disposal yet. We drop this ref on the next idle, after `c` is fully
#      * freed, so WebKit widget dispose (which tears down the WebProcess
#      * and any active GStreamer pipelines) cannot race with our free. */
#     deferred_box = GTK_WIDGET(g_object_ref(c->tab_box));

#     page_num = gtk_notebook_page_num(GTK_NOTEBOOK(vb.notebook), c->tab_box);
#     if (page_num >= 0) {
#         gtk_notebook_remove_page(GTK_NOTEBOOK(vb.notebook), page_num);
#     }

#     if (c->state.search.last_query) {
#         g_free(c->state.search.last_query);
#     }
#     if (c->state.hit_test_result) {
#         g_object_unref(c->state.hit_test_result);
#     }
#     if (c->state.uri) {
#         g_free(c->state.uri);
#     }
#     if (c->state.title) {
#         g_free(c->state.title);
#     }
#     completion_cleanup(c);
#     map_cleanup(c);
#     register_cleanup(c);
#     setting_cleanup(c);
# #ifdef FEATURE_AUTOCMD
#     autocmd_cleanup(c);
# #endif
#     handler_free(c->handler);
#     shortcut_free(c->config.shortcuts);
#     g_slice_free(Client, c);

#     g_idle_add_once((GSourceOnceFunc)g_object_unref, deferred_box);

#     if (gtk_notebook_get_n_pages(GTK_NOTEBOOK(vb.notebook)) == 0) {
#         gtk_window_destroy(GTK_WINDOW(vb.main_window));
#     }
# }'

#       substituteInPlace src/config.def.h \
#         --replace-fail '#define GUI_WINDOW_BACKGROUND_COLOR "#FFFFFF"' \
#                        '/* removed */'

#       substituteInPlace src/ex.c \
#         --replace-fail '    EX_TABLAST,
# } ExCode;' '    EX_TABLAST,
#     EX_TABTOGGLE,
# } ExCode;' \
#         --replace-fail '{"tablast",          EX_TABLAST,     ex_tabcmd,     EX_FLAG_NONE},' \
#                        '{"tablast",          EX_TABLAST,     ex_tabcmd,     EX_FLAG_NONE},
#     {"tabbar-toggle",    EX_TABTOGGLE,   ex_tabcmd,     EX_FLAG_NONE},' \
#         --replace-fail '        case EX_TABLAST:
#             vb_tab_goto(vb_get_tab_count() - 1);
#             return CMD_SUCCESS;' '        case EX_TABLAST:
#             vb_tab_goto(vb_get_tab_count() - 1);
#             return CMD_SUCCESS;

#         case EX_TABTOGGLE:
#             if (vb.notebook) {
#                 gboolean s = gtk_notebook_get_show_tabs(GTK_NOTEBOOK(vb.notebook));
#                 gtk_notebook_set_show_tabs(GTK_NOTEBOOK(vb.notebook), !s);
#             }
#             return CMD_SUCCESS;'

#       substituteInPlace src/main.c \
#         --replace-fail 'spawn_new_instance(webkit_uri_request_get_uri(req));
#                 }
#             }
#             break;' 'vb_load_uri(c, &(Arg){TARGET_TAB, (char*)webkit_uri_request_get_uri(req)});
#                 }
#             }
#             break;'

#       substituteInPlace src/main.c \
#         --replace-fail '"user-content-manager", ucm,
#                     "web-context", vb.webcontext,
#                     NULL));' '"user-content-manager", ucm,
#                     "web-context", vb.webcontext,
#                     "network-session", vb.session,
#                     NULL));'

#       cat > src/vimb_dark_mode.h <<'DMEOF'
#       #pragma once
#       #include <gtk/gtk.h>
#       #include <gio/gio.h>

#       static void vimb_apply_dark(gboolean dark) {
#           g_setenv("GTK_THEME", dark ? "Graphite-Dark-nord:dark" : "Graphite-Dark-nord", TRUE);
#           GtkSettings *gs = gtk_settings_get_default();
#           if (!gs) return;
#           g_object_set(gs, "gtk-application-prefer-dark-theme", dark, NULL);
#           g_object_notify(G_OBJECT(gs), "gtk-application-prefer-dark-theme");
#       }

#       static void vimb_on_portal_setting_changed(GDBusConnection *c, const gchar *sender,
#               const gchar *obj, const gchar *iface, const gchar *signal,
#               GVariant *params, gpointer u) {
#           const gchar *ns = NULL, *key = NULL; GVariant *value = NULL;
#           g_variant_get(params, "(&s&sv)", &ns, &key, &value);
#           if (g_strcmp0(ns, "org.freedesktop.appearance") == 0 &&
#               g_strcmp0(key, "color-scheme") == 0) {
#               guint32 v = g_variant_get_uint32(value);
#               vimb_apply_dark(v == 1);
#           }
#           if (value) g_variant_unref(value);
#       }

#       static guint32 vimb_query_portal_color_scheme(GDBusConnection *bus) {
#           GVariant *res = g_dbus_connection_call_sync(bus,
#               "org.freedesktop.portal.Desktop",
#               "/org/freedesktop/portal/desktop",
#               "org.freedesktop.portal.Settings", "Read",
#               g_variant_new("(ss)", "org.freedesktop.appearance", "color-scheme"),
#               G_VARIANT_TYPE("(v)"), G_DBUS_CALL_FLAGS_NONE, -1, NULL, NULL);
#           if (!res) return 0;
#           GVariant *vv = NULL; g_variant_get(res, "(v)", &vv);
#           GVariant *inner = g_variant_is_of_type(vv, G_VARIANT_TYPE_VARIANT) ? g_variant_get_variant(vv) : g_variant_ref(vv);
#           guint32 v = g_variant_get_uint32(inner);
#           g_variant_unref(inner); g_variant_unref(vv); g_variant_unref(res);
#           return v;
#       }

#       static void vimb_dark_mode_init(void) {
#           GDBusConnection *bus = g_bus_get_sync(G_BUS_TYPE_SESSION, NULL, NULL);
#           if (!bus) return;
#           g_dbus_connection_signal_subscribe(bus,
#               "org.freedesktop.portal.Desktop",
#               "org.freedesktop.portal.Settings",
#               "SettingChanged", "/org/freedesktop/portal/desktop",
#               NULL, G_DBUS_SIGNAL_FLAGS_NONE,
#               vimb_on_portal_setting_changed, NULL, NULL);
#           vimb_apply_dark(vimb_query_portal_color_scheme(bus) == 1);
#       }
#       DMEOF

#       substituteInPlace src/main.c \
#         --replace-fail '#include <webkit/webkit.h>' '#include <webkit/webkit.h>
#       #include "vimb_dark_mode.h"' \
#         --replace-fail 'gtk_init();' 'gtk_init();
#           vimb_dark_mode_init();'
#     '';
  });

  settings = {
    intelligent-tracking-prevention = true;
    media-stream = true;
    mediasource = true;
    print-backgrounds = false;
    webaudio = true;
    webgl = true;
    webinspector = false;
    stylesheet = false;
    scroll-step = 50;
    home-page = "file:///home/alec/.config/vimb/homepage.html";
    history-max-items = 100;
    editor-command = "hx '%s'";
    show-titlebar = false;
    spell-checking = true;

    #cursiv-font = "Iosevka";
    #default-font = "Iosevka";
    #monospace-font = "Iosevka";
    #sans-serif-font = "Iosevka";
    #serif-font = "Iosevka";
    #notification = "never"; # no notification asking
    #prevent-newwindow = true; # never open a new window, only use tabs!
    #hint-keys-same-length = true; # delete if looks ugly

    # site-specific-quirks = true; #only enable if broken sites
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

  xdg.configFile = {
    "vimb/config".text = lib.concatStringsSep "\n" configLines + "\n";
    "vimb/scripts.js".text = ''
      (function () {
        'use strict';

        const HIDE = [
          '[id^="google_ads"]','[id^="div-gpt-ad"]','[id^="ad-"]','[id^="ad_"]',
          '[id$="-ad"]','[id*="-ads-"]','[id*="-advert"]','[id*="advertisement"]',
          '[class^="ad-"]:not(.add-to-cart):not(.address):not(.added):not(.adjust)',
          '[class*=" ad-"]','[class$="-ad"]','[class*="-ads-"]','[class*="-advert"]',
          '[class*="advertisement"]','[class*="sponsored-content"]','[class*="sponsor-content"]',
          '[data-ad]','[data-ad-slot]','[data-ad-client]','[data-advert]',
          'ins.adsbygoogle',
          'iframe[src*="googlesyndication"]','iframe[src*="doubleclick.net"]',
          'iframe[src*="googleadservices"]','iframe[src*="adnxs"]',
          'iframe[src*="taboola"]','iframe[src*="outbrain"]',
          'iframe[src*="criteo"]','iframe[src*="amazon-adsystem"]',
          'iframe[id^="aswift_"]','iframe[id^="google_ads"]',
          'div[id^="taboola"]','div[class*="taboola"]',
          'div[id*="outbrain"]','div[class*="outbrain"]',
          'div[id^="sponsored"]','div[class*="sponsored-post"]',
          '[aria-label*="advertisement" i]','[aria-label*="sponsored" i]',
          'ytd-ad-slot-renderer','ytd-display-ad-renderer',
          'ytd-promoted-sparkles-web-renderer','ytd-companion-slot-renderer',
          'ytd-action-companion-ad-renderer','ytd-in-feed-ad-layout-renderer',
          'ytd-statement-banner-renderer','tp-yt-paper-dialog:has(yt-mealbar-promo-renderer)',
          '.ytp-ad-overlay-container','.ytp-ad-module','.ytp-ad-image-overlay',
          'shreddit-ad-post','[data-promoted="true"]',
          '[data-testid="placementTracking"]',
        ];

        const CSS = HIDE.join(',') + '{display:none!important;visibility:hidden!important;height:0!important;width:0!important;}';

        const onYouTube = /(^|\.)youtube\.com$/.test(location.hostname);
        const inject = () => {
          if (onYouTube) return;
          if (document.getElementById('vimb-adblock')) return;
          const s = document.createElement('style');
          s.id = 'vimb-adblock';
          s.textContent = CSS;
          (document.head || document.documentElement).appendChild(s);
        };
        inject();
        new MutationObserver(() => {
          if (!document.getElementById('vimb-adblock')) inject();
        }).observe(document.documentElement, { childList: true, subtree: true });

        const BLOCK = [
          'doubleclick.net','googlesyndication.com','googleadservices.com',
          'google-analytics.com','googletagmanager.com','googletagservices.com',
          'amazon-adsystem.com','adnxs.com','taboola.com','outbrain.com',
          'criteo.net','criteo.com','scorecardresearch.com','quantserve.com',
          'pubmatic.com','rubiconproject.com','openx.net','adsrvr.org',
          'moatads.com','adsystem.com','smartadserver.com','adsafeprotected.com',
          'serving-sys.com','indexww.com','casalemedia.com','adform.net',
          'bidswitch.net','3lift.com','yieldmo.com','contextweb.com',
          'sharethrough.com','tribalfusion.com','adroll.com','demdex.net',
          'mediavoice.com','revcontent.com','mgid.com',
        ];

        const blocked = (url) => {
          try {
            const u = typeof url === "string" ? url : (url && (url.url || url.href)) || "";
            if (/(^|\.)youtube\.com$/.test(location.hostname)) return false;
            return BLOCK.some(d => u.includes(d));
          } catch { return false; }
        };

        const origFetch = window.fetch;
        window.fetch = function (input, init) {
          if (blocked(input)) return Promise.reject(new TypeError('Blocked by adblock'));
          return origFetch.apply(this, arguments);
        };

        const origOpen = XMLHttpRequest.prototype.open;
        XMLHttpRequest.prototype.open = function (method, url) {
          if (blocked(url)) throw new Error('Blocked by adblock');
          return origOpen.apply(this, arguments);
        };

        const noop = function () {};
        const noopObj = new Proxy({}, { get: () => noop });
        try { window.googletag = { cmd: { push: noop }, pubads: () => noopObj, enableServices: noop, defineSlot: () => noopObj, display: noop, destroySlots: noop }; } catch (e) {}
        try {
          const a = [];
          a.push = noop;
          Object.defineProperty(window, 'adsbygoogle', { value: a, configurable: false, writable: false });
        } catch (e) {}

        if (/(^|\.)youtube\.com$/.test(location.hostname)) {
          const yt = document.createElement('style');
          yt.id = 'vimb-yt-css';
          yt.textContent = [
            '#masthead-ad',
            'ytd-banner-promo-renderer',
            'ytd-statement-banner-renderer',
            'ytd-mealbar-promo-renderer',
          ].join(',') + '{display:none!important;}';
          (document.head || document.documentElement).appendChild(yt);

          const skip = () => {
            try {
              const player = document.querySelector('.html5-video-player.ad-showing');
              if (!player) return;
              const btn = player.querySelector(
                '.ytp-ad-skip-button, .ytp-ad-skip-button-modern, .ytp-skip-ad-button'
              );
              if (btn) { btn.click(); return; }
              const v = player.querySelector('video');
              if (v && isFinite(v.duration) && v.duration > 0) {
                v.muted = true;
                v.currentTime = v.duration;
              }
            } catch (e) {}
          };
          setInterval(skip, 250);
        }
      })();
    '';
    "vimb/homepage.html".text = "<!DOCTYPE html><html style=background:#2e3440><title>Homepage</title>";
  };
}
