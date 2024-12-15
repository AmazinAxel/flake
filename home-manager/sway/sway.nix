# Variables
set $mod Mod4

# Main (blue)
set $cl_high #81A1C1
# Indicator (gray)
set $cl_indi #D8DEE9
# Background (black)
set $cl_back #3B4252
# Foreground (gray)
set $cl_fore #ECEFF4
# Urgent (red)
set $cl_urge #BF616A

# Colors                border   bg       text     indi     childborder
client.focused          $cl_high $cl_high $cl_fore $cl_indi $cl_high
client.focused_inactive $cl_back $cl_back $cl_fore $cl_back $cl_back
client.unfocused        $cl_back $cl_back $cl_fore $cl_back $cl_back
client.urgent           $cl_urge $cl_urge $cl_fore $cl_urge $cl_urge

# workspaces
set $ws1   1:1
set $ws2   2:2
set $ws3   3:3
set $ws4   4:4
set $ws5   5:5
set $ws6   6:6
set $ws7   7:7
set $ws8   8:8
set $ws9   9:9

# SwayFX eye candy

blur enable
blur_radius 10
scratchpad_minimize enable
corner_radius 4

# Font
font pango:monospace 5

# Window borders
default_border pixel 2
default_floating_border none

gaps inner 5

# Desktop components
exec --no-startup-id ags
exec --no-startup-id dbus-update-activation-environment --all &
exec --no-startup-id fcitx5 & # Enable Chinese + English language switching
#exec_always /usr/bin/gnome-keyring-daemon --start --components=secrets &
#exec_always /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1 &
exec --no-startup-id swayidle -w timeout 300 'gtklock' before-sleep 'gtklock' & # Change gtklock to my custom lockscreen!
exec --no-startup-id swayidle -w timeout 450 'pidof java || systemctl suspend' & # dont sleep if playing minecraft, else nvidia will die
exec --no-startup-id dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
#exec --no-startup-id swaybg -i ~/.config/wallpaper.jpeg
exec --no-startup-id wl-paste --type text --watch cliphist store # Enable wayland paste
exec --no-startup-id wl-paste --type image --watch cliphist store # Enable wayland image paste
exec --no-startup-id wl-paste -p --watch wl-copy -p '' # Disables middle mouse paste
exec --no-startup-id gammastep -O 4000 # Screen color temp (filters blue light)

# Input configuration
input * {
    xkb_variant nodeadkeys
}

input type:touchpad {
    tap enabled
}

# Output configuration
output * bg ~/.config/wallpaper.jpeg fill
output * scale 1.3

# Idle configuration
exec swayidle \
    timeout 300 'exec $lock' \
    timeout 600 'swaymsg "output * dpms off"' \
    after-resume 'swaymsg "output * dpms on"' \
    before-sleep 'exec $lock'

# Toggle the current focus between tiling and floating mode
bindsym $mod+Shift+space floating toggle

# Move the currently focused window to the scratchpad
bindsym $mod+z move scratchpad
# Show the next scratchpad window or hide the focused scratchpad window.
# If there are multiple scratchpad windows, this command cycles through them.
bindsym $mod+x scratchpad show

# Modes
mode "resize" {
    bindsym Left resize shrink width 10px
    bindsym Down resize grow height 10px
    bindsym Up resize shrink height 10px
    bindsym Right resize grow width 10px

    # return to default mode
    bindsym Return mode "default"
    bindsym Escape mode "default"
}
bindsym $mod+Control+r mode "resize"

# Include keybinds
include ~/.config/sway/keybinds

INSTALL GAMMASTEP - temporary until Swayfx filter system is finished