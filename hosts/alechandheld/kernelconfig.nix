{ lib, ...}: {
  boot.kernelPatches = [{
    name = "h700-rg35xx-h-config";
    patch = null;
    structuredExtraConfig = with lib.kernel; {
      INPUT_JOYSTICK = yes;
      JOYSTICK_ADC = yes;
      INPUT_MISC = yes;
      INPUT_AXP20X_PEK = yes;
      INPUT_UINPUT = yes;
      INPUT_PWM_VIBRA = yes;
      SERIO = yes;
      SERIO_AMBAKMI = yes;
      SERIO_LIBPS2 = yes;
    };
  }];
}