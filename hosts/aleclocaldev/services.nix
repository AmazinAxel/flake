{ pkgs, planning, ... }:

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
      homelabDisplay = service // {
        serviceConfig = service.serviceConfig // privileges // {
          ExecStart = "/home/alec/homelab/display/homelabDisplay";
        };
      };
      lofi = service // {
        serviceConfig = service.serviceConfig // privileges // {
          ExecStart = "${pkgs.php82}/bin/php -S 0.0.0.0:9000 -t /media/lofi/";
        };
      };
      planning = let 
        theme = pkgs.graphite-gtk-theme.override {
          tweaks = [ "nord" ];
          themeVariants = [ "default" ];
          colorVariants = [ "dark" ];
        };
      in service // {
        after = [ "planning-broadway.service" ];
        requires = [ "planning-broadway.service" ];
        environment = {
          GDK_BACKEND = "broadway";
          BROADWAY_DISPLAY = ":5";
          GTK_THEME = "Graphite-Dark-nord";
          XDG_DATA_DIRS = "${theme}/share:${pkgs.adwaita-icon-theme}/share:${pkgs.hicolor-icon-theme}/share";
        }; # MUST RUN mkdir -p /home/alec/.config/planning
        serviceConfig = service.serviceConfig // {
          User = "alec";
          WorkingDirectory = "/home/alec/";
          ExecStart = "${planning}/bin/planning";
        };
      };
      planning-broadway = service // {
        serviceConfig = service.serviceConfig // {
          User = "alec";
          ExecStart = "${pkgs.gtk4}/bin/gtk4-broadwayd --port 8000 :5";
        };
      };

      daily.script = ''
        ${pkgs.fish}/bin/fish /home/alec/homelab/scripts/githubBackup.fish
        ${pkgs.fish}/bin/fish /home/alec/homelab/scripts/spotifySync.fish

        ${pkgs.toybox}/bin/time date +%s > /home/alec/lastSynced
      '';
    };

    timers."daily" = { # Every morning at 3AM PT
      wantedBy = [ "timers.target" ];
      partOf = [ "daily.service" ];
      timerConfig.OnCalendar = "*-*-* 03:00:00";
    };
  };
}
