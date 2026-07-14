#!/usr/bin/env fish

# sudo chattr -i /persist/var/empty && sudo rm -rf /persist/var/empty

set -l persist /persist
set -l dev (awk -v m=$persist '$5==m && $4=="/" {print $3; exit}' /proc/self/mountinfo)

if test (id -u) -ne 0
    echo "persist-prune: run as root (sudo persist-prune)" >&2
    exit 1
end

set -g __pp_keep (awk -v d=$dev '$3==d && $4!="/" {sub(/^\//,"",$4); print $4}' /proc/self/mountinfo | sort -u)
set -a __pp_keep nix passwords swapfile lost+found
set -g __pp_root $persist
set -g __pp_stale

# rel is kept itself or lives inside a kept path → keep the whole subtree.
function __pp_kept -a rel
    contains -- $rel $__pp_keep; and return 0
    for k in $__pp_keep
        string match -q -- "$k/*" $rel; and return 0
    end
    return 1
end

# rel is an ancestor of a kept path → descend to reach the kept bit.
function __pp_ancestor -a rel
    for k in $__pp_keep
        string match -q -- "$rel/*" $k; and return 0
    end
    return 1
end

function __pp_walk -a dir
    for child in (find $dir -mindepth 1 -maxdepth 1 -print0 2>/dev/null | string split0)
        test -L "$child"; and continue # never follow or delete symlinks
        set -l rel (string replace -- $__pp_root/ '' $child)
        if __pp_kept $rel
            continue
        else if __pp_ancestor $rel
            __pp_walk $child
        else
            set -a __pp_stale $child
        end
    end
end

__pp_walk $persist

if test (count $__pp_stale) -eq 0
    echo "persist-prune: clean — everything under $persist is still persisted."
    exit 0
end

echo "persist-prune: on $persist but no longer persisted:"
echo
for p in $__pp_stale
    printf '%8s  %s\n' (du -sh $p 2>/dev/null | cut -f1) $p
end
echo

read -l -P "Delete these "(count $__pp_stale)" path(s)? This cannot be undone. [y/N] " ans
switch $ans
    case y Y yes YES
        for p in $__pp_stale
            rm -rf $p; and echo "removed $p"
        end
    case '*'
        echo "aborted — nothing deleted."
end
