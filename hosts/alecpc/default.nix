{ pkgs, config, lib, ... }: {
  imports = [
    ./hardware-configuration.nix
    ../common.nix
    ../../modules/desktop.nix
  ];

  networking.hostName = "alecpc";
  home-manager.users.alec.imports = [ ./hm.nix ];

  swapDevices = [{ device = "/persist/swapfile"; size = 18 * 1024; }];

  environment.systemPackages = with pkgs; [
    kdePackages.kdenlive
    gimp3
    libreoffice
    gnome-sound-recorder
    gnome-disk-utility
    thunderbird

    bun
    openjdk25
  ];
  programs.kdeconnect.enable = true;

  services = {
    xserver.videoDrivers = [ "nvidia" ]; # Load nvidia drivers
    openssh.enable = true;  # for remote builds
  };

  powerManagement.cpuFreqGovernor = "performance";

  # Faster builds
  nix.settings = {
    max-jobs = "auto";
    cores = 0;
  };

  # Nvidia options --
  hardware.graphics.extraPackages = with pkgs; [ nvidia-vaapi-driver libva-vdpau-driver libvdpau-va-gl ];

  boot = {
    initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
    kernelParams = [ "nvidia-drm.modeset=1" "nvidia-drm.fbdev=1" "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ];
    extraModprobeConfig=''
      options nvidia_drm modeset=1 fbdev=1
      options nvidia NVreg_RegistryDwords="PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerLevel=0x1; PowerMizerDefault=0x1; PowerMizerDefaultAC=0x1"
    '';
    binfmt.emulatedSystems = [ "aarch64-linux" ]; # Arch64 cross compliation
  };

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true;
    open = false; # GPU architecture is older than Turing
    package = config.boot.kernelPackages.nvidiaPackages.legacy_580; # GTX 1050 Ti last supported package
  };
}
