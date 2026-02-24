class_name FactionPanel
extends PanelContainer
## Displays 4 faction morale bars (0-100).

const FACTION_DISPLAY: Dictionary = {
	&"the_lens": "The Lens",
	&"the_veil": "The Veil",
	&"the_coin": "The Coin",
	&"the_wall": "The Wall",
}

const FACTION_IDS: Array[StringName] = [&"the_lens", &"the_veil", &"the_coin", &"the_wall"]

var _morale_bars: Dictionary = {}
var _morale_labels: Dictionary = {}

@onready var lens_bar: ProgressBar = %LensBar
@onready var lens_label: Label = %LensLabel
@onready var veil_bar: ProgressBar = %VeilBar
@onready var veil_label: Label = %VeilLabel
@onready var coin_bar: ProgressBar = %CoinBar
@onready var coin_label: Label = %CoinLabel
@onready var wall_bar: ProgressBar = %WallBar
@onready var wall_label: Label = %WallLabel


func _ready() -> void:
	_morale_bars = {
		&"the_lens": lens_bar,
		&"the_veil": veil_bar,
		&"the_coin": coin_bar,
		&"the_wall": wall_bar,
	}
	_morale_labels = {
		&"the_lens": lens_label,
		&"the_veil": veil_label,
		&"the_coin": coin_label,
		&"the_wall": wall_label,
	}
	for fid: StringName in _morale_bars:
		(_morale_bars[fid] as ProgressBar).min_value = 0
		(_morale_bars[fid] as ProgressBar).max_value = 100
	EventBus.faction_morale_changed.connect(_on_faction_morale_changed)
	_init_from_current_state()


func _on_faction_morale_changed(faction_id: StringName, new_morale: int, _old_morale: int) -> void:
	_update_faction(faction_id, new_morale)


func _update_faction(faction_id: StringName, morale: int) -> void:
	if _morale_bars.has(faction_id):
		(_morale_bars[faction_id] as ProgressBar).value = morale
	if _morale_labels.has(faction_id):
		var display: String = FACTION_DISPLAY.get(faction_id, faction_id)
		(_morale_labels[faction_id] as Label).text = "%s: %d" % [display, morale]


func _init_from_current_state() -> void:
	for fid: StringName in FACTION_IDS:
		_update_faction(fid, 50)
