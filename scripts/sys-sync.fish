#!/usr/bin/env fish

set mntPoint /mnt/alechomelab

## Pull music from shared homelab storage
read -l -P "[Sync] Enter NAS password: " passwd --silent
echo "[Sync] Pulling music from NAS"

# Mount share
mkdir -p $mntPoint
sudo mount.cifs //ALECHOMELAB.local/USB $mntPoint -o user=alec,password=$passwd

# Check & get mounted drive from share
set drives (find $mntPoint -mindepth 1 -maxdepth 1 -type d)
if test (count $drives) -eq 1
    set driveDir $drives[1]
else
    echo "Improper drive amount detected"
    exit 1
end

# Sync music directory from share 
rsync -av --ignore-existing "$driveDir/Music/" /home/alec/Music/
mpc update > /dev/null
sudo umount /mnt/alechomelab

## Update system
cd /home/alec/Projects/flake/
set isDirty (git status --porcelain)

if test -n "$isDirty"
    echo "[Sync] System flake is dirty - not updating system"
else
    if test (git rev-parse HEAD) == (git rev-parse @{u})
        echo "[Sync] No new changes in flake repository - not updating system"
    else
        git pull # Pull changes
        sudo nixos-rebuild switch --flake /home/alec/Projects/flake/ # Rebuild
    end
end

# Update last sync time for Astal integration
date +%s%3N > /home/alec/Projects/flake/ags/lastSync.txt
