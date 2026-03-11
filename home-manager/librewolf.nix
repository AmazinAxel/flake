{ pkgs, ... }: {
  programs.librewolf = {
    enable = true;

    # Other settings are managed by Mozilla settings sync
    settings = {
      "identity.fxaccounts.enabled" = true;
      "toolkit.tabbox.switchByScrolling" = true; # Scroll through tabs
      "mousewheel.min_line_scroll_amount" = 30; # Longer scrolls

      # middle mouse stuff
      "middlemouse.paste" = false;
      "middlemouse.contentLoadURL" = false;
    };
  };
}