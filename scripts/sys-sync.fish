#!/usr/bin/env fish

set mntPoint /mnt/alechomelab
read -l -P "[Sync] Enter password: " passwd --silent
echo

function s --inherit-variable passwd
    echo $passwd | sudo -S -p '' $argv
end

# Mount & sync from share
mkdir -p $mntPoint
s mount.cifs //ALECHOMELAB.local/USB $mntPoint -o user=alec,password=$passwd

echo \n"[Sync] Pulling music from NAS"
s rsync -av --ignore-existing "$mntPoint/Music/" /home/alec/Music/
mpc update >/dev/null
s umount $mntPoint

echo \n"[Sync] Pulling passwords"
set -x SYS_SYNC_PASS $passwd
set askpass (mktemp)
echo '#!/bin/sh
printf "%s\n" "$SYS_SYNC_PASS"' >$askpass
chmod +x $askpass
set -x GIT_ASKPASS $askpass
set -x SSH_ASKPASS $askpass
set -x SSH_ASKPASS_REQUIRE force
set -x DISPLAY :0
setsid -w pass git pull --rebase </dev/null

if test (pass git rev-list '@{u}..HEAD' --count) -gt 0
    echo \n"[Sync] Passwords modified"
    setsid -w pass git push </dev/null
end

set sshDir /home/alec/.ssh
mkdir -p $sshDir
chmod 700 $sshDir
set keyEntries /home/alec/.password-store/ssh/*.gpg # if this is empty it wont loop
for f in $keyEntries
    set name (basename $f .gpg)
    test -e $sshDir/$name; and continue # skip if installed?
    string match -q '*.pub' $name; and set mode 644; or set mode 600 # .pub is not secret
    pass show ssh/$name | install -m $mode /dev/stdin $sshDir/$name
    and echo "[Sync] Installed ssh key $name"
end

echo \n"[Sync] Syncing bookmarks"
set bookmarksDir /home/alec/.config/lightbrowse/bookmarks
set bookmarksRemote ssh://alec@alechomelab.local/media/bookmarks

if not test -d $bookmarksDir/.git
    echo "[Sync] Cloning bookmarks..."
    setsid -w git clone $bookmarksRemote $bookmarksDir </dev/null
else
    setsid -w git -C $bookmarksDir pull --rebase </dev/null
    git -C $bookmarksDir add -A
    git -C $bookmarksDir diff --cached --quiet
    or git -C $bookmarksDir commit -q -m "sync: "(date '+%Y-%m-%d %H:%M')
    setsid -w git -C $bookmarksDir push </dev/null
end

rm $askpass
set -e SYS_SYNC_PASS
set -e GIT_ASKPASS
set -e SSH_ASKPASS
set -e SSH_ASKPASS_REQUIRE
set -e DISPLAY

## Rebuild latest
cd /home/alec/Projects/flake/
set isDirty (git status --porcelain)

if test -n "$isDirty"
    echo \n"[Sync] System flake is dirty - not updating system"
else
    git pull
    s nixos-rebuild boot --flake 'path:/home/alec/Projects/flake/' --impure
end

# Astal
date +%s%3N >/home/alec/Projects/flake/ags/lastSync.txt
