import app from "ags/gtk4/app";
import { Astal, Gtk } from "ags/gtk4";
import { createState } from "ags";
import GLib from "gi://GLib";
import Gio from "gi://Gio";
// @ts-expect-error
import WebKit from "gi://WebKit?version=6.0";

// Mirrors dark/light mode
const interfaceSettings = new Gio.Settings({ schema: "org.gnome.desktop.interface" });
const applyColorScheme = () => {
  const dark = interfaceSettings.get_string("color-scheme") === "prefer-dark";
  Gtk.Settings.get_default()!.gtk_application_prefer_dark_theme = dark;
};
applyColorScheme();
interfaceSettings.connect("changed::color-scheme", applyColorScheme);

const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;

const [ width, setWidth ] = createState(400);

const dataDir = GLib.get_user_data_dir() + "/ags-sidebar-chat";
const cacheDir = GLib.get_user_cache_dir() + "/ags-sidebar-chat";

const networkSession = new WebKit.NetworkSession({
  data_directory: dataDir,
  cache_directory: cacheDir
});

// Persists cookies
networkSession.get_cookie_manager().set_persistent_storage(
  dataDir + "/cookies.sqlite",
  WebKit.CookiePersistentStorage.SQLITE
);

export const toggleChatSize = () => {
  const next = (width.peek() == 400) ? 700 : 400;
  setWidth(next);
  app.get_window('chat')?.set_default_size(next, -1);
};

let webviewRef: any = null;
let loaded = false;

export const toggleChat = () => {
  if (!loaded && webviewRef) {
    loaded = true;
    webviewRef.load_uri("https://claude.ai/new");
  }
  app.toggle_window("chat");
};

export default () =>
  <window
    name="chat"
    exclusivity={Astal.Exclusivity.EXCLUSIVE}
    keymode={Astal.Keymode.ON_DEMAND}
    anchor={TOP | BOTTOM | RIGHT}
    application={app}
    layer={Astal.Layer.OVERLAY}
    widthRequest={width}
  >
    <WebKit.WebView
      network_session={networkSession}
      $={(self: any) => {
        self.get_settings().set_user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 14_6) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"); // or else it causes security errors
        self.set_zoom_level(self.get_scale_factor() * 0.95);
        webviewRef = self;
      }}
    />
  </window>
