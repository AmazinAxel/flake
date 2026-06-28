{ inputs, ... }: {
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # sudo install -Dm600 <(grep '^alec:' /etc/shadow | cut -d: -f2) /persist/passwords/alec
  users.users.alec.hashedPasswordFile = "/persist/passwords/alec";

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "size=4G" "mode=755" ];
  };
  fileSystems."/nix" = {
    device = "/persist/nix";
    fsType = "none";
    options = [ "bind" ];
    neededForBoot = true;
    depends = [ "/persist" ];
  };

  environment.persistence."/persist" = {
    hideMounts = true;

    # System / machine state
    directories = [
      "/var/lib/nixos" # uid/gid map
      "/var/lib/systemd" # backlight
      "/var/lib/bluetooth" # paired devices
      "/var/lib/iwd" # wifi networks
      "/var/log" # journald history across reboots
    ];
    files = [
      "/etc/machine-id" # stable id
    ];

    users.alec = {
      directories = [
        ".ssh"
        ".gnupg"
        ".password-store"
        ".local/share/keyrings" # gnome-keyring

        # Desktop settings
        ".config/dconf"

        # XDG user data
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
        "Music"
        "Desktop"
        "Projects"
        "Models"

        # Shell
        ".local/share/fish" # history

        ".config/discord"
        ".config/Slack"
        ".config/filezilla"
        ".local/share/PrismLauncher"
        ".claude"
        ".config/zen"
        ".config/lightbrowse"
        ".cache/lightbrowse"
        ".config/spotify"
        ".cache/spotify"
        ".local/share/mpd"
        ".config/Code"

        ".cache/mesa_shader_cache"
        ".cache/mesa_shader_cache_db"
        ".cache/radv_builtin_shaders"
        ".cache/qtshadercache-x86_64-little_endian-lp64"
      ];
      files = [
        ".claude.json"
        ".git-credentials"
        ".gitconfig"
        "Safe.kdbx"
      ];
    };
  };
}
