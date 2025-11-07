{ lib, ...}: {
  boot.kernelPatches = [{
    name = "h700-rg35xx-h-config";
    patch = null;
    structuredExtraConfig = with lib.kernel; {
      JOYSTICK_ADC = yes;
      MUX_GPIO = yes;
      IIO_MUX = yes;
    };
  }];
}