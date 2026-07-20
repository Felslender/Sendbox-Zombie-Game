class_name Barricade
extends Node2D

var entity_kind := "barricade"
var entity_manager
var navigation_service: NavigationService
var health := GameConfig.BARRICADE_HEALTH
var vertical := false
var footprint := Rect2()
var hit_flash := 0.0
var registered := false

func setup(manager, navigation: NavigationService, start_position: Vector2, is_vertical: bool) -> bool:
	entity_manager = manager
	navigation_service = navigation
	global_position = start_position
	vertical = is_vertical
	var size := GameConfig.BARRICADE_SIZE
	if vertical:
		size = Vector2(size.y, size.x)
	footprint = Rect2(global_position - size * 0.5, size)
	registered = navigation_service.add_dynamic_obstacle(get_instance_id(), footprint)
	z_index = 6
	queue_redraw()
	return registered

func _process(delta: float) -> void:
	if hit_flash > 0.0:
		hit_flash = maxf(0.0, hit_flash - delta)
		queue_redraw()

func take_damage(amount: float) -> void:
	if health <= 0.0:
		return
	health -= amount
	hit_flash = 0.16
	queue_redraw()
	if health <= 0.0:
		navigation_service.remove_dynamic_obstacle(get_instance_id())
		registered = false
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color(0.55, 0.35, 0.2, 0.0), 0.35)
		tween.tween_callback(entity_manager.remove_barricade.bind(self))

func _exit_tree() -> void:
	if registered and navigation_service != null:
		navigation_service.remove_dynamic_obstacle(get_instance_id())
		registered = false

func _draw() -> void:
	var size := footprint.size
	var local_rect := Rect2(-size * 0.5, size)
	var wood := GameConfig.COLORS.barricade.lightened(0.18 if hit_flash > 0.0 else 0.0)
	draw_rect(local_rect, Color(0.08, 0.07, 0.06, 0.5))
	if vertical:
		for x in [-7.0, 7.0]:
			draw_rect(Rect2(x - 4.0, -size.y * 0.5, 8.0, size.y), wood)
		for y in [-22.0, 0.0, 22.0]:
			draw_line(Vector2(-size.x * 0.5, y), Vector2(size.x * 0.5, y), wood.darkened(0.15), 5.0)
	else:
		for y in [-7.0, 7.0]:
			draw_rect(Rect2(-size.x * 0.5, y - 4.0, size.x, 8.0), wood)
		for x in [-22.0, 0.0, 22.0]:
			draw_line(Vector2(x, -size.y * 0.5), Vector2(x, size.y * 0.5), wood.darkened(0.15), 5.0)
	var health_ratio := clampf(health / GameConfig.BARRICADE_HEALTH, 0.0, 1.0)
	if health_ratio < 1.0:
		draw_rect(Rect2(-size.x * 0.5, -size.y * 0.5 - 8.0, size.x, 3.0), Color(0.1, 0.1, 0.1, 0.85))
		draw_rect(Rect2(-size.x * 0.5, -size.y * 0.5 - 8.0, size.x * health_ratio, 3.0), Color("#f0bd62"))
