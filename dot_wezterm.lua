local wezterm = require("wezterm")
local mux = wezterm.mux
local config = {}

wezterm.on("gui-startup", function(cmd)
	local tab, pane, window = mux.spawn_window(cmd or {})
	window:gui_window():maximize()
end)

if wezterm.config_builder then
	config = wezterm.config_builder()
end

local schemes = { "Catppuccin Mocha", "Batman", "Dracula" }
local fonts = { "JetBrainsMono Nerd Font Mono", "FiraCode Nerd Font", "Hack Nerd Font Mono" }
config.color_scheme = schemes[1]
config.font = wezterm.font(fonts[1], { weight = "Book" })
config.font_size = 15
config.use_fancy_tab_bar = false
config.enable_tab_bar = false
config.window_padding = {
	left = 2,
	right = 2,
	top = 5,
	bottom = 2,
}
config.inactive_pane_hsb = {
	saturation = 0.8,
	brightness = 0.8,
}
config.window_background_opacity = 0.9
config.window_close_confirmation = "NeverPrompt"
config.window_decorations = "RESIZE"
config.default_cursor_style = "BlinkingUnderline"

config.automatically_reload_config = true

return config
