# no shebang so i can run this on a pi without fish

# Delete stuff
sudo nix-env --delete-generations old --profile /nix/var/nix/profiles/system
nix-env --delete-generations old
nix-collect-garbage -d # user-collected garbage
sudo nix-collect-garbage -d

# Optimize/trim
sudo nix-store --optimise
sudo fstrim -av
