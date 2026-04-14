#!/usr/bin/env fish

source /home/alec/homelab/scripts/logging.fish # Logging

# Check whether drive is mounted
if not mountpoint -q /media
    log "GH: no drive"
    exit 1
end

mkdir -p /media/Projects
set token (cat /home/alec/GithubToken | string trim -r -c '\n')

# Download & sync all repositories
for repo in (curl -s -H "Authorization: token $token" https://api.github.com/user/repos?per_page=100 | jq -r '.[].full_name')
    if string match -q 'AmazinAxel/*' $repo
        set repoName (string split '/' $repo)[2]
        set targetDir "/media/Projects/$repoName"

        if test -d "$targetDir/.git"
            echo "Pulling repo $repoName"
            git -C "$targetDir" pull https://AmazinAxel:$token@github.com/$repo.git
        else
            echo "Cloning repo $repoName"
            git clone https://AmazinAxel:$token@github.com/$repo.git "$targetDir"
        end
    end
end

log "GH: pulled repos"
