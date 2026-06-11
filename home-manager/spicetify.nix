{ inputs, pkgs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;

    # fix wayland
    spotifyPackage = pkgs.spotify.overrideAttrs (old: {
      nativeBuildInputs = (old.nativeBuildInputs or []) ++ [ pkgs.makeWrapper ];
      postFixup = (old.postFixup or "") + ''
        wrapProgram $out/bin/spotify --unset DISPLAY
      '';
    });

    theme = spicePkgs.themes.hazy;

    enabledExtensions = with spicePkgs.extensions; [
      autoSkipVideo
      #adblock
      adblockify
      keyboardShortcut
      aiBandBlocker
      shuffle
      sideHide
      hidePodcasts
    ];
  };
}
