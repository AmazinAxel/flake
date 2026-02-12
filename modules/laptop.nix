{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.batsignal ];
  # todo move batsignal sway startup action here
}