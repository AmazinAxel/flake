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
pass git pull --rebase

if test (pass git rev-list '@{u}..HEAD' --count) -gt 0
    echo \n"[Sync] Passwords modified"
    pass git push
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
    git clone $bookmarksRemote $bookmarksDir
else
    git -C $bookmarksDir pull --rebase
    git -C $bookmarksDir add -A
    git -C $bookmarksDir diff --cached --quiet
    or git -C $bookmarksDir commit -q -m "sync: "(date '+%Y-%m-%d %H:%M')
    git -C $bookmarksDir push
end

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
