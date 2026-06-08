{ pkgs, ... }: {
  home.packages = [ pkgs.batsignal ];

  wayland.windowManager.sway.config.startup = [
    { command = "batsignal -w 20 -c 10 -d 5 -m 30 -a 'Low battery'"; }
  ];
}
