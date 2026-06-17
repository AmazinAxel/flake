import { Astal, Gtk } from "ags/gtk4";
import { createState } from "ags";
import GLib from "gi://GLib";
import Gio from "gi://Gio";
import Gdk from "gi://Gdk";
// @ts-expect-error
import WebKit from "gi://WebKit?version=6.0";
import app from "ags/gtk4/app";

const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;

export type PageName = 'plan' | 'claude' | 'custom';

const urls: Record<PageName, string> = {
  plan: 'https://plan.amazinaxel.com/',
  claude: 'https://claude.ai/new',
  custom: 'https://skripthub.net/docs'
};

// Mirrors dark/light mode
const interfaceSettings = new Gio.Settings({ schema: "org.gnome.desktop.interface" });
const applyColorScheme = () => {
  const dark = interfaceSettings.get_string("color-scheme") === "prefer-dark";
  Gtk.Settings.get_default()!.gtk_application_prefer_dark_theme = dark;
};
applyColorScheme();
interfaceSettings.connect("changed::color-scheme", applyColorScheme);

const [ width, setWidth ] = createState(400);

const dataDir = GLib.get_user_data_dir() + '/ags-sideview';
const networkSession = new WebKit.NetworkSession({
  data_directory: dataDir,
  cache_directory: GLib.get_user_cache_dir() + '/ags-sideview'
});
networkSession.get_cookie_manager().set_persistent_storage(
  dataDir + "/cookies.sqlite",
  WebKit.CookiePersistentStorage.SQLITE
);


// Since we spoof a macOS user agenct, sites bind their shortcuts to the Command
// key (metaKey) and ignore Ctrl. Re-emit Ctrl presses as Command presses so the
// site's handlers fire; native Ctrl behavior (copy/paste/reload) is left intact.
// const ctrlToCommandSource = `
// (function() {
//   window.addEventListener("keydown", function(e) {
//     if (!e.ctrlKey || e.metaKey || !e.isTrusted) return;
//     e.target.dispatchEvent(new KeyboardEvent("keydown", {
//       key: e.key, code: e.code, location: e.location,
//       ctrlKey: false, metaKey: true, shiftKey: e.shiftKey, altKey: e.altKey,
//       repeat: e.repeat, isComposing: e.isComposing,
//       keyCode: e.keyCode, which: e.which, bubbles: true, cancelable: true
//     }));
//   }, true);
// })();
// `;
// const userContentManager = new WebKit.UserContentManager();
// userContentManager.add_script(WebKit.UserScript.new(
//   ctrlToCommandSource,
//   WebKit.UserContentInjectedFrames.ALL_FRAMES,
//   WebKit.UserScriptInjectionTime.START,
//   null, null
// ));

const stack = new Gtk.Stack();
const webviews: Partial<Record<PageName, any>> = {};
let currentPage: PageName | null = null;

const getWindow = () => app.get_window('sideview') as any; // wish i didnt have to type it as any

const ensurePage = (name: PageName) => {
  if (webviews[name]) return;
  const webview = new WebKit.WebView({
    network_session: networkSession
  });

  webview.get_settings().set_user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/26.0 Safari/605.1.15");

  // GTK grabs ctrl+. / ctrl+; for its emoji picker before the web content sees
  // them, so the ctrlToCommandSource script never gets a chance to remap them.
  // Intercept here in the CAPTURE phase: swallow both (no emoji picker), and for
  // ctrl+. re-emit a synthetic command+. into the page so the site's mac-style
  // shortcut (e.g. claude.ai's sidebar) fires.
  // const keyController = new Gtk.EventControllerKey();
  // keyController.set_propagation_phase(Gtk.PropagationPhase.CAPTURE);
  // keyController.connect("key-pressed", (_c, keyval, _code, state) => {
  //   if (!(state & Gdk.ModifierType.CONTROL_MASK)) return false;
  //   if (keyval !== Gdk.KEY_period && keyval !== Gdk.KEY_semicolon) return false;

  //   if (keyval === Gdk.KEY_period)
  //     webview.evaluate_javascript(
  //       `(document.activeElement||document.body).dispatchEvent(new KeyboardEvent("keydown",{key:".",code:"Period",keyCode:190,which:190,metaKey:true,bubbles:true,cancelable:true}))`,
  //       -1, null, null, null, null);
  //   return true; // consume so GTK's emoji picker never opens
  // });
  // webview.add_controller(keyController);

  webview.set_zoom_level(0.95);
  webview.load_uri(urls[name]);
  webviews[name] = webview;
  stack.add_named(webview, name);
};

export const showPage = (name: PageName) => {
  const window = getWindow();
  if (window.visible && currentPage === name) return hideSideview();

  ensurePage(name);
  stack.set_visible_child_name(name);
  currentPage = name;
  window.visible = true;
  window.keymode = Astal.Keymode.EXCLUSIVE;
};

export const toggleSideviewFocus = () => {
  const window = getWindow();
  if (!window?.visible) return;
  window.keymode = (window.keymode === Astal.Keymode.EXCLUSIVE)
    ? Astal.Keymode.ON_DEMAND
    : Astal.Keymode.EXCLUSIVE;
};

export const hideSideview = () => {
  const window = getWindow();
  window.visible = false;
};

// destroys all webviews
export const closeSideview = () => {
  hideSideview();
  for (const name of Object.keys(webviews) as PageName[]) {
    const webview = webviews[name]!;
    stack.remove(webview);
    webview.run_dispose?.();
    delete webviews[name];
  };
  currentPage = null;
};

export const toggleSideviewSize = () => {
  const next = (width.peek() == 400) ? 700 : 400;
  setWidth(next);
  getWindow()?.set_default_size(next, -1);
};

export default () =>
  <window
    name="sideview"
    visible={false}
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    keymode={Astal.Keymode.ON_DEMAND}
    anchor={TOP | BOTTOM | RIGHT}
    application={app}
    layer={Astal.Layer.OVERLAY}
    widthRequest={width}
  >
    <Gtk.EventControllerKey onKeyPressed={(_, key, __, state) => {
      if (key === 114 && (state & Gdk.ModifierType.CONTROL_MASK) && currentPage)
        webviews[currentPage]?.reload(); // ctrl+R to reload page
    }}/>
    {stack}
  </window>;
