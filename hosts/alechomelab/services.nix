{ pkgs, homelabDisplay, ... }:

let
  service = { # basic service config
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Restart = "always";
      RestartSec = 5;
    };
  };
  privileges = { # Fix webserver stuff
    NoNewPrivileges = false;
    PrivateUsers = false;
  };
in {
  systemd = {
    services = {
      # requires /etc/homelab/webserver.env with AIRNOW_TOKEN=
      webserver = service // {
        path = [ pkgs.util-linux ];
        serviceConfig = service.serviceConfig // privileges // {
          EnvironmentFile = "/etc/homelab/webserver.env";
          ExecStart = "${pkgs.bun}/bin/bun ${./webserver}/webserver.js";
        };
      };
      homelabDisplay = service // {
        serviceConfig = service.serviceConfig // privileges // {
          #ExecStartPre = "/bin/sh -c 'until test -c /dev/spidev0.0; do sleep 1; done'";
          ExecStart = "${homelabDisplay}/bin/homelabDisplay";
        };
      };
      lofi = service // {
        serviceConfig = service.serviceConfig // privileges // {
          ExecStart = "${pkgs.php82}/bin/php -S 0.0.0.0:9000 -t /media/lofi/";
        };
      };

      daily.script = ''
        ${pkgs.fish}/bin/fish ${./scripts}/githubBackup.fish
        ${pkgs.fish}/bin/fish ${./scripts}/spotifySync.fish

        ${pkgs.toybox}/bin/date +%s > /home/alec/lastSynced
      '';
    };

    timers."daily" = { # Every morning at 3AM PT
      wantedBy = [ "timers.target" ];
      partOf = [ "daily.service" ];
      timerConfig.OnCalendar = "*-*-* 03:00:00";
    };
  };
}
