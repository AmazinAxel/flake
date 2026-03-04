{ pkgs, ... }: {
  home.packages = [ pkgs.batsignal ];

  wayland.windowManager.sway.config.startup = [
    { command = "batsignal -w 20 -c 5 -d 0 -a Low battery"; }
  ];
}
