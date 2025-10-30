{ lib, pkgs, ... }: {
  boot = {
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_17;
    kernelPatches = builtins.map (patch: { inherit patch; }) [
      ./0001-v8_20250310_ryan_drm_sun4i_add_display_engine_3_3_de33_support.patch
      ./0003-20250216_ryan_arm64_dts_allwinner_h616_add_lcd_timing_controller_and_display_engine_support.patch
      ./0007-rg35xx-add-GPU-opp.patch
      ./0008-sun20i-add-pwm-driver.patch
      ./0009-h616-add-pwm-node.patch
      ./0010-rg35xx-enable-pwm-backlight.patch
      ./0040-Revert-usb-musb-Fix-hardware-lockup-on-first-Rx-endp.patch
      ./0110-v2_20250226_kikuchan98_drm_panel_add_generic_mipi_panel_driver.patch
      ./0124-battery-name.patch
      ./0126-20241018_macroalpha82_rg35xx_add_additional_hardware_support.patch
      ./0144-Update-sun50i-h700-anbernic-rg35xx-h.dts.patch
      ./0150-add-forcefeedback.patch
      ./0151-phy-fix-OTG-host-mode.patch
      ./0153-enable-rgb-leds.patch
      ./0155-sun4i-set-rgb-connector-as-DSI.patch
      ./0200-h700-update-opps.patch
      ./0201-drm-sun4i-add-TCON-global-control-reg-for-pad-select.patch
      ./0202-dts-Add-HDMI-support.patch
      ./0203-sound-soc-Add-sunxi_v2-for-h616-ahub.patch
      ./0204-dts-Enable-hdmi-sound.patch
    ];
  };
}