{ inputs, ... }: {
  imports = [ inputs.impermanence.nixosModules.impermanence ];

  environment.persistence."/persist" = {
    hideMounts = true;
    allowTrash = true;

    # System / machine state
    directories = [
      "/var/lib/nixos" # uid/gid map
      "/root/.cache/nix" # flake cache
      "/etc/ssh" # host keys for ssh
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
