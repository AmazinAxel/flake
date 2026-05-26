{ pkgs, ... }:
{
  programs = {
    helix = {
      enable = true;
      defaultEditor = true;
      settings = {
        theme = "nord";

        editor = {
          middle-click-paste = false;
          scroll-lines = 10; # mouse scroll
          shell = ["fish" "-c"]; # default is bash
          auto-info = false; # todo enable
          default-line-ending = "lf";
          trim-final-newlines = true; # only trims extra newlines
          trim-trailing-whitespace = true;
          popup-border = "all";
          clipboard-provider = "wayland";

          statusline = {
            left = ["mode" "file-name" ];
            center = [];
            right = [ "read-only-indicator" "file-modification-indicator" "version-control" ];
          };

          lsp = {
            display-messages = false; # ??
            display-inlay-hints = true;
            inlay-hints-length-limit = 20;
          };
          cursor-shape = {
            insert = "bar";
            select = "underline";
          };
          file-picker = {
            hidden = false; # show hidden files
            git-global = false; # not necessary, we dont modify this
            git-exclude = false; # ^
          };
          search.smart-case = false; # do NOT be case sensitive no matter what

          indent-guides = {
            render = true;
          };
          gutters = [ "diagnostics" "spacer" "line-numbers" "spacer" "diff" ];
          soft-wrap.enable = true;
        };
        keys = {
          normal = {
            C-z = "undo"; # control+Z
            C-S-z = "redo"; # control+shift+Z
            A-tab = "goto_last_accessed_file"; # alt-tab, goto_last_modified_file
            C-tab = "buffer_picker"; # ctrl+tab
          };
        };
      };
      themes.nord = {
        "inherits" = "nord";
        "ui.background" = { }; # transparent background
      };
      #languages.language = [
      #  { name = "javascript"; auto-format = true; }
      #  { name = "typescript"; auto-format = true; }
      #  { name = "tsx"; auto-format = true; }
      #];
    };
    nnn = {
      enable = true;
      bookmarks = {
        d = "~/Downloads";
      };
    };
  };
}