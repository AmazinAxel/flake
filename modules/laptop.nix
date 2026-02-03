{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.batsignal ];
  # todo move batsignal niri startup action here
}