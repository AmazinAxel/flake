#!/usr/bin/env fish

sudo nix-collect-garbage -d --delete-older-than 1d

# Run without sudo to clear garbage on user
nix-collect-garbage -d --delete-older-than 1d

sudo nix-store --optimise

# Trim drives - especially after deleting a bunch of stuff
fstrim -av