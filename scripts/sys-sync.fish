#!/usr/bin/env fish

set mntPoint /mnt/alechomelab
read -l -P "[Sync] Enter NAS password: " passwd --silent

# Mount & sync from share
mkdir -p $mntPoint
sudo mount.cifs //ALECHOMELAB.local/USB $mntPoint -o user=alec,password=$passwd

echo \n"[Sync] Pulling music from NAS"
sudo rsync -av --ignore-existing "$mntPoint/Music/" /home/alec/Music/
mpc update > /dev/null
sudo umount $mntPoint

echo \n"[Sync] Pulling passwords"
pass git pull --rebase

if not pass git diff --quiet
    echo \n"[Sync] Passwords modified"
    pass git push
end

## Rebuild latest
cd /home/alec/Projects/flake/
set isDirty (git status --porcelain)

if test -n "$isDirty"
    echo \n"[Sync] System flake is dirty - not updating system"
else
    git pull
    sudo nixos-rebuild boot --flake /home/alec/Projects/flake/
end

# Astal
date +%s%3N > /home/alec/Projects/flake/ags/lastSync.txt
