class_name HudThemeSetup
extends RefCounted
## Creates a minimal programmatic theme for the HUD.
## No font assets required — uses Godot defaults.


static func create_hud_theme() -> Theme:
	var theme := Theme.new()
	theme.set_default_font_size(16)
	_setup_panel_style(theme)
	_setup_progress_bar(theme)
	_setup_button_style(theme)
	return theme


static func _setup_panel_style(theme: Theme) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 0.85)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	theme.set_stylebox("panel", "PanelContainer", style)


static func _setup_progress_bar(theme: Theme) -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	bg.corner_radius_top_left = 2
	bg.corner_radius_top_right = 2
	bg.corner_radius_bottom_left = 2
	bg.corner_radius_bottom_right = 2
	theme.set_stylebox("background", "ProgressBar", bg)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.3, 0.7, 0.9, 1.0)
	fill.corner_radius_top_left = 2
	fill.corner_radius_top_right = 2
	fill.corner_radius_bottom_left = 2
	fill.corner_radius_bottom_right = 2
	theme.set_stylebox("fill", "ProgressBar", fill)


static func _setup_button_style(theme: Theme) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.2, 0.2, 0.28, 0.9)
	normal.corner_radius_top_left = 3
	normal.corner_radius_top_right = 3
	normal.corner_radius_bottom_left = 3
	normal.corner_radius_bottom_right = 3
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	theme.set_stylebox("normal", "Button", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.3, 0.3, 0.4, 0.9)
	theme.set_stylebox("hover", "Button", hover)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.15, 0.15, 0.22, 0.9)
	theme.set_stylebox("pressed", "Button", pressed)
