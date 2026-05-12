{
  programs.helix = {
    enable = true;
    defaultEditor = true;
    settings = {
      theme = "nord";
      
      editor = {
        #mouse = true; # mouse mode
        middle-click-paste = false;
        scroll-lines = 10; # mouse scroll
        shell = ["fish" "-c"]; # default is bash
        #auto-info = false; # todo enable
        default-line-ending = "lf";
        trim-final-newlines = true; # only trims extra newlines
        trim-trailing-whitespace = true;
        popup-border = "all";
        clipboard-provider = "wayland";
        
        #statusline = { }; # mode, file-name, [spacer] read-only-indicator, file-modification-indicator, version-control
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
        };
      };
    };
    themes.nord = {
      "inherits" = "nord";
      "ui.background" = { }; # transparent background
    };
    #languages.language = [{
    #  name = "nix";
    #  auto-format = true;
    #  formatter.command = lib.getExe pkgs.nixfmt-rfc-style;
    #}];
  };
}
