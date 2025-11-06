{
  programs.foot = {
    enable = true;
    settings = {
      main = {
        title = "Terminal";
        shell = "fish";
        pad = "5x5";
        font = "Iosevka:size=9";
      };
      cursor = {
        style = "beam";
        unfocused-style = "unchanged";
        blink = true;
        beam-thickness = 1;
      };
      colors = {
        alpha = 0.7;
        background = "2e3440"; # Black (regular0)
        foreground = "d8dee9"; # Grayish-white

        # Normal/regular Nord colors
        regular0 = "2e3440"; # Black
        regular1 = "bf616a"; # Red
        regular2 = "a3be8c"; # Green
        regular3 = "ebcb8b"; # Yellow
        regular4 = "5e81ac"; # Blue
        regular5 = "b48ead"; # Magenta
        regular6 = "81a1c1"; # Cyan
        regular7 = "eceff4"; # White

        urls = "5e81ac"; # Blue (regular4)
      };
      key-bindings.clipboard-paste = "Control+v XF86Paste";
    };
  };
}