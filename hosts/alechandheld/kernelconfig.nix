{ lib, ...}: {
  boot.kernelPatches = [{
    name = "h700-rg35xx-h-config";
    patch = null;
    #ignoreConfigErrors = true;
    structuredExtraConfig = with lib.kernel; {
      INPUT = yes;
      INPUT_FF_MEMLESS = yes;
      INPUT_POLLDEV = yes;
      INPUT_MATRIXKMAP = yes;
      INPUT_VIVALDIFMAP = yes;
      INPUT_EVDEV = yes;
      KEYBOARD_GPIO = yes;
      KEYBOARD_GPIO_POLLED = yes;
      INPUT_JOYSTICK = yes;
      JOYSTICK_ADC = yes;
      INPUT_MISC = yes;
      INPUT_AXP20X_PEK = yes;
      INPUT_UINPUT = yes;
      INPUT_PWM_VIBRA = yes;
    };
  }];
}