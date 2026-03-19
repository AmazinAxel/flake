{ lib, pkgs, ... }:

let
  retroarchSettings = {
    input_driver = "udev";
    input_joypad_driver = "udev";
    joypad_autoconfig_dir = "~/.config/retroarch/autoconfig";
    menu_driver = "rgui";
    video_driver = "gl";
    video_fullscreen = "true";
    video_threaded = "true";
    video_smooth = "false";
    audio_driver = "pulse";
    audio_latency = "64";
    rewind_enable = "false";
    input_autodetect_enable = "false";
    config_save_on_exit = "false";
    network_cmd_enable = "true";

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
  };

  # toKeyValue writes unquoted values which RetroArch may not parse correctly
  # for axis values like +0/-0. Use RetroArch's own format: key = "value"
  toRetroarchCfg = attrs:
    lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: ''${k} = "${v}"'') attrs) + "\n";

  configFile = pkgs.writeText "retroarch.cfg" (toRetroarchCfg retroarchSettings);

  autoconfigFile = pkgs.writeText "H700 Gamepad.cfg"
    "input_device = \"H700 Gamepad\"\ninput_driver = \"udev\"\n";
in {
  home.activation.retroarchConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.config/retroarch/autoconfig"
    cp ${configFile} "$HOME/.config/retroarch/retroarch.cfg"
    chmod 644 "$HOME/.config/retroarch/retroarch.cfg"
    cp ${autoconfigFile} "$HOME/.config/retroarch/autoconfig/H700 Gamepad.cfg"
    chmod 644 "$HOME/.config/retroarch/autoconfig/H700 Gamepad.cfg"
  '';

  home.stateVersion = "24.05";
}
