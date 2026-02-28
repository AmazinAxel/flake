{
  xdg.configFile."satty/config.toml".text = ''
    [general]
    fullscreen = false
    early-exit = true
    corner-roundness = 10
    initial-tool = "brush"
    copy-command = "wl-copy"

    annotation-size-factor = 2
    default-hide-toolbars = true
    focus-toggles-toolbars = true
    default-fill-shapes = true
    primary-highlighter = "freehand"
    disable-notifications = true
    actions-on-enter = ["save-to-clipboard"]
    actions-on-escape = ["save-to-clipboard"]

    [keybinds]
    pointer = "p"
    crop = "c"
    brush = "b"
    line = "l"
    arrow = "a"
    rectangle = "r"
    ellipse = "e"
    text = "t"
    marker = "m"
    blur = "b"
    highlight = "h"

    [font]
    family = "Sora"
    style = "Regular"

    [color-palette]
    palette = [
      "#bf616a",
      "#81a1c1",
      "#a3be8c",
      "#4c566a",
      "#d8dee9"
    ]
  '';
}