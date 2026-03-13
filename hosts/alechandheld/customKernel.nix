{ pkgs, lib, ... }:

let
  patchDir = ./patches; # idk why this has to be a var TODO

  patchFiles = map (p: ./patches/${p})
    (builtins.filter (f: lib.hasSuffix ".patch" f)
      (builtins.attrNames (builtins.readDir patchDir)));

  customKernel = pkgs.linux_6_19.override {
    kernelPatches = map (p: {
      name = builtins.baseNameOf p;
      patch = p;
    }) patchFiles;

    structuredExtraConfig = with lib.kernel; {
      # --- Display pipeline (built-in for early boot framebuffer) ---
      DRM_SUN4I              = yes;
      DRM_SUN6I_DSI          = yes;
      DRM_SUN8I_DW_HDMI      = yes;
      DRM_SUN8I_MIXER        = yes;
      DRM_SUN8I_TCON_TOP     = yes;
      DRM_SUN50I_PLANES      = yes;
      DRM_PANEL_SIMPLE       = module;
      DRM_PANEL_MIPI         = module;
      PHY_SUN6I_MIPI_DPHY    = yes;
      DRM_BRIDGE_CONNECTOR   = yes;
      DRM_DISPLAY_CONNECTOR  = yes;
      DRM_SIMPLE_BRIDGE      = yes;
      DRM_DW_HDMI            = yes;
      DRM_DW_HDMI_I2S_AUDIO  = module;
      DRM_ITE_IT6263         = yes;

      # Backlight
      BACKLIGHT_PWM          = yes;
      BACKLIGHT_GPIO         = yes;
      BACKLIGHT_LED          = yes;

      # Framebuffer console (see output during boot)
      DRM_FBDEV_EMULATION    = yes;
      FRAMEBUFFER_CONSOLE    = yes;

      # --- GPU ---
      DRM_PANFROST           = module;

      # --- Allwinner clocks / bus ---
      SUN8I_DE2_CCU          = yes;
      SUN50I_DE2_BUS         = yes;
      SUN50I_H616_CCU        = yes;

      # --- Power management (AXP PMIC) ---
      MFD_AXP20X             = yes;
      MFD_AXP20X_I2C         = yes;
      MFD_AXP20X_RSB         = yes;
      REGULATOR_AXP20X       = yes;
      AXP20X_POWER           = module;
      CHARGER_AXP20X         = module;
      BATTERY_AXP20X         = module;
      INPUT_AXP20X_PEK       = yes;

      # --- WiFi (RTL8821CS) ---
      RTW88                  = module;
      RTW88_CORE             = module;
      RTW88_SDIO             = module;
      RTW88_8821C            = module;
      RTW88_8821CS           = module;

      # --- Input (gamepad, joystick, buttons) ---
      KEYBOARD_ADC           = yes;
      KEYBOARD_GPIO          = yes;
      KEYBOARD_GPIO_POLLED   = yes;
      JOYSTICK_ADC           = yes;
      INPUT_PWM_VIBRA        = yes;
      INPUT_EVDEV            = yes;
      INPUT_UINPUT           = yes;

      # --- Audio ---
      SND_SUN4I_CODEC        = module;
      SND_SUN4I_I2S          = module;
      SND_SUN4I_SPDIF        = module;
      SND_SOC_HDMI_CODEC     = module;

      # --- Storage / MMC ---
      MMC_SUNXI              = yes;

      # --- Thermal / watchdog ---
      SUN8I_THERMAL          = yes;
      SUNXI_WATCHDOG         = yes;

      # --- USB ---
      PHY_SUN4I_USB          = yes;
      USB_MUSB_HDRC          = yes;
      USB_MUSB_SUNXI         = yes;

      # --- IOMMU ---
      SUN50I_IOMMU           = yes;

      # --- DMA ---
      DMA_SUN6I              = yes;

      # --- PWM (for backlight & vibration) ---
      PWM_SUN4I              = yes;

      # --- Pinctrl ---
      PINCTRL_SUN50I_H616    = yes;
      PINCTRL_SUN50I_H616_R  = yes;

      # --- RTC ---
      RTC_DRV_SUN6I          = yes;

      # --- Crypto HW acceleration ---
      CRYPTO_DEV_SUN8I_CE    = module;
      CRYPTO_DEV_SUN8I_SS    = module;
    };
  };
  customLinuxPackages = pkgs.linuxPackagesFor customKernel;
in {
  boot.kernelPackages = customLinuxPackages;
}