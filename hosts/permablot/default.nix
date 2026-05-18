{ pkgs, ... }: {
  imports = [
    ../common.nix
    ../../modules/pi.nix
  ];
  environment.systemPackages = with pkgs; [  ];
  #systemd.tmpfiles.rules = [ "w /sys/class/leds/ACT/trigger - - - - none" ]; # no LED

  users.extraGroups.gpio = { };
  users.users.alec.extraGroups = [ "gpio" ];  hardware.i2c.enable = true;

  # Networking
  networking = {
    hostName = "permablot";
    firewall.allowedTCPPorts = [ 80 ];
  };

  system.stateVersion = "25.11";

  /*
  [all]
  # For proper boot
  kernel=u-boot-rpi3.bin
  arm_64bit=1
  enable_uart=1

  # Turn on gpio button
  gpio=6,19,5,26,13,21,20,16=pu

  # Disable hdmi output
  gpu_mem=16
  disable_fw_kms_setup=1
  disable_overscan=1
  hdmi_force_hotplug=0
  hdmi_blanking=2

  # Faster boot
  boot_delay=0
  disable_splash=1
  avoid_warnings=1
  */
}
