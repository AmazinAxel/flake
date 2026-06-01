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
          auto-info = true;
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
            ignore = false; # ^
          };
          search.smart-case = false; # do NOT be case sensitive no matter what

          indent-guides = {
            render = true;
          };
          gutters = [ "diagnostics" "spacer" "line-numbers" "spacer" "diff" ];
          soft-wrap.enable = true;
        };
        keys = let
          keybinds = {
            C-z = "undo"; # control+Z
            C-S-z = "redo"; # control+shift+Z
            A-tab = "goto_last_accessed_file"; # alt-tab, goto_last_modified_file
            C-tab = "buffer_picker"; # ctrl+tab
            C-s = ":write"; # ctrl+S save
          };
        in {
          normal = keybinds;
          insert = keybinds;
          select = keybinds;
        };
      };
      themes.nord = {
        "inherits" = "nord";
        "ui.background" = { }; # transparent background
      };

      languages = {
        # if you are building this please remove the following language, its not bundled in this flake as it is private for now
        # cd into skript-syntax-highlighting
        # nix-shell -p tree-sitter nodejs --run "tree-sitter generate"
        # hx --grammar fetch
        # nix-shell -p gcc --run "hx --grammar build"
        language = [{
          name = "skript";
          scope = "source.skript";
          file-types = [ "sk" ];
          roots = [ ];
          comment-token = "#";
          indent = {
            tab-width = 4;
            unit = "\t";
          };
          grammar = "skript";
        }];
        grammar = [{
          name = "skript";
          source.path = "${./skript-syntax-highlighting}";
        }];
      };
    };
    #nnn = {
    #  enable = true;
    #  bookmarks = {
    #    d = "~/Downloads";
    #  };
    #};
  };
  xdg.configFile."helix/runtime/queries/skript".source = ./skript-syntax-highlighting/queries; # needed for skript highlighting
}