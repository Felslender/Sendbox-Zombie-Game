class_name EvacuationZone
extends Node2D

var evacuation_system
var capacity := GameConfig.EVACUATION_CAPACITY
var reserved_count := 0
var rescued_count := 0
var remaining := GameConfig.EVACUATION_DURATION
var active := true
var pulse := 0.0

func setup(system, at_position: Vector2) -> void:
	evacuation_system = system
	global_position = at_position
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	if not active:
		return
	remaining -= delta
	pulse += delta
	if remaining <= 0.0:
		deactivate()
	queue_redraw()

func has_capacity() -> bool:
	return active and rescued_count + reserved_count < capacity

func reserve_civilian() -> bool:
	if not has_capacity():
		return false
	reserved_count += 1
	queue_redraw()
	return true

func cancel_reservation() -> void:
	reserved_count = maxi(0, reserved_count - 1)
	queue_redraw()

func complete_rescue() -> void:
	reserved_count = maxi(0, reserved_count - 1)
	rescued_count += 1
	if rescued_count >= capacity:
		deactivate()
	queue_redraw()

func deactivate() -> void:
	if not active:
		return
	active = false
	evacuation_system.zone_deactivated(self)
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var color: Color = GameConfig.COLORS.evacuation
	var life_ratio := clampf(remaining / GameConfig.EVACUATION_DURATION, 0.0, 1.0)
	draw_circle(Vector2.ZERO, GameConfig.EVACUATION_RADIUS, Color(color, 0.08 + life_ratio * 0.05))
	draw_arc(Vector2.ZERO, GameConfig.EVACUATION_RADIUS, 0.0, TAU, 48, Color(color, 0.75), 3.0)
	draw_arc(Vector2.ZERO, GameConfig.EVACUATION_RADIUS - 8.0, -pulse, TAU - pulse, 32, Color(color, 0.32), 2.0)
	draw_circle(Vector2.ZERO, 25.0, Color(0.05, 0.15, 0.15, 0.82))
	draw_line(Vector2(-11, 0), Vector2(11, 0), color, 4.0)
	draw_line(Vector2(-11, -12), Vector2(-11, 12), color, 4.0)
	draw_line(Vector2(11, -12), Vector2(11, 12), color, 4.0)

	var occupied := rescued_count + reserved_count
	var start_angle := -PI * 0.5
	for index in range(capacity):
		var angle := start_angle + TAU * float(index) / float(capacity)
		var slot_color := color if index < occupied else Color(color, 0.2)
		draw_circle(Vector2.RIGHT.rotated(angle) * (GameConfig.EVACUATION_RADIUS - 15.0), 3.2, slot_color)
