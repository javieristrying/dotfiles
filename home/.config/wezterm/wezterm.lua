local wezterm = require("wezterm")

local config = wezterm.config_builder()

config.color_scheme = "rose-pine-moon"
config.font = wezterm.font("CaskaydiaMono Nerd Font")
config.font_size = 14.0
config.window_background_opacity = 0.8
config.macos_window_background_blur = 50
config.hide_tab_bar_if_only_one_tab = true
config.window_decorations = "RESIZE|MACOS_FORCE_SQUARE_CORNERS"
config.window_padding = { left = 16, right = 16, top = 16, bottom = 16 }

return config
