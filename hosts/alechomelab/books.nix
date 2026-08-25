{ pkgs, inputs, ... }:

# Auto-convert EPUBs for the wintergreen e-reader.
#
# Drop a .epub into /media/books over Samba; a path unit notices and converts it
# into /media/books/.compiled/<stem>/. The reader pulls only the compiled form
# over HTTP (see webserver/booksync.js), so it never parses an EPUB itself and
# never sees the originals.

let
  epub2wgb = inputs.wintergreen.packages.aarch64-linux.epub2wgb;
in {
  systemd.tmpfiles.rules = [
    "d /media/books 0775 alec users -"
    "d /media/books/.compiled 0775 alec users -"
  ];

  systemd.paths.book-convert = {
    wantedBy = [ "multi-user.target" ];
    pathConfig = {
      DirectoryNotEmpty = "/media/books";
      MakeDirectory = false;
    };
  };

  systemd.services.book-convert = {
    path = [ epub2wgb pkgs.fish pkgs.coreutils pkgs.curl ];
    serviceConfig = {
      Type = "oneshot";
      # A Pi Zero 2 shares this machine with the air-quality webserver, and a
      # conversion is CPU- and IO-heavy for tens of seconds. Never let it stall
      # the thing people actually look at.
      Nice = 15;
      IOSchedulingClass = "idle";
      CPUSchedulingPolicy = "idle";
    };
    script = ''
      fish ${./scripts/convertBooks.fish}
    '';
  };
}
