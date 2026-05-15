{
  programs.neovim.initLua = ''
    vim.g.neovide_opacity = 0.9
    vim.o.guifont = "Iosevka Nerd Font Mono:h14"
    vim.o.termguicolors = true

    vim.g.neovide_padding_top = 2
    vim.g.neovide_padding_bottom = 2
    vim.g.neovide_padding_right = 2
    vim.g.neovide_padding_left = 2

    vim.g.neovide_floating_blur_amount_x = 2.0
    vim.g.neovide_floating_blur_amount_y = 2.0

    vim.g.neovide_floating_shadow = true
    vim.g.neovide_floating_z_height = 10
    vim.g.neovide_light_angle_degrees = 45
    vim.g.neovide_light_radius = 5
    vim.g.neovide_floating_corner_radius = 0.0

    vim.g.neovide_position_animation_length = 0.3

    vim.g.neovide_progress_bar_enabled = true
    vim.g.neovide_progress_bar_height = 5.0
    vim.g.neovide_progress_bar_animation_speed = 200.0
    vim.g.neovide_progress_bar_hide_delay = 0.2

    vim.g.neovide_hide_mouse_when_typing = true
    vim.g.neovide_underline_stroke_scale = 1.5

    -- functionality
    --vim.g.neovide_refresh_rate = 144
    vim.g.neovide_input_ime = true

    -- looks
    vim.g.neovide_cursor_animation_length = 0.1
    vim.g.neovide_cursor_short_animation_length = 0.05
    vim.g.neovide_cursor_trail_size = 0.5

    vim.g.neovide_cursor_antialiasing = true -- disable if not needed?
    vim.g.neovide_cursor_animate_in_insert_mode = true
    vim.g.neovide_cursor_animate_command_line = true

    vim.g.neovide_cursor_unfocused_outline_width = 0.1
    vim.g.neovide_cursor_smooth_blink = true
    vim.g.neovide_cursor_vfx_mode = "pixiedust"
    vim.g.neovide_cursor_vfx_opacity = 100.0
    vim.g.neovide_cursor_vfx_particle_lifetime = 0.3
    vim.g.neovide_cursor_vfx_particle_highlight_lifetime = 0.1
    vim.g.neovide_cursor_vfx_particle_density = 0.9
    vim.g.neovide_cursor_vfx_particle_speed = 10.0
  '';
}