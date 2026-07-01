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
      "/var/lib/iwd" # saved networks
      "/root/.cache/nix" # flake cache
    ];
    files = [
      "/etc/machine-id" # stable id
    ];

    users.alec.directories = [
      ".local/share/fish" # shell history
      ".local/share/git" # github login
    ];
  };
}
