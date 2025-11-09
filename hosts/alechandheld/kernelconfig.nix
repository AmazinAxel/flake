{ lib, ...}: {
  boot.kernelPatches = [{
    patch = null;
    extraConfig = ''
      JOYSTICK_ADC y
      MUX_GPIO y
      IIO_MUX y
    '';
  }];
}