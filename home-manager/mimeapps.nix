{ lib, ... }: {
  xdg.mimeApps = {
    enable = true;
    defaultApplications = lib.concatMapAttrs (app: mimes: lib.genAttrs mimes (_: app)) {
      "Helix.desktop" = [
        "text/plain"
        "text/markdown"
        "application/json"
        "application/yaml"
        "application/toml"
        "application/x-shellscript"
        "text/x-python"
        "text/javascript"
        "text/vnd.trolltech.linguist" # .ts
        "application/x-tiled-tsx" # .tsx
        "text/x-csrc"
        "text/x-c++src"
        "text/x-chdr"
        "text/x-c++hdr"
        "text/rust"
        "text/x-go"
        "text/x-lua"
        "text/x-log"
        "application/octet-stream" # unknown fallback
      ];
      "org.gnome.FileRoller.desktop" = [
        "application/zip"
      ];
      "org.gnome.gThumb.desktop" = [
        "image/png"
        "image/jpeg"
        "image/gif"
        "image/webp"
        "image/bmp"
        "image/svg+xml"
        "image/x-xcf"
        "image/vnd.adobe.photoshop"
        "video/mp4"
        "video/x-matroska"
        "video/webm"
        "video/vnd.avi"
        "video/quicktime"
        "audio/mpeg"
        "audio/flac"
        "audio/vnd.wave"
        "audio/ogg"
        "audio/mp4"
      ];
      "com.amazinaxel.lightbrowse.desktop" = [
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "text/html"
        "application/pdf"
      ];
    };
  };
}
