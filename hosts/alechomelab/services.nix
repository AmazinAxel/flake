{ pkgs, inputs, ... }:

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
      # /etc/homelab/webserver.env with AIRNOW_TOKEN=
      webserver = service // {
        path = [ pkgs.util-linux ];
        serviceConfig = service.serviceConfig // privileges // {
          EnvironmentFile = "/etc/homelab/webserver.env";
          ExecStart = "${pkgs.bun}/bin/bun ${./webserver}/webserver.js";
        };
      };
      homelabDisplay = service // {
        serviceConfig = service.serviceConfig // privileges // {
          ExecStart = "${inputs.homelab.packages.aarch64-linux.homelabDisplay}/bin/homelabDisplay";
        };
      };
      # lofi = service // {
      #   serviceConfig = service.serviceConfig // privileges // {
      #     ExecStart = "${pkgs.php82}/bin/php -S 0.0.0.0:9000 -t /media/lofi/";
      #   };
      # };

      daily = {
        path = with pkgs; [ util-linux curl jq gawk spotdl toybox fish git ];
        script = ''
          fish ${./scripts}/githubBackup.fish
          fish ${./scripts}/spotifySync.fish

          date +%s > /home/alec/lastSynced
        '';
        serviceConfig = {
          MemoryHigh = "150M";
          MemoryMax = "250M"; # hard cap
          OOMScoreAdjust = 500; # kill first
          CPUWeight = 10;
          IOWeight = 10;
          IOSchedulingClass = "idle";
          Nice = 19;
        };
      };
    };

    timers."daily" = { # Every morning at 3AM PT
      wantedBy = [ "timers.target" ];
      partOf = [ "daily.service" ];
      timerConfig.OnCalendar = "*-*-* 03:00:00";
    };
  };
}
