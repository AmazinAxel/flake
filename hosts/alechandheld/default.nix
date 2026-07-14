{ pkgs, ... }:

let
  retroarchCustom = pkgs.retroarch-bare.overrideAttrs (old: {
    # dbus is needed so retroarch's bluez D-Bus bluetooth driver compiles in
    # (the alternative — bluetoothctl driver — screen-scrapes CLI output and
    # broke when bluez 5.86 changed non-interactive output flushing).
    buildInputs = (old.buildInputs or []) ++ [ pkgs.dbus ];
    configureFlags = old.configureFlags ++ [
      "--enable-opengles" # Mali GPU on H700 supports GLES, not full desktop GL
      "--enable-opengles3"
      "--enable-kms"
      #"--enable-neon" # ARM NEON SIMD

      "--enable-threads" # audio
      "--enable-wifi" # wifi menu
      "--enable-bluetooth" # bt menu
      "--enable-dbus" # enables the bluez D-Bus bluetooth driver (avoids fragile bluetoothctl scraping)

      # unused
      "--disable-v4l2" # camera
      "--disable-microphone" # no mic
      "--disable-x11"
      "--disable-vulkan" # not supported on this gpu
      "--disable-wayland"
      "--disable-qt" # no desktop ui needed
      "--disable-cdrom" # guh
      "--disable-discord" # rich presence
      "--disable-cheevos" # retroarchievements
      "--disable-langextra"
    ];
  });

  fake08Core = pkgs.stdenv.mkDerivation {
    pname = "libretro-fake-08";
    version = "unstable";
    src = pkgs.fetchFromGitHub {
      owner = "jtothebell";
      repo = "fake-08";
      rev = "f6bab5a7ba521ce440e45d1aeef6122674be6ee9";
      hash = "sha256-ngnZdo7bQFLcwLOM+J+7CZiTCjz+tgszdwePE6Ek/Jg=";
      fetchSubmodules = true;
    };
    buildPhase = "make -C platform/libretro platform=unix";
    installPhase = "install -Dt $out/lib/retroarch/cores platform/libretro/fake08_libretro.so";
    passthru.libretroCore = "/lib/retroarch/cores";
    passthru.core = "fake08";
  };
in {
  # sudo nixos-rebuild boot --flake .#alechandheld --target-host alec@10.0.0.169 --sudo --ask-sudo-password --no-reexec --option system "aarch64-linux"
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/tmpfs-root.nix

    ./customKernel.nix
    ./inputHandlers.nix
    ./menus.nix
    ./portmaster.nix
  ];

  # Host state worth surviving the tmpfs root (game data lives on the game
  # card instead — see portmaster.nix/hm.nix)
  environment.persistence."/persist".directories = [
    "/etc/NetworkManager/system-connections" # wifi credentials
    "/var/lib/bluetooth" # earbud pairings
  ];

  environment.systemPackages = with pkgs; [
    retroarchCustom
    fake08Core
    libretro.mgba
    libretro-core-info # has fake-08 core info too
  ];

  home-manager.users.alec.imports = [ ./hm.nix ];
  programs.gamemode.enable = true; # RetroArch requests priority boosts via gamemode D-Bus
  zramSwap.enable = false; # Breaks boot if enabled (also conflicts with hibernate below)

  # --- Hibernation (suspend-to-disk) ---
  # The H700 has no real deep/S3 suspend: mainline sunxi never registers a SoC
  # standby state, so /sys/power/mem_sleep only offers s2idle, which keeps DRAM
  # refreshed and the radios powered — flat battery in ~2 days.  ARM64 hibernation
  # is arch-generic (software snapshot, no PMIC firmware needed), so it works where
  # deep suspend can't: snapshot RAM to swap, then power fully off (~zero drain,
  # resumes where you left off).  Power button switches to hibernate once the
  # resume offset below is filled in.
  swapDevices = [ { device = "/persist/swapfile"; size = 2048; } ]; # >= 1 GB RAM
  boot.resumeDevice = "/dev/disk/by-uuid/44444444-4444-4444-8888-888888888888"; # mmcblk0p2 (/persist)

  services = {
    openssh.enable = true;
    fstrim.enable = true; # weekly TRIM — kinder to the SD card than continuous discard
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

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings.General.Experimental = true;
  };

  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (subject.user !== "alec") return;
      if (action.id.startsWith("org.bluez") ||
          action.id === "org.freedesktop.login1.power-off" ||
          action.id === "org.freedesktop.login1.reboot" ||
          action.id === "org.freedesktop.login1.suspend" ||
          action.id === "org.freedesktop.login1.hibernate" ||
          (action.id === "org.freedesktop.systemd1.manage-units" &&
           action.lookup("unit") === "oga_events.service")) {
        return polkit.Result.YES;
      }
    });
  '';

  services.logind.settings.Login = {
    HandlePowerKey = "hibernate"; # no deep/S3 on H700; hibernate for ~zero standby drain (see swapDevices)
    HandlePowerKeyLongPress = "poweroff";
  };

  # Minimal on purpose: the ONLY thing that genuinely doesn't self-recover across
  # hibernate is the ehci/ohci USB root hubs ("root hub lost power", never
  # re-enumerate → freeze on next plug), so rebind just those.  WiFi (rtw88
  # re-associates itself), the joypad (pad + uinput clone survive intact), and the
  # codec all come back on their own — earlier attempts to "help" them by
  # unbinding/restarting actively BROKE them (the wifi rebind deauth'd the
  # already-reconnected link; restarting handheld-inputd swapped the clone out from
  # under the running app).  musb/OTG is left alone too: it never loses power and
  # its rebind fails -EEXIST.  State is logged to /persist for verification.
  powerManagement.resumeCommands = ''
    exec > /persist/last-resume.log 2>&1
    echo "===== resume $(${pkgs.coreutils}/bin/date) ====="

    echo "[usb] rebind ehci/ohci"
    for _d in 5101000.usb 5200000.usb; do echo "$_d" > /sys/bus/platform/drivers/ehci-platform/bind 2>/dev/null || true; done
    for _d in 5101400.usb 5200400.usb; do echo "$_d" > /sys/bus/platform/drivers/ohci-platform/bind 2>/dev/null || true; done

    # Joypad: the H616 GPADC (5070000.adc) resumes dead — reads time out — and the
    # pad is a polled-ADC device, so the WHOLE pad (sticks + buttons) goes silent.
    # Rebinding the gpadc revives it (verified live: adc read TIMEOUT → rebind →
    # clean reads + events flowing).  The joypad driver holds the iio channels, so
    # it must be unbound around the gpadc rebind; inputd is stopped/started so it
    # deterministically re-grabs the fresh pad and republishes its uinput clone.
    # First joypad bind can hit a transient -EEXIST (leftover sysfs group), hence
    # the retry loop.
    echo "[joypad] gpadc rebind"
    ${pkgs.systemd}/bin/systemctl stop handheld-inputd 2>/dev/null || true
    echo rocknix-singleadc-joypad > /sys/bus/platform/drivers/rocknix-singleadc-joypad/unbind 2>/dev/null || true
    echo 5070000.adc > /sys/bus/platform/drivers/sun20i-gpadc/unbind 2>/dev/null || true
    ${pkgs.coreutils}/bin/sleep 1
    echo 5070000.adc > /sys/bus/platform/drivers/sun20i-gpadc/bind 2>/dev/null || echo "  gpadc bind FAILED"
    for _try in 1 2 3; do
      [ -e /sys/bus/platform/drivers/rocknix-singleadc-joypad/rocknix-singleadc-joypad ] && break
      echo rocknix-singleadc-joypad > /sys/bus/platform/drivers/rocknix-singleadc-joypad/bind 2>/dev/null || true
      ${pkgs.coreutils}/bin/sleep 1
    done
    ${pkgs.systemd}/bin/systemctl start handheld-inputd || echo "  inputd start FAILED"

    # Audio: sun4i-codec (5096000.codec) also resumes dead (pw-cat "plays" into
    # silence).  Rebind it, then unmute the DAC switch — the fresh probe brings the
    # codec up with 'DAC Playback Switch' off (the actual signal source; Speaker/
    # Line Out come up on) and wireplumber's route-restore never touches it.
    # Verified live: rebind alone = still silent; rebind + DAC unmute = sound.
    # The pipewire restart below re-attaches to the recreated card.
    echo "[audio] codec rebind + DAC unmute"
    echo 5096000.codec > /sys/bus/platform/drivers/sun4i-codec/unbind 2>/dev/null || true
    ${pkgs.coreutils}/bin/sleep 1
    echo 5096000.codec > /sys/bus/platform/drivers/sun4i-codec/bind 2>/dev/null || echo "  codec bind FAILED"
    ${pkgs.coreutils}/bin/sleep 1
    ${pkgs.alsa-utils}/bin/amixer -c 0 -q sset 'DAC' unmute 2>/dev/null || echo "  DAC unmute FAILED"
    ${pkgs.alsa-utils}/bin/amixer -c 0 -q sset 'Speaker' on 2>/dev/null || true
    ${pkgs.alsa-utils}/bin/amixer -c 0 -q sset 'Line Out' on 2>/dev/null || true

    echo "[userspace] pipewire/automount/mmc1"
    ${pkgs.systemd}/bin/systemctl --user -M alec@ restart wireplumber pipewire pipewire-pulse || echo "  pipewire FAILED"
    ${pkgs.systemd}/bin/systemctl restart mnt-AlecContent.automount 2>/dev/null || true
    ${pkgs.systemd}/bin/systemctl restart mmc1-rescue.service 2>/dev/null || true

    ${pkgs.coreutils}/bin/sleep 3
    echo "[state] wlan0:"; ${pkgs.iproute2}/bin/ip -br link show wlan0 2>&1 || echo "  no wlan0"
    echo "[state] gamepad device count:"; ${pkgs.gnugrep}/bin/grep -c "H700 Gamepad" /proc/bus/input/devices 2>&1
    ${pkgs.util-linux}/bin/dmesg > /persist/last-resume-dmesg.txt 2>/dev/null || true
    echo "===== resume hook done ====="
  '';

  # Unbind the USB host controllers while still healthy (before the snapshot) so
  # they resume detached instead of in the broken "root hub lost power" state that
  # freezes the kernel on the next plug; resumeCommands rebinds them.
  powerManagement.powerDownCommands = ''
    for _d in 5101000.usb 5200000.usb; do echo "$_d" > /sys/bus/platform/drivers/ehci-platform/unbind 2>/dev/null || true; done
    for _d in 5101400.usb 5200400.usb; do echo "$_d" > /sys/bus/platform/drivers/ohci-platform/unbind 2>/dev/null || true; done
  '';

  # The TF2 (game card) slot controller intermittently fails init at boot:
  # "sunxi-mmc 4022000.mmc: fatal err update clk timeout" — the card then never
  # enumerates and /mnt/AlecContent can't mount.  Unbinding and rebinding the
  # controller re-runs the whole init, which (unlike the failed first attempt)
  # happens with clocks/power already settled.  Retry a few times.
  systemd.services.mmc1-rescue = {
    description = "Re-init TF2 slot if the game card failed to enumerate";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "mmc1-rescue" ''
        for _try in 1 2 3 4 5; do
          [ -b /dev/disk/by-label/AlecContent ] && exit 0
          echo 4022000.mmc > /sys/bus/platform/drivers/sunxi-mmc/unbind 2>/dev/null || true
          sleep 1
          echo 4022000.mmc > /sys/bus/platform/drivers/sunxi-mmc/bind 2>/dev/null || true
          sleep 3
        done
        [ -b /dev/disk/by-label/AlecContent ] # exit status reflects success
      '';
    };
  };

  networking = {
    useNetworkd = false;
    networkmanager = {
      enable = true;
      wifi = {
        backend = "iwd";
        powersave = false; # Stop network drops
      };
    };
    hostName = "alechandheld";
    firewall.enable = false; # causes errors
  };
  systemd.network.enable = false; # no networkd

  hardware.graphics.enable = true; # Mesa/OpenGL
  security.rtkit.enable = true; # realtime priority for pw
  powerManagement.cpuFreqGovernor = "schedutil";
  systemd.services.NetworkManager-wait-online.enable = false;
  # nowatchdog/nmi_watchdog already set in common.nix
  boot.kernelParams = [
    "cma=256M" # default 32mb, for running more intensive games
    # Hibernation resume offset for /persist/swapfile.  The scripted initrd
    # (initrd.systemd.enable=false) writes only the resume DEVICE to
    # /sys/power/resume, never the offset, so the swapfile's first-block offset
    # must arrive on the cmdline (ext4 block == page == 4096, so it maps 1:1).
    # Re-measure and update if the swapfile is ever recreated/resized:
    #   sudo filefrag -v /persist/swapfile | awk 'NR==4{gsub(/\./,"",$4); print $4}'
    "resume_offset=319488"
  ];
  # rtw88 deep low-power state causes intermittent WiFi drops on RTL8821CS.
  boot.extraModprobeConfig = ''
    options rtw88_core disable_lps_deep=Y
  '';

  # The sun8i-ce hardware crypto engine comes back dead from hibernate ("DMA
  # timeout for ecb(aes)").  iwd runs its WPA crypto through the kernel (AF_ALG),
  # which routes AES to this engine — so after resume the 4-way handshake hangs
  # until the AP kicks us (4WAY_HANDSHAKE_TIMEOUT) and WiFi never reconnects.
  # Nothing here needs HW crypto (no disk encryption; a handshake is a few KB),
  # so drop the engine entirely and let the kernel use software AES.
  boot.blacklistedKernelModules = [ "sun8i_ce" ];

  # RTL8821CS WiFi+BT combo: firmware LPS entry causes coex h2c timeouts spamming dmesg
  # ("coex request time out", "failed to send h2c command", "firmware failed to leave lps state").
  # disable_lps_deep alone isn't enough — regular LPS still triggers the bug. Force power_save off
  # via iw once wlan0 exists. Restart on wlan0 (re)appearance so it sticks across rfkill toggles.
  systemd.services.wifi-no-powersave = {
    description = "Disable WiFi power_save (RTL8821CS BT-coex workaround)";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" "NetworkManager.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = pkgs.writeShellScript "wifi-no-powersave" ''
        for _i in 1 2 3 4 5 6 7 8 9 10; do
          [ -d /sys/class/net/wlan0 ] && break
          sleep 1
        done
        ${pkgs.iw}/bin/iw dev wlan0 set power_save off || true
      '';
    };
  };
  boot.kernel.sysctl = {
    "kernel.sched_autogroup_enabled" = 0;
    "vm.dirty_ratio" = 20;
    "vm.dirty_background_ratio" = 5;
    "vm.vfs_cache_pressure" = 50;
  };

  users.users.alec.extraGroups = [ "input" "gamemode" "bluetooth" "networkmanager" "video" "uinput" "tty" ];
  # pin: a uid drift (1001→1000) on this host once broke all on-disk ownership
  # (game card + /run/user paths); scoped here — other hosts' uids are unverified
  users.users.alec.uid = 1000;

  services.journald.extraConfig = "Storage=volatile"; # Extend SD card lifespan

  # Old system generations pile up fast with remote deploys; a full SD card
  # wears faster (less room for wear leveling)
  nix.gc = {
    automatic = true;
    options = "--delete-older-than 14d";
  };

  # WirePlumber: prefer A2DP (high-quality stereo output, no mic) over HFP/HSP.
  # bluez5.auto-connect: request A2DP profile first, then HFP as fallback.
  # Removing the wireplumber.settings block — bluetooth.autoswitch-to-headset-profile
  # is not a valid key in this WirePlumber version and causes the file to be ignored.
  # GameMaker ports (Undertale/Deltarune) request tiny audio buffers and
  # underrun (pops/crackle) on this CPU; force a sane floor server-side.
  # ~21ms — going higher (43ms) made the latency audible without curing the
  # stutter; the real starvation fix is rtkit access inside the sandbox
  # (see the /run/dbus bind in portmaster.nix).
  services.pipewire.extraConfig.pipewire-pulse."20-min-quantum" = {
    "pulse.properties"."pulse.min.quantum" = "1024/48000";
  };

  services.pipewire.wireplumber.extraConfig."10-bluetooth" = {
    "monitor.bluez.properties" = {
      "bluez5.roles"            = [ "a2dp_sink" "a2dp_source" "hsp_hs" "hsp_ag" "hfp_hf" "hfp_ag" ];
      "bluez5.codecs"           = [ "sbc_xq" "aac" "sbc" ];
      "bluez5.auto-connect"     = [ "a2dp_sink" "a2dp_source" "hsp_hs" "hfp_hf" ];
      "bluez5.enable-hw-volume" = true;
      "bluez5.enable-msbc"      = false;
    };
  };
}
