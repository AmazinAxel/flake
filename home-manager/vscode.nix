{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        arcticicestudio.nord-visual-studio-code
        jnoortheen.nix-ide
        mechatroner.rainbow-csv
        davidanson.vscode-markdownlint # .md lint & spellcheck
        yzhang.markdown-all-in-one # .md keybinds, preview support
        github.vscode-github-actions
        dbaeumer.vscode-eslint
        ms-vscode.live-server
        svelte.svelte-vscode
        ms-vsliveshare.vsliveshare
      ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
        name = "Sk-VSC";
        publisher = "ayhamalali";
        version = "2.6.6";
        sha256 = "sha256-hTMSi3UTbum+mht9ELWReAX8V5/s61/f7iFEj70xj7Q";
      } {
        name = "vscode-nbt";
        publisher = "Misodee";
        version = "0.9.3";
        sha256 = "sha256-47AO385wHsiMquXX6YvhWbCkjOENzB4DECgwMCpeSv4";
      }];

      userSettings = {
        editor = {
          wordWrap = "on";
          fontFamily = "'Iosevka'";
          fontLigatures = "'calt'"; # Iosevka ligatures
          confirmPasteNative = false;
          minimap.enabled = false;
        };
        explorer = {
          confirmDelete = false;
          confirmDragAndDrop = false; # No drag & drop popup
          confirmPasteNative = false; # No image paste popup
        };
        git = {
          enableSmartCommit = true;
          confirmSync = false;
          autofetch = true;
        };
        workbench = {
          startupEditor = "fish";
          colorTheme = "Nord"; # Enable theme
        };
        chat.disableAIFeatures = true;
        terminal.integrated = {
          defaultProfile.linux = "fish";
          profiles.linux.fish = {
            path = "fish";
            icon = "terminal-bash";
          };
        };
        svelte.enable-ts-plugin = true; # Svelte TS intellisense
        window.titleBarStyle = "custom"; # Fix Wayland bug
        javascript.updateImportsOnFileMove.enabled = "always";
        typescript.updateImportsOnFileMove.enabled = "always";
        diffEditor.ignoreTrimWhitespace = false; # Keep diff viewer clean
        markdownlint.focusMode = 5; # Don't show nearby Markdown warnings when typing
      };
    };
  };
}
