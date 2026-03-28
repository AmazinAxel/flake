{ inputs, ... }: {
  imports = [ inputs.zen-browser.homeModules.beta ];

  programs.zen-browser = {
    enable = true;
    setAsDefaultBrowser = true;

    profiles.default = {
      settings = { # Other settings are managed by Mozilla settings sync
        "identity.fxaccounts.enabled" = true;
        "toolkit.tabbox.switchByScrolling" = true;
        "mousewheel.min_line_scroll_amount" = 30;

        # middle mouse fixes
        "middlemouse.paste" = false;
        "middlemouse.contentLoadURL" = false;

        "zen.view.compact.hide-toolbar" = true;
        "zen.view.compact.toolbar-hide-after-hover.duration" = 500;
        "zen.watermark.enabled" = false;
        "zen.urlbar.wait-to-clear" = 5000;
      };

      search = {
        force = true;
        engines = {
          "MyNixOS" = {
            urls = [{
              template = "https://mynixos.com/search";
              params = [{ name = "q"; value = "{searchTerms}"; }];
            }];
            definedAliases = [ "@nix" ];
            icon = "https://mynixos.com/favicon.ico";
            updateInterval = 24 * 60 * 60 * 1000;
          };
        };
      };

      mods = [
        "ad97bb70-0066-4e42-9b5f-173a5e42c6fc" # better pins/essentials
        "a6335949-4465-4b71-926c-4a52d34bc9c0" # better find bar
        "1e86cf37-a127-4f24-b919-d265b5ce29a0" # remove toolbar clutter
        "81fcd6b3-f014-4796-988f-6c3cb3874db8" # declutter context menu
        "c6813222-6571-4ba6-8faf-58f3343324f6" # remove rounded corners
        "4ab93b88-151c-451b-a1b7-a1e0e28fa7f8" # no sidebar scrollbar
        "d8b79d4a-6cba-4495-9ff6-d6d30b0e94fe" # better active tab highlight
        "e51b85e6-cef5-45d4-9fff-6986637974e1" # smaller toast
      ];
    };
  };
}
