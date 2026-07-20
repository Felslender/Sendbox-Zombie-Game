class_name AgentBase
extends CharacterBody2D

var entity_kind := "agent"
var navigation_service: NavigationService
var entity_manager
var movement_speed := 60.0
var body_color := Color.WHITE
var radius := 8.0
var current_path := PackedVector2Array()
var path_index := 0
var destination := Vector2.ZERO
var index_update_timer := 0.0
var route_refresh_timer := 0.0
var facing := Vector2.DOWN

func setup_base(manager, navigation: NavigationService, start_position: Vector2) -> void:
	entity_manager = manager
	navigation_service = navigation
	global_position = start_position
	index_update_timer = randf_range(0.0, 0.35)
	route_refresh_timer = randf_range(0.1, 0.5)
	collision_layer = 0
	collision_mask = 0
	queue_redraw()

func set_destination(new_destination: Vector2, force: bool = false) -> void:
	new_destination = navigation_service.clamp_to_map(new_destination)
	if not force and destination.distance_squared_to(new_destination) < 32.0 * 32.0 and not current_path.is_empty():
		return
	destination = new_destination
	current_path = navigation_service.find_path(global_position, destination)
	path_index = 0
	while path_index < current_path.size() and global_position.distance_to(current_path[path_index]) < 12.0:
		path_index += 1
	route_refresh_timer = randf_range(1.2, 2.0)

func follow_path(delta: float, speed_multiplier: float = 1.0) -> bool:
	index_update_timer -= delta
	route_refresh_timer -= delta
	if index_update_timer <= 0.0:
		entity_manager.update_spatial_position(self)
		index_update_timer = randf_range(0.28, 0.42)

	if path_index >= current_path.size():
		velocity = Vector2.ZERO
		return true
	if not navigation_service.is_position_walkable(current_path[path_index]):
		set_destination(destination, true)
		if path_index >= current_path.size():
			velocity = Vector2.ZERO
			return true
	var target: Vector2 = current_path[path_index]
	var offset := target - global_position
	if offset.length() < 10.0:
		path_index += 1
		if path_index >= current_path.size():
			velocity = Vector2.ZERO
			return true
		target = current_path[path_index]
		offset = target - global_position
	var direction := offset.normalized()
	facing = direction
	velocity = direction * movement_speed * speed_multiplier
	move_and_slide()
	global_position = navigation_service.clamp_to_map(global_position)
	return false

func stop_moving() -> void:
	velocity = Vector2.ZERO
	current_path.clear()
	path_index = 0

func _draw() -> void:
	draw_circle(Vector2(2, 3), radius + 1.5, Color(0, 0, 0, 0.3))
	draw_circle(Vector2.ZERO, radius, body_color)
	draw_circle(Vector2.ZERO, radius, Color(1, 1, 1, 0.55), false, 1.5)
	draw_line(Vector2.ZERO, facing * (radius + 4.0), Color(1, 1, 1, 0.75), 2.0)
