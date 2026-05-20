{ pkgs, ... }:
let
  serverDir = "/var/lib/permafrost";
in {
  environment.systemPackages = [
    (pkgs.writeShellScriptBin "pf-sync" ''
      set -euo pipefail

      if systemctl is-active --quiet minecraft-server; then
        sudo systemctl stop minecraft-server
      fi

      cd ${serverDir}
      sudo -u minecraft git pull --rebase

      sudo systemctl start minecraft-server
    '')

    (pkgs.writeShellScriptBin "pf-stop" ''
      set -euo pipefail

      if systemctl is-active --quiet minecraft-server; then
        sudo systemctl stop minecraft-server
      fi

      cd ${serverDir}

      sudo -u minecraft git pull --rebase || true
      sudo -u minecraft git add -A
      sudo -u minecraft git reset -q -- 'Permafrost' 'Permafrost/*' 'server.properties' 2>/dev/null || true

      # commit message
      if ! sudo -u minecraft git diff --cached --quiet; then
        date_str=$(date +%-m/%-d/%y)

        top_files=$(sudo -u minecraft git diff --cached --numstat \
          | awk '$1 != "-" { print $1+$2"\t"$3 }' \
          | sort -rn \
          | head -3 \
          | cut -f2 \
          | xargs -n1 basename \
          | paste -sd ', ')

        description=$(sudo -u minecraft git diff --cached --numstat \
          | awk '$1 != "-" { printf "%d\t- %s (+%s/-%s)\n", $1+$2, $3, $1, $2 }' \
          | sort -rn \
          | cut -f2-)

        msg="feat: sync $date_str $top_files"

        sudo -u minecraft git commit -m "$msg" -m "$description"
        sudo -u minecraft git push
      else
        echo "[permafrost stop] No major tracked changes"
      fi

      sudo systemctl poweroff
    '')
  ];
}
