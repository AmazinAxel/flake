{
  programs.xwayland.enable = true;
  environment.etc."niri/config.kdl".text = ''
    input {
      warp-mouse-to-focus
      focus-follows-mouse
      workspace-auto-back-and-forth
      keyboard {
        repeat-delay 300
        repeat-rate 20
      }

      touchpad {
        tap
        dwt // disable touchpad while typing
        drag true // tap & drag
        //drag-lock
        // accel-speed 0.2
        // accel-profile "flat" // enable if feels weird
        // scroll-factor 1.0
        // scroll-factor vertical=1.0 horizontal=-2.0
        
        // scroll-method "two-finger"
        // tap-button-map "left-middle-right"
        // click-method "clickfinger"
      }

      mouse {
        // accel-speed 0.2
        // accel-profile "flat"
        // scroll-factor 1.0
        // scroll-factor vertical=1.0 horizontal=-2.0
        // scroll-method "no-scroll"
        // scroll-button 273
        // scroll-button-lock
      }

      trackpoint {
        off
      }
      trackball {
        off
      }
      tablet {
        off
      }
      touch {
        off
      }
    }

    layout {
      gaps 4 // Window gaps

      default-column-width { proportion 0.5; }

      focus-ring {
        off
      }
      tab-indicator {
        off
      }
      insert-hint {
        color "#5e81ac"
      }

      border {
        width 2
        active-color "#5e81ac"
        inactive-color "#4c566a"
        urgent-color "#bf616a"
      }
    }

    spawn-at-startup "hyprlock"
    spawn-at-startup "fcitx5" "-d"
    spawn-at-startup "gammastep" "-O" "3000"
    spawn-at-startup "batsignal" "-w" "20" "-c" "5" "-d" "0" "-p" "Low battery"

    hotkey-overlay {
      skip-at-startup
    }

    prefer-no-csd
    screenshot-path null

    animations {

    }
    gestures {
    
      hot-corners {
        off
      }
    }

    /-window-rule {
      match app-id=r#"firefox$"# title="^Picture-in-Picture$"
      open-floating true
    }

    window-rule {
      match app-id=r#"^org\.keepassxc\.KeePassXC$"#
      match app-id=r#"^org\.gnome\.World\.Secrets$"#

      block-out-from "screen-capture"
    }

    window-rule {
      geometry-corner-radius 6
      clip-to-geometry true
    }

    binds {
      Mod+Return repeat=false { spawn "foot"; } // Terminal
      Mod+E repeat=false { spawn "librewolf"; } // Browser

      // Desktop shell control
      Mod+Space repeat=false { spawn "ags" "toggle" "launcher"; }
      Mod+A repeat=false { spawn "ags" "toggle" "chat"; }
      Mod+V repeat=false { spawn "ags" "toggle" "clipboard"; }
      Mod+Period repeat=false { spawn "ags" "toggle" "emojiPicker"; }
      Mod+Shift+S repeat=false { spawn "ags" "toggle" "powermenu"; }

      Mod+C repeat=false { spawn "ags" "request" "hideNotif"; }
      Mod+R repeat=false { spawn "ags" "request" "record"; }
      Mod+Control+R repeat=false { spawn "ags" "request" "record"; }
      Mod+Shift+D repeat=false { spawn "ags" "request" "toggleDND"; }

      Mod+Control+Period repeat=false { spawn "ags" "request" "media next"; }
      Mod+Control+Comma repeat=false { spawn "ags" "request" "media prev"; }
      Mod+Shift+Period repeat=false { spawn "ags" "request" "media nextPlaylist"; }
      Mod+Shift+Comma repeat=false { spawn "ags" "request" "media prevPlaylist"; }
      Mod+Slash repeat=false { spawn "ags" "request" "media toggle"; }

      // Volume control
      XF86AudioRaiseVolume { spawn "wpctl set-volume @DEFAULT_SINK@ .05+"; }
      XF86AudioLowerVolume { spawn "wpctl set-volume @DEFAULT_SINK@ .05-"; }

      // Brightness
      XF86MonBrightnessUp { spawn "brightnessctl" "set" "+5%"; }
      XF86MonBrightnessDown { spawn "brightnessctl" "set" "5%-"; }

      Mod+O repeat=false { toggle-overview; }
      Mod+Q repeat=false { close-window; }

      Mod+Left  { focus-column-left; }
      Mod+Down  { focus-window-down; }
      Mod+Up    { focus-window-up; }
      Mod+Right { focus-column-right; }

      Mod+Ctrl+Left  { move-column-left; }
      Mod+Ctrl+Down  { move-window-down; }
      Mod+Ctrl+Up    { move-window-up; }
      Mod+Ctrl+Right { move-column-right; }

      Mod+Shift+Left  { focus-monitor-left; }
      Mod+Shift+Down  { focus-monitor-down; }
      Mod+Shift+Up    { focus-monitor-up; }
      Mod+Shift+Right { focus-monitor-right; }

      Mod+Shift+Ctrl+Left  { move-column-to-monitor-left; }
      Mod+Shift+Ctrl+Down  { move-column-to-monitor-down; }
      Mod+Shift+Ctrl+Up    { move-column-to-monitor-up; }
      Mod+Shift+Ctrl+Right { move-column-to-monitor-right; }

      // Alternatively, there are commands to move just a single window:
      // Mod+Shift+Ctrl+Left  { move-window-to-monitor-left; }
      // ...

      // And you can also move a whole workspace to another monitor:
      // Mod+Shift+Ctrl+Left  { move-workspace-to-monitor-left; }
      // ...

      Mod+Page_Down      { focus-workspace-down; }
      Mod+Page_Up        { focus-workspace-up; }
      Mod+U              { focus-workspace-down; }
      Mod+I              { focus-workspace-up; }
      Mod+Ctrl+Page_Down { move-column-to-workspace-down; }
      Mod+Ctrl+Page_Up   { move-column-to-workspace-up; }
      Mod+Ctrl+U         { move-column-to-workspace-down; }
      Mod+Ctrl+I         { move-column-to-workspace-up; }

      // Alternatively, there are commands to move just a single window:
      // Mod+Ctrl+Page_Down { move-window-to-workspace-down; }
      // ...

      Mod+Shift+Page_Down { move-workspace-down; }
      Mod+Shift+Page_Up   { move-workspace-up; }
      Mod+Shift+U         { move-workspace-down; }
      Mod+Shift+I         { move-workspace-up; }

      Mod+WheelScrollDown      cooldown-ms=150 { focus-workspace-down; }
      Mod+WheelScrollUp        cooldown-ms=150 { focus-workspace-up; }
      Mod+Ctrl+WheelScrollDown cooldown-ms=150 { move-column-to-workspace-down; }
      Mod+Ctrl+WheelScrollUp   cooldown-ms=150 { move-column-to-workspace-up; }

      Mod+WheelScrollRight      { focus-column-right; }
      Mod+WheelScrollLeft       { focus-column-left; }
      Mod+Ctrl+WheelScrollRight { move-column-right; }
      Mod+Ctrl+WheelScrollLeft  { move-column-left; }

      // Usually scrolling up and down with Shift in applications results in
      // horizontal scrolling; these binds replicate that.
      Mod+Shift+WheelScrollDown      { focus-column-right; }
      Mod+Shift+WheelScrollUp        { focus-column-left; }
      Mod+Ctrl+Shift+WheelScrollDown { move-column-right; }
      Mod+Ctrl+Shift+WheelScrollUp   { move-column-left; }

      Alt+Tab { focus-workspace-previous; }

      // The following binds move the focused window in and out of a column.
      // If the window is alone, they will consume it into the nearby column to the side.
      // If the window is already in a column, they will expel it out.
      Mod+BracketLeft  { consume-or-expel-window-left; }
      Mod+BracketRight { consume-or-expel-window-right; }

      // Consume one window from the right to the bottom of the focused column.
      //Mod+Comma  { consume-window-into-column; }
      // Expel the bottom window from the focused column to the right.
      //Mod+Period { expel-window-from-column; }

      //Mod+R { switch-preset-column-width; }
      // Cycling through the presets in reverse order is also possible.
      // Mod+R { switch-preset-column-width-back; }
      //Mod+Shift+R { switch-preset-window-height; }
      //Mod+Ctrl+R { reset-window-height; }
      //Mod+F { maximize-column; }

      Mod+Shift+F { maximize-window-to-edges; }
      Mod+Ctrl+Shift+F { toggle-windowed-fullscreen; }
      F11 { fullscreen-window; }
      

      // Expand the focused column to space not taken up by other fully visible columns.
      // Makes the column "fill the rest of the space".
      //Mod+Ctrl+F { expand-column-to-available-width; }

      // Move the focused window between the floating and the tiling layout.
      Mod+F       { toggle-window-floating; }

      //Mod+W { toggle-column-tabbed-display; }

      Print { screenshot; }

      Mod+Escape allow-inhibiting=false { toggle-keyboard-shortcuts-inhibit; }
    }
  '';
}
