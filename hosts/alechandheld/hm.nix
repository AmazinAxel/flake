{ lib, pkgs, ... }:

let
  retroarchCfg = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: ''${k} = "${v}"'') attrs) + "\n";
in {
  xdg.configFile."retroarch/retroarch.cfg" = {
    force = true;
    text = retroarchCfg {
      input_driver = "udev";
      input_joypad_driver = "udev";
      joypad_autoconfig_dir = "~/.config/retroarch/autoconfig";
      menu_driver = "rgui";
      video_driver = "gl";
      video_fullscreen = "true";
      video_threaded = "false"; # TEMP FIX
      video_smooth = "false";
      audio_driver = "pulse";
      audio_latency = "64";
      audio_sync = "false";
      video_swap_interval = "0";
      rewind_enable = "false";
      input_autodetect_enable = "false";
      config_save_on_exit = "false";
      network_cmd_enable = "true";
      log_verbosity = "true";
      log_dir = "/tmp";

      # gamepad
      input_player1_joypad_index = "0";
      input_player1_b_btn = "1";
      input_player1_a_btn = "0";
      input_player1_x_btn = "2";
      input_player1_y_btn = "3";
      input_player1_l_btn = "4";
      input_player1_r_btn = "5";
      input_player1_l2_btn = "6";
      input_player1_r2_btn = "7";
      input_player1_select_btn = "8";
      input_player1_start_btn = "9";
      input_player1_l3_btn = "11";
      input_player1_r3_btn = "12";
      input_player1_up_btn = "13";
      input_player1_down_btn = "14";
      input_player1_left_btn = "15";
      input_player1_right_btn = "16";
      input_player1_l_x_plus_axis = "+0";
      input_player1_l_x_minus_axis = "-0";
      input_player1_l_y_plus_axis = "+1";
      input_player1_l_y_minus_axis = "-1";
      input_player1_r_x_plus_axis = "+3";
      input_player1_r_x_minus_axis = "-3";
      input_player1_r_y_plus_axis = "+4";
      input_player1_r_y_minus_axis = "-4";
      input_menu_toggle_btn = "10";

      savestate_auto_save = "true";
      savestate_auto_load = "true";
      autosave_interval = "60"; # flush SRAM to disk every 60s, not just on clean exit

      wifi_driver = "nmcli"; # for wifi settings
      bluetooth_driver = "bluetoothctl"; # for bluetooth settings
      menu_show_advanced_settings = "true"; # ?? remove probably

      input_remapping_directory = "~/.config/retroarch/remaps";

      # fix cores not being found
      libretro_directory = "/run/current-system/sw/lib/retroarch/cores";
      libretro_info_path = "${pkgs.libretro-core-info}/share/retroarch/cores";
    };
  };

  # melonDS core options - goes in the global options file, not a per-core .opt
  # (per-core .opt only works with game_specific_options enabled)
  #xdg.configFile."retroarch/retroarch-core-options.cfg".text = ''
  #  melonds_jit_enable = "enabled"
  #  melonds_jit_block_size = "32"
  #  melonds_threaded_renderer = "enabled"
  #'';

  # melonDS needs a bigger audio buffer - DS runs at ~59.83fps (non-standard) which causes
  # stuttering at the global 64ms latency. audio_sync also needs to be on for it to pace correctly.
  #xdg.configFile."retroarch/config/melonDS/melonDS.cfg".text = retroarchCfg {
  #  audio_latency = "256";
  #  audio_sync = "true";
  #};

  # Swap A and B buttons on gba
  xdg.configFile."retroarch/remaps/mGBA/mGBA.rmp".text = ''
    input_player1_btn_a = "0"
    input_player1_btn_b = "8"
  '';

  home.stateVersion = "24.05";
}
