#!/usr/bin/env fish

source (dirname (status filename))/logging.fish

# Check whether drive is mounted
if not mountpoint -q /media
    log "GH: no drive"
    exit 1
end

mkdir -p /media/Projects
set token (cat /home/alec/GithubToken | string trim -r -c '\n')
set -x GIT_CONFIG_COUNT 9
set -x GIT_CONFIG_KEY_0 safe.directory
set -x GIT_CONFIG_VALUE_0 '*'

# reduce mem usage
set -x GIT_CONFIG_KEY_1 pack.threads
set -x GIT_CONFIG_VALUE_1 1
set -x GIT_CONFIG_KEY_2 index.threads
set -x GIT_CONFIG_VALUE_2 1
set -x GIT_CONFIG_KEY_3 pack.windowMemory
set -x GIT_CONFIG_VALUE_3 32m
set -x GIT_CONFIG_KEY_4 pack.deltaCacheSize
set -x GIT_CONFIG_VALUE_4 16m
set -x GIT_CONFIG_KEY_5 core.packedGitLimit
set -x GIT_CONFIG_VALUE_5 64m
set -x GIT_CONFIG_KEY_6 core.packedGitWindowSize
set -x GIT_CONFIG_VALUE_6 16m
set -x GIT_CONFIG_KEY_7 gc.auto
set -x GIT_CONFIG_VALUE_7 0
set -x GIT_CONFIG_KEY_8 maintenance.auto
set -x GIT_CONFIG_VALUE_8 false

for row in (curl -s -H "Authorization: token $token" https://api.github.com/user/repos?per_page=100 | jq -r '.[] | "\(.id)\t\(.full_name)"')
    set fields (string split \t $row)
    set repoId $fields[1]
    set repo $fields[2]

    string match -q 'AmazinAxel/*' $repo; or continue

    set repoName (string split '/' $repo)[2]
    set targetDir "/media/Projects/$repoName"
    set cleanUrl "https://github.com/$repo.git" # origin
    set authUrl "https://AmazinAxel:$token@github.com/$repo.git" # used only for the fetch

    # renames
    if not test -d "$targetDir/.git"
        for dir in /media/Projects/*/
            test -d "$dir/.git"; or continue
            if test (git -C "$dir" config --local --get homelab.repoid 2>/dev/null) = "$repoId"
                echo "Repo renamed: "(basename $dir)" -> $repoName, moving local copy"
                mv "$dir" "$targetDir"
                break
            end
        end
    end

    if test -d "$targetDir/.git"
        echo "Pulling repo $repoName"
        git -C "$targetDir" remote set-url origin "$cleanUrl" 2>/dev/null
        or git -C "$targetDir" remote add origin "$cleanUrl"
        git -C "$targetDir" config --local homelab.repoid "$repoId"
        git -C "$targetDir" fetch "$authUrl"
        and git -C "$targetDir" reset --hard FETCH_HEAD
        and git -C "$targetDir" clean -fd
    else
        echo "Cloning repo $repoName"
        if git clone "$authUrl" "$targetDir"
            git -C "$targetDir" remote set-url origin "$cleanUrl" # no token
            git -C "$targetDir" config --local homelab.repoid "$repoId"
        end
    end
end

log "GH: pulled repos"
