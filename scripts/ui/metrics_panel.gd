class_name MetricsPanel
extends PanelContainer
## Displays 4 metric bars (pollution, anxiety, solidarity, harmony)
## and a Science/Magic alignment slider (display-only).

const METRIC_COLORS: Dictionary = {
	&"pollution": Color(0.6, 0.2, 0.8),
	&"anxiety": Color(0.9, 0.3, 0.2),
	&"solidarity": Color(0.2, 0.7, 0.9),
	&"harmony": Color(0.3, 0.8, 0.3),
}

var _metric_bars: Dictionary = {}
var _metric_labels: Dictionary = {}

@onready var pollution_bar: ProgressBar = %PollutionBar
@onready var pollution_label: Label = %PollutionLabel
@onready var anxiety_bar: ProgressBar = %AnxietyBar
@onready var anxiety_label: Label = %AnxietyLabel
@onready var solidarity_bar: ProgressBar = %SolidarityBar
@onready var solidarity_label: Label = %SolidarityLabel
@onready var harmony_bar: ProgressBar = %HarmonyBar
@onready var harmony_label: Label = %HarmonyLabel
@onready var alignment_slider: HSlider = %AlignmentSlider


func _ready() -> void:
	_metric_bars = {
		&"pollution": pollution_bar,
		&"anxiety": anxiety_bar,
		&"solidarity": solidarity_bar,
		&"harmony": harmony_bar,
	}
	_metric_labels = {
		&"pollution": pollution_label,
		&"anxiety": anxiety_label,
		&"solidarity": solidarity_label,
		&"harmony": harmony_label,
	}
	alignment_slider.min_value = -1.0
	alignment_slider.max_value = 1.0
	alignment_slider.step = 0.01
	alignment_slider.editable = false
	for bar_name: StringName in _metric_bars:
		var bar: ProgressBar = _metric_bars[bar_name]
		bar.min_value = 0.0
		bar.max_value = 1.0
		var fill := bar.get_theme_stylebox("fill").duplicate() as StyleBoxFlat
		if fill:
			fill.bg_color = METRIC_COLORS.get(bar_name, Color.WHITE)
			bar.add_theme_stylebox_override("fill", fill)
	EventBus.metric_changed.connect(_on_metric_changed)
	EventBus.alignment_changed.connect(_on_alignment_changed)
	_init_from_current_state()


func _on_metric_changed(metric_name: StringName, new_value: float, _old_value: float) -> void:
	_update_metric(metric_name, new_value)


func _on_alignment_changed(new_alignment: float) -> void:
	alignment_slider.value = new_alignment


func _update_metric(metric_name: StringName, value: float) -> void:
	if _metric_bars.has(metric_name):
		(_metric_bars[metric_name] as ProgressBar).value = value
	if _metric_labels.has(metric_name):
		(_metric_labels[metric_name] as Label).text = (
			"%s: %.0f%%" % [metric_name.capitalize(), value * 100.0]
		)


func _init_from_current_state() -> void:
	for metric_name: StringName in MetricSystem.METRIC_NAMES:
		_update_metric(metric_name, MetricSystem.get_metric(metric_name))
	alignment_slider.value = MetricSystem.get_alignment()
