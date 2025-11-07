{ lib, ...}: {
  boot.kernelPatches = [{
    name = "h700-rg35xx-h-config";
    patch = null;
    #ignoreConfigErrors = true;
    structuredExtraConfig = with lib.kernel; {
      INPUT = yes;
      INPUT_EVDEV = yes;
      KEYBOARD_ADC = yes;
      INPUT_JOYSTICK = yes;
      JOYSTICK_ADC = yes;
      #INPUT_MISC = yes;
      #INPUT_AXP20X_PEK = yes;
      #INPUT_UINPUT = yes;
      #INPUT_PWM_VIBRA = yes;
      USB_EHCI_HCD = yes;
      SUN20I_GPADC = yes;
      MUX_GPIO = yes;
      KEYS = yes;
    };
  }];
}