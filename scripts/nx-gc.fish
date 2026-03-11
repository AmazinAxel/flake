#!/usr/bin/env fish

# Delete stuff
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
nix-env --delete-generations old
nix-collect-garbage -d # user-collected garbage
sudo nix-collect-garbage -d

# Optimize/trim
sudo nix-store --optimise
fstrim -av
