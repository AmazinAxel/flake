import { Astal, Gtk } from "ags/gtk4";
import GLib from "gi://GLib";
import Gio from "gi://Gio";
// @ts-expect-error
import WebKit from "gi://WebKit?version=6.0";
import app from "ags/gtk4/app";

// Mirrors dark/light mode
const interfaceSettings = new Gio.Settings({ schema: "org.gnome.desktop.interface" });
const applyColorScheme = () => {
  const dark = interfaceSettings.get_string("color-scheme") === "prefer-dark";
  Gtk.Settings.get_default()!.gtk_application_prefer_dark_theme = dark;
};
applyColorScheme();
interfaceSettings.connect("changed::color-scheme", applyColorScheme);

const { TOP, BOTTOM, RIGHT } = Astal.WindowAnchor;

export default (name: string, url: string, width: any = 400) => {
  const dataDir = GLib.get_user_data_dir() + '/ags-sidebar-' + name;
  const cacheDir = GLib.get_user_cache_dir() + '/ags-sidebar-' + name;

  const networkSession = new WebKit.NetworkSession({
    data_directory: dataDir,
    cache_directory: cacheDir
  });

  // Persists cookies
  networkSession.get_cookie_manager().set_persistent_storage(
    dataDir + "/cookies.sqlite",
    WebKit.CookiePersistentStorage.SQLITE
  );

  let webviewRef: any = null;
  let loaded = false;

  // this exists because we dont load the page until its opened, this reduces mem and network errors
  const toggle = () => {
    if (!loaded && webviewRef) {
      loaded = true;
      webviewRef.load_uri(url);
    };
    app.toggle_window(name);
  };

  const Window = () =>
    <window
      name={name}
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
          self.set_zoom_level(0.95);
          webviewRef = self;
        }}
      />
    </window>;

  return { Window, toggle };
};
