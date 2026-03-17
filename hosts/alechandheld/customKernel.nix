{ pkgs, lib, ... }:

let
  mainlinePatches = map (p: ./mainline-patches/${p})
    (builtins.filter (f: lib.hasSuffix ".patch" f)
      (builtins.attrNames (builtins.readDir ./mainline-patches)));

  devicePatches = map (p: ./patches/${p})
    (builtins.filter (f: lib.hasSuffix ".patch" f)
      (builtins.attrNames (builtins.readDir ./patches)));

  f = lib.mkForce;

  customKernel = pkgs.linux_6_19.override {
    ignoreConfigErrors = true;
    kernelPatches = map (p: {
      name = builtins.baseNameOf p;
      patch = p;
    }) (mainlinePatches ++ devicePatches);

    structuredExtraConfig = with lib.kernel; {
      # Display
      DRM_SUN4I = f yes;
      DRM_SUN6I_DSI = f yes;
      DRM_SUN8I_DW_HDMI = f yes;
      DRM_SUN8I_MIXER = f yes;
      DRM_SUN8I_TCON_TOP = f yes;
      DRM_SUN50I_PLANES = f yes;

      DRM_PANEL_SIMPLE = f module;
      DRM_PANEL_MIPI = f module;
      PHY_SUN6I_MIPI_DPHY = f yes;
      DRM_BRIDGE_CONNECTOR = f yes;
      DRM_DISPLAY_CONNECTOR = f yes;
      DRM_SIMPLE_BRIDGE = f yes;
      DRM_DW_HDMI = f yes;
      DRM_DW_HDMI_I2S_AUDIO = module;
      DRM_ITE_IT6263 = f yes;

      # Framebuffer console for early boot
      DRM_FBDEV_EMULATION = f yes;
      FRAMEBUFFER_CONSOLE = f yes;

      # Backlight
      BACKLIGHT_CLASS_DEVICE = f module;
      BACKLIGHT_PWM = f module;
      BACKLIGHT_GPIO = f module;
      BACKLIGHT_LED = f module;

      # GPU - built-in to avoid probe order issues
      DRM_PANFROST = f yes;

      # Allwinner clocks & bus
      SUN8I_DE2_CCU = f yes;
      SUN50I_DE2_BUS = f yes;
      SUN50I_H616_CCU = f yes;

      # Power management (AXP PMIC)
      MFD_AXP20X = f yes;
      MFD_AXP20X_I2C = f yes;
      MFD_AXP20X_RSB = f yes;
      REGULATOR_AXP20X = f yes;
      AXP20X_POWER = module;
      CHARGER_AXP20X = module;
      BATTERY_AXP20X = module;
      INPUT_AXP20X_PEK = f yes;
      AXP20X_ADC = f yes;

      WIRELESS = f yes;
      WLAN = f yes;
      WLAN_VENDOR_REALTEK = f yes;
      RTW88 = f module;
      RTW88_CORE = f module;
      RTW88_SDIO = f module;
      RTW88_8821C = f module;
      RTW88_8821CS = f module;
      RTW88_LEDS = f yes;

      # Input (gamepad, joystick & buttons)
      INPUT_POLLDEV = f yes;
      KEYBOARD_ADC = f yes;
      KEYBOARD_GPIO = f yes;
      KEYBOARD_GPIO_POLLED = f yes;
      JOYSTICK_ADC = f yes;
      INPUT_PWM_VIBRA = f yes;
      INPUT_EVDEV = f yes;
      INPUT_UINPUT = f yes;
      SUN20I_GPADC = f yes; # analog joystick ADC

      # IIO subsystem (required by SUN20I_GPADC and rocknix-singleadc-joypad)
      IIO = f yes;
      IIO_MUX = f yes; # analog mux for joystick channels

      # Audio
      SND_SUN4I_CODEC = module;
      SND_SUN4I_I2S = module;
      SND_SUN4I_SPDIF = module;
      SND_SOC_HDMI_CODEC = module;

      # Storage/MMC
      MMC_SUNXI = f yes;

      # Thermal & watchdog
      SUN8I_THERMAL = f yes;
      SUNXI_WATCHDOG = f yes;

      # USB
      PHY_SUN4I_USB = f yes;
      USB_MUSB_HDRC = f yes;
      USB_MUSB_SUNXI = f yes;

      # IOMMU
      SUN50I_IOMMU = f yes;

      # DMA
      DMA_SUN6I = f yes;

      # PWM for backlight & vibration
      PWM_SUN4I = f yes;
      PWM_SUN20I = f yes; # H700 uses SUN20I PWM for backlight

      # SPI (panel is SPI-connected)
      SPI = f yes;
      SPI_SUN6I = f yes;

      # RSB bus (AXP PMIC on H700 uses RSB, not I2C)
      SUNXI_RSB = f yes;

      # MIPI D-PHY framework
      GENERIC_PHY_MIPI_DPHY = f yes;

      # Pinctrl
      PINCTRL_SUN50I_H616 = f yes;
      PINCTRL_SUN50I_H616_R = f yes;

      # RTC
      RTC_DRV_SUN6I = f yes;

      # Crypto HW acceleration
      CRYPTO_DEV_SUN8I_CE = module;
      CRYPTO_DEV_SUN8I_SS = module;

      RFKILL = f yes;
      RFKILL_GPIO = f yes;

      DEBUG_INFO_NONE = f yes;
      DEBUG_INFO_DWARF_TOOLCHAIN_DEFAULT = f no;
    };
  };

  customLinuxPackages = pkgs.linuxPackagesFor customKernel;
  rocknixJoypad = customLinuxPackages.callPackage ./rocknix-joypad.nix { };
in {
  boot.kernelPackages = customLinuxPackages;
  boot.extraModulePackages = [ rocknixJoypad ];
}
