{ pkgs, lib, inputs, ... }:
let
  skriptTreesitterSrc = pkgs.fetchFromGitHub {
    owner = "AmazinAxel";
    repo = "skript-treesitter";
    rev = "d22fee87c5b383bb9039ba30df6d28b2f98ade3d";
    hash = "sha256-q7OQedbJ9PAMN3l3J/u410BO0qNkccJaDdro+br65D0=";
  };
  skriptTreesitter = pkgs.tree-sitter.buildGrammar {
    language = "skript";
    version = "1.0.0";
    src = skriptTreesitterSrc;
  };
  helixPkg = inputs.helix.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  programs = {
    helix = {
      enable = true;
      defaultEditor = true;
      package = helixPkg;
      extraPackages = with pkgs; [
        marksman # markdown
        harper # grammar checker
        prettier # formatter
        typescript-language-server # some LSP stuff
        vscode-langservers-extracted # more lSP stuff
      ];
      settings = {
        theme = {
          light = "nord_light";
          dark = "nord-night";
        };

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
          idle-timeout = 500; # delay while typing
          inline-diagnostics = {
            cursor-line = "error";
            other-lines = "error";
          };
          end-of-line-diagnostics = "error";
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
            C-s = [ "normal_mode" ":write" ]; # ctrl+S save
            C-r = [ ":reload" ]; # reload file
          };
        in {
          normal = keybinds // {
            C-c = "yank_main_selection_to_clipboard";
            c = "toggle_comments";
            space.m = "@:move <C-r>%<C-w>";
            space.x = [ ":sh rm '%{buffer_name}'"  ":buffer-close!" ];
            space.o = [ ":sh cp '%{buffer_name}' ./"  ":open %sh{basename '%{buffer_name}'}" ];
            space.D = [
              ":sh git diff -U99999 HEAD -- %{buffer_name} | sed '1,/^@@/d' > /tmp/hx-diff-show.diff"
              ":vsplit /tmp/hx-diff-show.diff"
            ];
          };
          insert = keybinds;
          select = keybinds // {
            C-c = "yank_main_selection_to_clipboard";
            c = "toggle_comments";
          };
        };
      };
      themes."nord-night" = {
        "inherits" = "nord-night";
        "ui.background" = { };
      }; # we cant set background of nord-light to nothing since then the background wont change due to a bug

      languages = {
        language-server.harper-ls = {
          command = "harper-ls";
          args = [ "--stdio" ];
          config.harper-ls.linters = {
            UseTitleCase = false;
            UseEllipsisCharacter = false;
            Excellent = false;
            LongSentences = false;
            DiscourseMarkers = false;
            SplitWords = false;
            ExpandMemoryShorthand = false;
            NumericRangeEnDash = false;
          };
        };
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
        } {
          name = "markdown";
          language-servers = [ "marksman" "harper-ls" ];
          auto-format = true;
          formatter = {
            command = "prettier";
            args = [ "--parser" "markdown" ];
          };
        }];
        grammar = [{
          name = "skript";
          source.path = "${skriptTreesitterSrc}";
        }];
      };
    };
  };
  xdg.configFile = {
    "helix/runtime/queries/skript".source = "${skriptTreesitterSrc}/queries"; # needed for skript highlighting
    "helix/runtime/grammars/skript.so".source = "${skriptTreesitter}/parser"; # needed for skript syntax highlighting
  };

  home.activation.helix-grammars =
    let
      hx = lib.getExe helixPkg;
    in
    lib.hm.dag.entryAfter [ "linkGeneration" ]
      ''
        export HELIX_RUNTIME=/home/alec/.config/helix/runtime
        export PATH="${pkgs.git}/bin/:$PATH" # for pulling
        export PATH="${pkgs.gcc}/bin:$PATH" # for compiling
        run ${hx} --grammar fetch || true
        run ${hx} --grammar build || true
      '';
}
