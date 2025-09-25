{
  programs.hyprlock = {
    enable = true;

    settings = {
      background = {
        path = "screenshot";
        blur_passes = 3;
        brightness = 0.6;
      };

      general = {
        grace = 0;
        disable_loading_bar = true;
        ignore_empty_input = true;
      };

      # Custom input field to wrap clock
      input-field = {
        size = "400, 500";
        position = "0, 12";
        rounding = 4;
        outline_thickness = 7;
        fail_timeout = 0;

        outer_color = "rgba(255, 255, 255, 0)";
        check_color = "rgba(255, 255, 255, 0.3)";
        fail_color = "rgba(255, 255, 255, 0)";
        inner_color = "rgba(0, 0, 0, 0)";
        font_color = "rgba(0, 0, 0, 0)";
        placeholder_text = "";
        fail_text = "";
      };

      # Clock
      label = [ { # Hour
          text = ''cmd[update:1000] echo -e "$(date +'%H')"'';
          color = "rgba(255, 255, 255, 0.5)";
          font_size = 200;
          font_family = "Liberation Mono";
          position = "0, 100";
          halign = "center";
          valign = "center";

          shadow_passes = 1;
          shadow_size = 7;
          shadow_color = "rgb(255,255,255)";
        } { # Minute
          text = ''cmd[update:1000] echo -e "$(date +'%M')"'';
          color = "rgba(255, 255, 255, 0.5)";
          font_size = 200;
          font_family = "Liberation Mono";
          position = "0, -100";
          halign = "center";
          valign = "center";

          shadow_passes = 1;
          shadow_size = 7;
          shadow_color = "rgb(255,255,255)";
        }
      ];
    };
  };
}