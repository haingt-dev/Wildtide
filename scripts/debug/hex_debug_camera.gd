class_name HexDebugCamera
extends Camera3D
## Simple orbit camera for hex grid debug visualization.
## Right-click drag to orbit, scroll to zoom.

@export var orbit_speed: float = 0.3
@export var zoom_speed: float = 2.0
@export var min_distance: float = 5.0
@export var max_distance: float = 60.0
@export var initial_distance: float = 30.0

var _distance: float
var _rotation_x: float = -50.0  ## Pitch (degrees, negative = looking down)
var _rotation_y: float = 30.0  ## Yaw (degrees)
var _is_dragging: bool = false


func _ready() -> void:
	_distance = initial_distance
	_update_transform()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_is_dragging = mb.pressed
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			_distance = maxf(_distance - zoom_speed, min_distance)
			_update_transform()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_distance = minf(_distance + zoom_speed, max_distance)
			_update_transform()

	elif event is InputEventMouseMotion and _is_dragging:
		var motion := event as InputEventMouseMotion
		_rotation_y += motion.relative.x * orbit_speed
		_rotation_x -= motion.relative.y * orbit_speed
		_rotation_x = clampf(_rotation_x, -89.0, -10.0)
		_update_transform()


func _update_transform() -> void:
	var pitch := deg_to_rad(_rotation_x)
	var yaw := deg_to_rad(_rotation_y)

	var offset := Vector3(
		_distance * cos(pitch) * sin(yaw),
		-_distance * sin(pitch),
		_distance * cos(pitch) * cos(yaw),
	)

	global_position = offset
	look_at(Vector3.ZERO, Vector3.UP)
