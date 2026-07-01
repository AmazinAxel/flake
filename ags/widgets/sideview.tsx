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
// networkSession.set_itp_enabled(false);

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
