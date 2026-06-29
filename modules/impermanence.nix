{ inputs, lib, ... }: {
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  # sudo install -Dm600 <(grep '^alec:' /etc/shadow | cut -d: -f2) /persist/passwords/alec
  users = {
    users.alec = {
      hashedPasswordFile = "/persist/passwords/alec";
      initialPassword = lib.mkForce null; # todo will NEVER be necessary when we are finished with impermanence config
    };
    mutableUsers = false;
  };

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
    allowTrash = true;

    # System / machine state
    directories = [
      "/var/lib/nixos" # uid/gid map
      "/var/lib/systemd" # backlight
      "/var/lib/bluetooth" # bt paired devices
      "/var/lib/iwd" # saved networks
      "/var/log" # journald history across reboots
      "/root/.cache/nix" # flake cache
    ];
    files = [
      "/etc/machine-id" # stable id
    ];

    users.alec = {
      directories = [
        "Documents"
        "Downloads"
        "Pictures"
        "Videos"
        "Music"
        "Desktop"
        "Projects"
        "Models"
        # ".local/share/Trash"

        # keys
        ".ssh"
        ".gnupg"
        ".password-store"

        ".local/share/fish" # shell history
        ".local/share/git" # github login

        # apps
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
        ".local/share/ags-sideview"
        ".cache/ags-sideview"

        # GPU cache
        ".cache/mesa_shader_cache"
        ".cache/mesa_shader_cache_db"
        ".cache/radv_builtin_shaders"
        ".cache/qtshadercache-x86_64-little_endian-lp64"
      ];
      files = [ ".claude.json" ]; # claude login
    };
  };
}
