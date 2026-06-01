{
  programs.tmux = {
    enable = true;
    prefix = "C-a"; # easier to type
    keyMode = "vi";
    mouse = true;
    escapeTime = 10;
    terminal = "tmux-256color";
    baseIndex = 1;
    extraConfig = ''
      set -ga terminal-overrides ",foot*:Tc"

      # TODO make it follow starship theme
      set -g status-style "bg=#3b4252,fg=#d8dee9"
      set -g status-left  "#[bg=#d8dee9,fg=#4c566a] #S #[bg=#3b4252,fg=#d8dee9]"
      set -g status-right "#[fg=#81a1c1]%H:%M "
      set -g window-status-current-style "bg=#81a1c1,fg=#2e3440"
    '';
  };
}