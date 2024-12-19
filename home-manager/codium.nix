{ pkgs, lib, ... }: {
    programs.vscode = {
        enable = true;
        package = pkgs.vscodium;
        extensions = with pkgs.vscode-extensions; [ 
            arcticicestudio.nord-visual-studio-code # Nord theme
            jnoortheen.nix-ide # Nix syntax highlighting
            mechatroner.rainbow-csv # CSV syntax highlighting
            ms-python.python # Rich Python support
            davidanson.vscode-markdownlint # Markdown linter & spellcheck
            yzhang.markdown-all-in-one # Markdown ToC, keybinds, preview support 
            github.vscode-github-actions # Github Actions lint
            dbaeumer.vscode-eslint # ESlint integration
            ms-vscode.live-server # Local HTTP dev server
            svelte.svelte-vscode # Svelte support
        ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [{
            name = "Sk-VSC";
            publisher = "ayhamalali";
            version = "2.6.6";
            sha256 = "sha256-hTMSi3UTbum+mht9ELWReAX8V5/s61/f7iFEj70xj7Q";
        }
        {
            name = "vscode-nbt";
            publisher = "Misodee";
            version = "0.9.3";
            sha256 = "sha256-47AO385wHsiMquXX6YvhWbCkjOENzB4DECgwMCpeSv4";
        }];

        userSettings = {
            "explorer.confirmDelete" = false;
            "window.titleBarStyle" = "custom";
            "git.enableSmartCommit" = true;
            "git.confirmSync" = false;
            "git.autofetch" = true;
            "workbench.startupEditor" = "fish";

            "terminal.integrated.profiles.linux" = {
                fish = {
                    path = "fish";
                    icon = "terminal-bash";
                };
                tmux = {
                    path = "tmux";
                    icon = "terminal-tmux";
                };
            };
            "terminal.integrated.defaultProfile.linux" = "fish";
            "svelte.enable-ts-plugin" = true;
            "editor.fontFamily" = "'Iosevka', 'monospace', monospace";
            "editor.fontLigatures" = "'calt'";
            "explorer.confirmPasteNative" = false;
            "workbench.colorTheme" = "Nord"; # Enable Nord theme - requires VSCodium to restart
            "workbench.editor.empty.hint" = "hidden";
            "explorer.confirmDragAndDrop" = false;
            "javascript.updateImportsOnFileMove.enabled" = "always";
            "diffEditor.ignoreTrimWhitespace" = false;
            "livePreview.serverRoot" = "public/";
            "editor.minimap.enabled" = false;
        };
    };
}
