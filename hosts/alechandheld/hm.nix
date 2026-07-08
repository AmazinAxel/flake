{ lib, pkgs, ... }:

let
  retroarchCfg = attrs: lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: ''${k} = "${v}"'') attrs) + "\n";
in {
  xdg.configFile."retroarch/retroarch.cfg" = {
    force = true;
    text = retroarchCfg {
      # drivers
      audio_driver = "pulse";
      wifi_driver = "nmcli"; # for wifi settings
      bluetooth_driver = "bluez"; # bluetooth settings
      menu_driver = "rgui";
      video_driver = "gl";
      joypad_autoconfig_dir = "~/.config/retroarch/autoconfig";
      input_joypad_driver = "udev";
      input_driver = "udev";

      # audio
      audio_sync = "false";
      audio_volume = "1.500000";

      # video
      aspect_ratio_index = "22";
      video_aspect_ratio = "1.333300";
      video_fullscreen = "true";
      video_smooth = "false";
      video_swap_interval = "0";

      # behavior
      autosave_interval = "60";
      auto_overrides_enable = "false";
      auto_remaps_enable = "false";
      core_info_cache_enable = "true"; # skip re-parsing core .info files on every start
      input_autodetect_enable = "false";
      input_hotkey_block_delay = "5";
      input_max_users = "8";
      input_overlay_show_inputs = "2";
      log_dir = "/tmp";
      pause_nonactive = "false";
      savestate_auto_load = "true";
      savestate_auto_save = "true";
      config_save_on_exit = "false";

      # menu
      materialui_menu_color_theme = "9";
      materialui_landscape_layout_optimization = "1";
      materialui_thumbnail_view_landscape = "2";
      materialui_thumbnail_view_portrait = "1";
      menu_show_configurations = "false";
      menu_show_core_updater = "false";
      menu_show_information = "false";
      menu_show_load_core = "false";
      menu_show_online_updater = "false";
      menu_show_overlays = "false";
      menu_show_quit_retroarch = "false";
      menu_show_restart_retroarch = "false";
      menu_swap_ok_cancel_buttons = "false"; # compensates for the A/B btn swap below
      rgui_browser_directory = "/mnt/AlecContent";
      rgui_menu_color_theme = "23";
      rgui_particle_effect = "2";
      rgui_particle_effect_speed = "0.700000";

      #input_player1_joypad_index = "0";
      
      # settings tabs (mostly hidden)
      settings_show_accessibility = "false";
      settings_show_ai_service = "false";
      settings_show_audio = "false";
      settings_show_configuration = "false";
      settings_show_core = "false";
      settings_show_directory = "false";
      settings_show_drivers = "false";
      settings_show_file_browser = "false";
      settings_show_frame_throttle = "false";
      settings_show_input = "false";
      settings_show_latency = "false";
      settings_show_logging = "false";
      settings_show_network = "false";
      settings_show_onscreen_display = "false";
      settings_show_playlists = "false";
      settings_show_power_management = "false";
      settings_show_recording = "false";
      settings_show_saving = "false";
      settings_show_user = "false";
      settings_show_user_interface = "false";
      settings_show_video = "false";

      # quick menu
      quick_menu_show_add_to_favorites = "false";
      quick_menu_show_add_to_playlist = "false";
      quick_menu_show_controls = "false";
      quick_menu_show_core_options_flush = "false";
      quick_menu_show_download_thumbnails = "false";
      quick_menu_show_information = "false";
      quick_menu_show_options = "false";
      quick_menu_show_latency = "false";
      quick_menu_show_replay = "false";
      quick_menu_show_reset_core_association = "false";
      quick_menu_show_save_content_dir_overrides = "false";
      quick_menu_show_save_core_overrides = "false";
      quick_menu_show_save_game_overrides = "false";
      quick_menu_show_set_core_association = "false";
      quick_menu_show_shaders = "false";
      quick_menu_show_start_streaming = "false";

      # content tabs
      content_show_favorites = "false";

      # player 1 gamepad — A/B and X/Y swapped globally (Nintendo layout) for all cores.
      # libretro A = physical button 1 (east/right face button)
      # libretro B = physical button 0 (south/bottom face button)
      input_player1_a_btn = "1";
      input_player1_b_btn = "0";
      input_player1_x_btn = "3";
      input_player1_y_btn = "2";
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

      # fast forwarding

      input_enable_hotkey_btn = "10";
      input_toggle_fast_forward_btn = "7";
      fastforward_ratio = "1.500000";

      # paths — all writable data on the game card; home is ephemeral tmpfs
      savefile_directory = "/mnt/AlecContent/retroarch/saves";
      savestate_directory = "/mnt/AlecContent/retroarch/states";
      system_directory = "/mnt/AlecContent/retroarch/system"; # BIOS files
      input_remapping_directory = "/mnt/AlecContent/retroarch/remaps";
      screenshot_directory = "/mnt/AlecContent/retroarch/screenshots";
      # fix cores not being found
      libretro_directory = "/run/current-system/sw/lib/retroarch/cores";
      libretro_info_path = "${pkgs.libretro-core-info}/share/retroarch/cores";
    };
  };

  home.stateVersion = "26.05";
}
