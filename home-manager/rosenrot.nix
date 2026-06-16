{ pkgs, config, ... }:
let
  easylist = builtins.fetchurl "https://easylist.to/easylist/easylist.txt";
  easyprivacy = builtins.fetchurl "https://easylist.to/easylist/easyprivacy.txt";

  filterList = pkgs.runCommand "rosenrot-filterlist.txt" { } ''
    cat ${easylist} ${easyprivacy} > $out
  '';

  rosenrot = pkgs.stdenv.mkDerivation {
    pname = "rosenrot";
    version = "1.0.0";

    src = builtins.fetchTarball
      "https://github.com/NunoSempere/rosenrot-browser/archive/31e03cd7c1269a625fd82add615e2e5cd20066f5.tar.gz";

    nativeBuildInputs = with pkgs; [ pkg-config wrapGAppsHook4 ];

    buildInputs = with pkgs; [
      glib
      glib-networking
      gtk4
      webkitgtk_6_0
    ] ++ (with pkgs.gst_all_1; [
      gstreamer
      gst-plugins-base
      gst-plugins-good
      gst-plugins-bad
      gst-plugins-ugly
      gst-libav
    ]);

    postPatch = ''
      # Use our vendored config.h verbatim; @out@ is the only build-time value.
      install -m 0644 ${./rosenrot-config.h} src/config.h
      substituteInPlace src/config.h \
        --replace-fail '@out@' "$out"

      # Drop the custom GTK stylesheet entirely so the browser inherits the
      # plain GTK theme.
      substituteInPlace src/rosenrot.c \
        --replace-fail '/opt/rosenrot/uris.txt' \
                       '/home/alec/.cache/rosenrot/uris.txt' \
        --replace-fail 'GtkCssProvider* css = gtk_css_provider_new();' "" \
        --replace-fail 'gtk_css_provider_load_from_path(css, "/opt/rosenrot/style-gtk4.css");' "" \
        --replace-fail 'gtk_style_context_add_provider_for_display(gdk_display_get_default(), GTK_STYLE_PROVIDER(css), GTK_STYLE_PROVIDER_PRIORITY_USER);' ""

      substituteInPlace src/plugins/style/style.c \
        --replace-fail '/opt/rosenrot/style.js' \
                       "$out/share/rosenrot/style.js"

      substituteInPlace src/plugins/readability/readability.c \
        --replace-fail '/opt/rosenrot/readability.js' \
                       "$out/share/rosenrot/readability.js"
    '';

    buildPhase = ''
      runHook preBuild
      mkdir -p out

      gcc -std=c99 -O2 -Wall -Wextra -Wno-unused-parameter -fstack-protector-strong \
        $(pkg-config --cflags webkitgtk-6.0 gtk4) \
        src/plugins/strings/strings.c \
        src/plugins/style/style.c \
        src/plugins/shortcuts/shortcuts.c \
        src/plugins/readability/readability.c \
        src/plugins/libre_redirect/libre_redirect.c \
        src/rosenrot.c \
        -o out/rosenrot \
        $(pkg-config --libs webkitgtk-6.0 gtk4)

      # Adblock web-process extension: a shared library WebKit loads into the
      # web process to intercept and block requests against the filter list.
      # The filter path is compiled in via -D.
      gcc -std=c99 -O2 -Wall -Wextra -Wno-unused-parameter -fPIC -shared \
        $(pkg-config --cflags webkitgtk-web-process-extension-6.0 glib-2.0 gio-2.0) \
        -DADBLOCK_FILTERLIST_PATH="\"$out/share/rosenrot/easylist.txt\"" \
        src/plugins/adblock/adblock_extension.c \
        src/plugins/adblock/uri_tester.c \
        -o out/librosenrot-adblock.so \
        $(pkg-config --libs webkitgtk-web-process-extension-6.0 glib-2.0 gio-2.0)

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      install -Dm755 out/rosenrot $out/bin/rosenrot
      install -Dm644 src/plugins/style/style.js     $out/share/rosenrot/style.js
      install -Dm644 src/plugins/readability/readability.js $out/share/rosenrot/readability.js
      cp -r src/images/flower-imgs $out/share/rosenrot/flower-imgs

      # Adblock extension + filter list
      install -Dm755 out/librosenrot-adblock.so $out/share/rosenrot/extensions/librosenrot-adblock.so
      install -Dm644 ${filterList} $out/share/rosenrot/easylist.txt
      runHook postInstall
    '';
  };
in {
  home.packages = [ rosenrot ];


  xdg.configFile."rosenrot-homepage.html".text = "<!DOCTYPE html><html style=background:#2e3440><title>Homepage</title>";


  # Cache + uris.txt must exist before rosenrot is launched; the binary opens
  # uris.txt in append mode and WebKit needs a writable base-cache-directory.
  # home.activation.rosenrotCache =
  #   config.lib.dag.entryAfter [ "writeBoundary" ] ''
  #     run mkdir -p ${config.home.homeDirectory}/.cache/rosenrot
  #     run touch   ${config.home.homeDirectory}/.cache/rosenrot/uris.txt
  #   '';
}
