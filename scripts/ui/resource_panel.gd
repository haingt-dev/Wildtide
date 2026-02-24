class_name ResourcePanel
extends PanelContainer
## Displays gold and mana amounts with capacity bars.

var economy_manager: EconomyManager

@onready var gold_label: Label = %GoldLabel
@onready var gold_bar: ProgressBar = %GoldBar
@onready var mana_label: Label = %ManaLabel
@onready var mana_bar: ProgressBar = %ManaBar


func _ready() -> void:
	EventBus.gold_changed.connect(_on_gold_changed)
	EventBus.mana_changed.connect(_on_mana_changed)
	_init_from_current_state()


func _on_gold_changed(new_amount: int, _old_amount: int) -> void:
	_update_gold(new_amount)


func _on_mana_changed(new_amount: int, _old_amount: int) -> void:
	_update_mana(new_amount)


func _update_gold(amount: int) -> void:
	var cap: int = _get_gold_capacity()
	gold_label.text = "Gold: %d / %d" % [amount, cap]
	gold_bar.max_value = float(cap)
	gold_bar.value = float(amount)


func _update_mana(amount: int) -> void:
	var cap: int = _get_mana_capacity()
	mana_label.text = "Mana: %d / %d" % [amount, cap]
	mana_bar.max_value = float(cap)
	mana_bar.value = float(amount)


func _get_gold_capacity() -> int:
	if economy_manager:
		return economy_manager.get_gold_capacity()
	return 100


func _get_mana_capacity() -> int:
	if economy_manager:
		return economy_manager.get_mana_capacity()
	return 100


func _init_from_current_state() -> void:
	if economy_manager:
		_update_gold(economy_manager.get_gold())
		_update_mana(economy_manager.get_mana())
	else:
		gold_label.text = "Gold: 0 / 100"
		mana_label.text = "Mana: 0 / 100"
