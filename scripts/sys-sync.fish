#!/usr/bin/env fish

set mntPoint /mnt/alechomelab

## Pull music from shared homelab storage
read -l -P "[Sync] Enter NAS password: " passwd --silent

# Mount share
mkdir -p $mntPoint
sudo mount.cifs //ALECHOMELAB.local/USB $mntPoint -o user=alec,password=$passwd

# Sync music directory from share 
echo "[Sync] Pulling music from NAS"
sudo rsync -av --ignore-existing "$mntPoint/Music/" /home/alec/Music/
mpc update > /dev/null
sudo umount $mntPoint

## Update system
cd /home/alec/Projects/flake/
set isDirty (git status --porcelain)

if test -n "$isDirty"
    echo "[Sync] System flake is dirty - not updating system"
else
    git pull
    sudo nixos-rebuild switch --flake /home/alec/Projects/flake/
end

# Update last sync time for Astal integration
date +%s%3N > /home/alec/Projects/flake/ags/lastSync.txt