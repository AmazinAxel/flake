{ pkgs, ... }: {
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        arcticicestudio.nord-visual-studio-code # Nord theme
        jnoortheen.nix-ide # Nix syntax highlighting
        mechatroner.rainbow-csv # CSV syntax highlighting
        ms-python.python # Python support
        davidanson.vscode-markdownlint # Markdown lint & spellcheck
        yzhang.markdown-all-in-one # Markdown ToC, keybinds, preview support
        github.vscode-github-actions # Github Actions highlighting
        dbaeumer.vscode-eslint # ESlint integration
        ms-vscode.live-server # Local HTTP dev server
        svelte.svelte-vscode # Svelte support
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
          fontFamily = "'Iosevka'"; # Iosevka ftw
          fontLigatures = "'calt'"; # Iosevka ligatures
          confirmPasteNative = false;
          minimap.enabled = false;
        };
        explorer = {
          confirmDelete = false;
          confirmDragAndDrop = false; # Disable drag & drop popup
          confirmPasteNative = false; # Disable image paste popup
        };
        git = {
          enableSmartCommit = true;
          confirmSync = false;
          autofetch = true;
        };
        workbench = {
          startupEditor = "fish";
          colorTheme = "Nord"; # Enable theme - requires VSCodium restart
        };
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
        
        livePreview.serverRoot = "public/"; # For Journal writing previews
        markdownlint.focusMode = 5; # Don't show nearby Markdown warnings when typing
      };
    };
  };
}
