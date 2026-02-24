class_name StabilityPanel
extends PanelContainer
## Displays stability meter (0-100) with color-coded alert level.

const ALERT_COLORS: Dictionary = {
	&"normal": Color(0.3, 0.8, 0.3),
	&"yellow": Color(0.9, 0.9, 0.2),
	&"red": Color(0.9, 0.2, 0.2),
	&"final": Color(0.5, 0.0, 0.0),
}

@onready var stability_bar: ProgressBar = %StabilityBar
@onready var stability_label: Label = %StabilityLabel
@onready var alert_label: Label = %AlertLabel


func _ready() -> void:
	stability_bar.min_value = 0
	stability_bar.max_value = 100
	EventBus.stability_changed.connect(_on_stability_changed)
	EventBus.alert_level_changed.connect(_on_alert_level_changed)
	_init_from_current_state()


func _on_stability_changed(new_value: int, _old_value: int) -> void:
	stability_bar.value = new_value
	stability_label.text = "Stability: %d" % new_value


func _on_alert_level_changed(new_level: StringName) -> void:
	_apply_alert_color(new_level)


func _apply_alert_color(level: StringName) -> void:
	var color: Color = ALERT_COLORS.get(level, Color.WHITE)
	var fill := stability_bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
	if fill:
		fill.bg_color = color
		stability_bar.add_theme_stylebox_override("fill", fill)
	alert_label.text = level.capitalize()
	alert_label.add_theme_color_override("font_color", color)


func _init_from_current_state() -> void:
	stability_bar.value = 100
	stability_label.text = "Stability: 100"
	_apply_alert_color(&"normal")
