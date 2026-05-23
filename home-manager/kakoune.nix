{ pkgs, lib, ... }: let
  nord-kak = pkgs.kakouneUtils.buildKakounePlugin {
    pname = "nord-kak";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "ABuffSeagull";
      repo = "nord.kak";
      rev = "8061196a0a671f482f288bfceb20a59b786dd8d4";
      hash = "sha256-ttohYhE3gunCxMfwNH6GUpgdTZKx6NTcI/t1df/vHCE=";
    };
  };

  kaktree = pkgs.kakouneUtils.buildKakounePlugin {
    pname = "kaktree";
    version = "unstable-2024";
    src = pkgs.fetchFromGitHub {
      owner = "andreyorst";
      repo = "kaktree";
      rev = "320d0a339638452e79be2a9caef11c05e8d47bec";
      hash = "sha256-67MpqTI6thQxFezYUHC2nETa1honfm2BQhqC+bsmQtQ=";
    };
  };

  skript-kak = pkgs.kakouneUtils.buildKakounePlugin {
    pname = "skript-syntax-highlighting";
    version = "1.0";
    src = ./skript-syntax-highlighting;
  };
in {
  programs.kakoune = {
    enable = true;
    plugins = with pkgs.kakounePlugins; [
      kakoune-lsp
      auto-pairs-kak
      fzf-kak
      kakoune-buffers
      kakboard
      nord-kak
      kaktree
      skript-kak
    ];
    extraConfig = ''
      # UI
      # todo use nord-kak??????
      hook global WinDisplay .* %{
          set-face global Default            "%opt{nord6},default"
          set-face global BufferPadding      "%opt{nord3},default"
          set-face global LineNumbers        "%opt{nord3},default"
          set-face global LineNumberCursor   "%opt{nord13},default+b"
          set-face global StatusLine         "%opt{nord4},default"
          set-face global StatusLineMode     "%opt{nord0},%opt{nord14}"
          set-face global StatusLineInfo     "%opt{nord8},default"
          set-face global StatusLineValue    "%opt{nord14},default"
      }
      add-highlighter global/ number-lines -hlcursor
      add-highlighter global/ show-matching
      add-highlighter global/ wrap -word -indent

      set-option global tabstop 4
      set-option global indentwidth 4
      set-option global scrolloff 3,3
      set-option global ui_options terminal_assistant=none
      set-option global startup_info_version 99999999

      # Clipboard
      hook global ModuleLoaded kakboard %{
          kakboard-enable
      }
      map global normal <c-c> '<a-|>wl-copy<ret>' -docstring 'copy selection to system clipboard'
      map global normal <c-v> '!wl-paste --no-newline<ret>' -docstring 'paste from system clipboard'
      map global insert <c-v> '<esc>!wl-paste --no-newline<ret>i' -docstring 'paste from system clipboard'

      # Auto pairs
      enable-auto-pairs

      # LSP
      eval %sh{kak-lsp --kakoune -s $kak_session}
      hook global WinSetOption filetype=(rust|python|go|javascript|typescript|c|cpp|nix|html|css|json|sh) %{
          lsp-enable-window
      }

      # Save with <c-s>
      map global normal <c-s> ': write<ret>'
      map global insert <c-s> '<esc>: write<ret>i'

      # fzf-kak
      # <space> already triggers user mode by default.
      map global user f ': fzf-mode<ret>f' -docstring 'fzf: files'
      map global user b ': fzf-mode<ret>b' -docstring 'fzf: buffers'
      map global user r ': fzf-mode<ret>F' -docstring 'fzf: recent (modified) files'
      map global user / ': fzf-mode<ret>s' -docstring 'fzf: ripgrep'

      # Buffer switcher (jabs replacement)
      # Ctrl-Tab opens a numbered info box of buffers; <a-tab> toggles to last.
      map global normal <c-tab>   ': enter-user-mode buffers<ret>b'
      map global normal <c-s-tab> ': enter-user-mode buffers<ret>b'
      map global normal <a-tab>   ': buffer-previous<ret>'
      map global user   k         ': enter-user-mode buffers<ret>' -docstring 'buffers menu'

      # ---------- kaktree (file tree sidebar) ----------

      hook global ModuleLoaded kaktree %{
          set-option global kaktree_split horizontal
          set-option global kaktree_side left
          set-option global kaktree_size 30
          set-option global kaktree_show_hidden true
          set-option global kaktree_sort true
          set-option global kaktree_double_click_duration '0.3'
          set-option global kaktree_indentation 1
          set-option global kaktree_dir_icon_open  '▾ '
          set-option global kaktree_dir_icon_close '▸ '
          set-option global kaktree_file_icon      '  '
      }

      declare-option -hidden bool kaktree_started false
      hook global ClientCreate .* %{
          evaluate-commands %sh{
              [ "$kak_hook_param" = "kaktreeclient" ] && exit 0
              # Always point jumpclient at the most recent real client.
              printf 'try %%{ set-option global kaktree__jumpclient %s }\n' "$kak_hook_param"
              if [ "$kak_opt_kaktree_started" = "false" ]; then
                  printf 'set-option global kaktree_started true\n'
                  printf 'try %%{ kaktree-enable }\n'
                  printf 'try %%{ set-option global kaktree__jumpclient %s }\n' "$kak_hook_param"
                  printf 'try %%{ kaktree--display }\n'
              fi
          }
      }

      hook global WinSetOption filetype=kaktree %{
          try %{ remove-highlighter window/number-lines }
          try %{ remove-highlighter window/show-matching }
          try %{ remove-highlighter window/wrap }
          try %{ remove-highlighter buffer/numbers }
          try %{ remove-highlighter buffer/matching }
          try %{ remove-highlighter buffer/wrap }
          try %{ remove-highlighter buffer/show-whitespaces }
      }

      # Toggle tree
      map global normal <c-b> ': kaktree-toggle<ret>' -docstring 'toggle file tree'

      # Skript
      hook global BufCreate .*\.sk %{ set-option buffer filetype skript }

      # :Project
      define-command -params 1 \
          -shell-script-candidates %{ ls -1 /home/alec/Projects 2>/dev/null } \
          -docstring 'Project <name>: cd into ~/Projects/<name>, refresh tree, load workspace' \
          Project %{
              evaluate-commands %sh{
                  path="/home/alec/Projects/$1"
                  if [ ! -d "$path" ]; then
                      echo "echo -markup '{Error}not a directory: $path'"
                      exit
                  fi
                  printf 'change-directory %%{%s}\n' "$path"
                  printf 'try %%{ workspace-load }\n'
                  printf 'try %%{ kaktree-disable }\n'
              printf 'try %%{ kaktree-enable; kaktree--display; kaktree--refresh }\n'
              }
          }
      alias global P Project

      # .code-workspace
      declare-option str-list workspace_roots
      declare-option int workspace_index 0

      define-command workspace-load \
          -docstring 'Load *.code-workspace folders; point tree at the first' %{
          evaluate-commands %sh{
              ws=$(ls -1 *.code-workspace 2>/dev/null | head -n1)
              [ -z "$ws" ] && exit 0
              base=$(dirname "$(readlink -f "$ws")")
              # Emit absolute folder paths, one per line
              roots=$(jq -r --arg base "$base" '
                  .folders[]?.path
                  | if startswith("/") then . else $base + "/" + . end
                  | sub("/\\.$"; "")
              ' "$ws" 2>/dev/null)
              [ -z "$roots" ] && exit 0
              # Build a kakoune str-list literal: items separated by single quotes
              args=""
              first=""
              while IFS= read -r r; do
                  [ -z "$r" ] && continue
                  [ -z "$first" ] && first="$r"
                  esc=$(printf %s "$r" | sed "s/'/'''/g")
                  args="$args '$esc'"
              done <<EOF
$roots
EOF
              printf 'set-option global workspace_roots%s\n' "$args"
              printf 'set-option global workspace_index 0\n'
              esc_first=$(printf %s "$first" | sed "s/'/'''/g")
              printf "change-directory '%s'\n" "$esc_first"
              printf 'try %%{ kaktree-disable }\n'
              printf 'try %%{ kaktree-enable; kaktree--display; kaktree--refresh }\n'
          }
      }

      define-command workspace-cycle \
          -docstring 'Cycle kaktree root through *.code-workspace folders' %{
          evaluate-commands %sh{
              eval "set -- $kak_quoted_opt_workspace_roots"
              count=$#
              [ "$count" -le 1 ] && exit 0
              next=$(( (kak_opt_workspace_index + 1) % count ))
              shift "$next"
              folder="$1"
              [ -z "$folder" ] && exit 0
              esc=$(printf %s "$folder" | sed "s/'/'''/g")
              printf 'set-option global workspace_index %d\n' "$next"
              printf "change-directory '%s'\n" "$esc"
              printf 'try %%{ kaktree-disable }\n'
              printf 'try %%{ kaktree-enable; kaktree--display; kaktree--refresh }\n'
              printf "echo -markup '{Information}workspace: %s'\n" "$esc"
          }
      }

      map global user w ': workspace-cycle<ret>' -docstring 'cycle workspace root'

      # Auto-load workspace on startup if one exists in cwd
      hook global KakBegin .* %{
          try %{ workspace-load }
      }
    '';
  };

  home.packages = with pkgs; [
    fzf
    ripgrep
    bat # fzf-kak previews
    jq # workspace-load JSON parsing
    perl # kaktree dependency
  ];
}
