set $mod Mod4

# Development settings to be disabled later!
bindsym Ctrl+Shift+r exec ags quit; ags -b hypr && hyprctl reload # Restart Ags

# Volume buttons + media controls
bindsym XF86AudioRaiseVolume exec 'audio.speaker.volume += 0.05; indicator.speaker()'
bindsym XF86AudioLowerVolume exec 'audio.speaker.volume -= 0.05; indicator.speaker()'
bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
bindsym XF86AudioPlay exec playerctl play-pause
bindsym XF86AudioNext exec playerctl next
bindsym XF86AudioPrev exec playerctl previous

# Brightness buttons
bindsym XF86MonBrightnessUp exec ags -r 'brightness.screen += 0.05; indicator.display()'
bindsym XF86MonBrightnessDown exec ags -r 'brightness.screen -= 0.05; indicator.display()'

# Quick application access
bindsym $mod+e exec microsoft-edge-stable --enable-features=UseOzonePlatform --ozone-platform=wayland --gtk-version=4 --enable-wayland-ime
bindsym $mod+Return exec foot # Terminal

# Wofi features
bindsym $mod+period exec bemoji -n # Emoji picker
bindsym $mod+v exec cliphist list | wofi --dmenu --allow-images | cliphist decode | wl-copy

# Screenshot and screen recording tools
bindsym $mod+r exec ags -r 'recorder.start()' 
bindsym Print exec ags -r 'recorder.screenshot()'
bindsym Print+Shift exec ags -r 'recorder.screenshot(true)' # Fullscreen screenshot

# Desktop utilities
bindsym $mod+s togglefloating # Make window non-tiling

# App launcher
bindsym $mod+space exec ags -t applauncher

# Using $mod + F will make that workspace floating
bindsym $mod+f workspace all floating enable

# Move windows around
bindsym $mod+Shift+Left move left
bindsym $mod+Shift+Right move right
bindsym $mod+Shift+Up move up
bindsym $mod+Shift+Down move down

# Workspace, window, tab switch with keyboard
bindsym Control+$mod+Right workspace next
bindsym Control+$mod+Left workspace prev
bindsym Control+$mod+bracketleft workspace prev
bindsym Control+$mod+bracketright workspace next
bindsym Control+$mod+Button1 workspace prev
bindsym Control+$mod+Button2 workspace next
bindsym Control+$mod+Shift+Right move to workspace next
bindsym Control+$mod+Shift+Left move to workspace prev

# Alt+Tab functionality
bindsym Alt+Tab focus right
bindsym Alt+Shift+Tab focus left

# Fullscreen
bindsym F11 fullscreen toggle # F11 functionality

# Close window
bindsym $mod+q kill

# Scroll through workspaces
bindsym $mod+Button4 workspace next
bindsym $mod+Button5 workspace prev

# Move and resize windows
bindsym $mod+Button1 move
bindsym $mod+Button3 resize

# Reload sway easily
bindsym Mod4+Shift+c reload