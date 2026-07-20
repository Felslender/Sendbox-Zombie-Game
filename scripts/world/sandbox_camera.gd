extends Camera2D

const PAN_SPEED := 560.0
const MIN_ZOOM := 0.62
const MAX_ZOOM := 1.75

var dragging := false
var target_zoom := Vector2.ONE

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	position = GameConfig.MAP_SIZE * 0.5
	target_zoom = zoom

func _process(delta: float) -> void:
	var direction := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	if direction.length_squared() > 0.0:
		position += direction * PAN_SPEED * delta / zoom.x
	zoom = zoom.lerp(target_zoom, minf(1.0, delta * 12.0))
	_clamp_position()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			dragging = event.pressed
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_set_zoom(target_zoom.x * 1.12)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_set_zoom(target_zoom.x / 1.12)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and dragging:
		position -= event.relative / zoom.x
		_clamp_position()
		get_viewport().set_input_as_handled()

func _set_zoom(value: float) -> void:
	var bounded := clampf(value, MIN_ZOOM, MAX_ZOOM)
	target_zoom = Vector2(bounded, bounded)

func _clamp_position() -> void:
	position = position.clamp(Vector2.ZERO, GameConfig.MAP_SIZE)
