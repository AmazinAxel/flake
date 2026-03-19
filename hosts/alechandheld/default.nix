{ pkgs, ... }:

let
  volumeKeysScript = pkgs.writeShellScript "volume-keys" ''
    DEV=""
    for f in /sys/class/input/event*/device/name; do
      if [ "$(cat "$f" 2>/dev/null)" = "gpio-keys-volume" ]; then
        num=$(echo "$f" | grep -o 'event[0-9]*')
        DEV="/dev/input/$num"
        break
      fi
    done
    [ -z "$DEV" ] && exit 1

    ${pkgs.evtest}/bin/evtest "$DEV" | while IFS= read -r line; do
      case "$line" in
        *"(KEY_VOLUMEUP), value 1"*|*"(KEY_VOLUMEUP), value 2"*)
          echo -n "VOLUME_UP" > /dev/udp/127.0.0.1/55355 || true
          ;;
        *"(KEY_VOLUMEDOWN), value 1"*|*"(KEY_VOLUMEDOWN), value 2"*)
          echo -n "VOLUME_DOWN" > /dev/udp/127.0.0.1/55355 || true
          ;;
      esac
    done
  '';
in {
  # sudo nixos-rebuild boot --flake .#alechandheld --target-host alec@10.0.0.169 --sudo --ask-sudo-password --no-reexec --option system "aarch64-linux"
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ./customKernel.nix
  ];

  environment.systemPackages = with pkgs; [
    gitMinimal
    (retroarch.withCores (cores: with cores; [
      # eeeee todo
    ]))
  ];

  home-manager.users.alec.imports = [ ./hm.nix ];

  programs.gamemode.enable = true;

  zramSwap.enable = false; # Breaks boot if enabled

  services = {
    cage = {
      enable = true;
      user = "alec";
      program = "${pkgs.gamemode}/bin/gamemoderun ${pkgs.retroarch}/bin/retroarch";
      extraArguments = [ "-s" ]; # Allow TTY switching
    };
    sshd.enable = true;
    libinput.enable = true;
    earlyoom = {
      enable = true;
      freeMemThreshold = 5;
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
    };
  };

  systemd.services.volume-keys = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "alec";
      SupplementaryGroups = [ "input" ];
      ExecStart = volumeKeysScript;
      Restart = "always";
      RestartSec = "2s";
    };
  };

  networking = {
    wireless.iwd.enable = false; # todo switch to iwd?
    networkmanager.enable = true;
    hostName = "alechandheld";
    firewall.enable = false; # causes errors
  };

  hardware.graphics.enable = true; # Mesa/OpenGL
  security.rtkit.enable = true; # realtime priority for pw

  powerManagement.cpuFreqGovernor = "schedutil"; # idk what this does

  systemd.services.NetworkManager-wait-online.enable = false; # waiting not needed

  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 0;
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
  };

  users.users.alec.extraGroups = [ "input" "gpio" "i2c" "gamemode" ];
  nix.settings.trusted-users = [ "alec" ]; # Remote deployment

  services.journald.extraConfig = "Storage=volatile"; # Extend SD card lifespan
}
