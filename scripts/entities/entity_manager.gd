class_name EntityManager
extends Node2D

const CIVILIAN_SCRIPT := preload("res://scripts/entities/civilian_agent.gd")
const BARRICADE_SCRIPT := preload("res://scripts/entities/barricade.gd")

var navigation_service: NavigationService
var events: SimulationEvents
var spatial_index := SpatialIndex.new()
var civilians: Array = []
var zombies: Array = []
var police_units: Array = []
var barricades: Array = []
var evacuation_system: EvacuationSystem
var rescued_count := 0
var metrics_timer := 0.0
var last_metrics: Dictionary = {}

func setup(navigation: NavigationService, event_bus: SimulationEvents) -> void:
	navigation_service = navigation
	events = event_bus

func set_evacuation_system(system: EvacuationSystem) -> void:
	evacuation_system = system

func spawn_initial_population(count: int) -> void:
	for index in range(count):
		spawn_civilian(navigation_service.random_walkable_position())

func spawn_civilian(at_position: Vector2):
	var civilian = CIVILIAN_SCRIPT.new()
	add_child(civilian)
	civilian.setup(self, navigation_service, at_position)
	civilians.append(civilian)
	spatial_index.add(civilian)
	return civilian

func transform_civilian(civilian) -> void:
	if not is_instance_valid(civilian) or civilian.is_queued_for_deletion():
		return
	var spawn_position: Vector2 = civilian.global_position
	_unregister(civilian, civilians)
	civilian.state = CivilianAgent.State.REMOVED
	civilian.queue_free()
	spawn_zombie(spawn_position)

func spawn_zombie(at_position: Vector2):
	var zombie_script = load("res://scripts/entities/zombie_agent.gd")
	var zombie = zombie_script.new()
	add_child(zombie)
	zombie.setup(self, navigation_service, at_position)
	zombies.append(zombie)
	spatial_index.add(zombie)
	return zombie

func spawn_police(at_position: Vector2):
	var police_script = load("res://scripts/entities/police_agent.gd")
	var officer = police_script.new()
	add_child(officer)
	officer.setup(self, navigation_service, at_position)
	police_units.append(officer)
	spatial_index.add(officer)
	return officer

func can_place_barricade(at_position: Vector2, vertical: bool) -> bool:
	if barricades.size() >= GameConfig.BARRICADE_MAX_COUNT:
		return false
	var size := GameConfig.BARRICADE_SIZE
	if vertical:
		size = Vector2(size.y, size.x)
	return navigation_service.can_place_dynamic_obstacle(Rect2(at_position - size * 0.5, size))

func spawn_barricade(at_position: Vector2, vertical: bool):
	if not can_place_barricade(at_position, vertical):
		return null
	var barricade = BARRICADE_SCRIPT.new()
	add_child(barricade)
	if not barricade.setup(self, navigation_service, at_position, vertical):
		barricade.queue_free()
		return null
	barricades.append(barricade)
	spatial_index.add(barricade)
	return barricade

func remove_barricade(barricade) -> void:
	if not is_instance_valid(barricade) or barricade.is_queued_for_deletion():
		return
	_unregister(barricade, barricades)
	barricade.queue_free()

func remove_zombie(zombie) -> void:
	if not is_instance_valid(zombie) or zombie.is_queued_for_deletion():
		return
	_unregister(zombie, zombies)
	zombie.queue_free()

func rescue_civilian(civilian, zone: EvacuationZone) -> void:
	if not is_instance_valid(civilian) or civilian.is_queued_for_deletion():
		return
	if is_instance_valid(zone):
		zone.complete_rescue()
	_unregister(civilian, civilians)
	civilian.state = CivilianAgent.State.RESCUED
	civilian.stop_moving()
	rescued_count += 1
	events.feedback_requested.emit("Civil resgatado com sucesso", false)
	var tween: Tween = civilian.create_tween()
	tween.set_parallel(true)
	tween.tween_property(civilian, "scale", Vector2(0.15, 0.15), 0.4)
	tween.tween_property(civilian, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(civilian.queue_free)

func update_spatial_position(entity: Node2D) -> void:
	if is_instance_valid(entity) and not entity.is_queued_for_deletion():
		spatial_index.update(entity)

func find_nearest(position: Vector2, radius: float, kind: String, exclude: Node = null):
	return spatial_index.nearest(position, radius, kind, exclude)

func find_nearest_healthy(position: Vector2, radius: float):
	var best = null
	var best_distance_squared := radius * radius
	for civilian in spatial_index.nearby(position, radius, "civilian"):
		if civilian.is_infected:
			continue
		var distance_squared := position.distance_squared_to(civilian.global_position)
		if distance_squared < best_distance_squared:
			best = civilian
			best_distance_squared = distance_squared
	return best

func get_nearby(position: Vector2, radius: float, kind: String = "") -> Array:
	return spatial_index.nearby(position, radius, kind)

func find_nearest_evacuation(position: Vector2):
	if evacuation_system == null:
		return null
	return evacuation_system.nearest_available_zone(position)

func publish_metrics(simulation_time: float) -> void:
	metrics_timer -= get_process_delta_time()
	if metrics_timer > 0.0:
		return
	metrics_timer = 0.2
	_cleanup_arrays()
	var infected := 0
	for civilian in civilians:
		if civilian.is_infected:
			infected += 1
	var metrics := {
		"healthy": civilians.size() - infected,
		"infected": infected,
		"zombies": zombies.size(),
		"rescued": rescued_count,
		"defense": police_units.size(),
		"barricades": barricades.size(),
		"panic": _average_panic(),
		"time": simulation_time,
		"fps": Engine.get_frames_per_second(),
	}
	if metrics != last_metrics:
		last_metrics = metrics
		events.metrics_changed.emit(metrics)

func _unregister(entity, collection: Array) -> void:
	spatial_index.remove(entity)
	collection.erase(entity)

func _cleanup_arrays() -> void:
	civilians = civilians.filter(func(entity): return is_instance_valid(entity) and not entity.is_queued_for_deletion())
	zombies = zombies.filter(func(entity): return is_instance_valid(entity) and not entity.is_queued_for_deletion())
	police_units = police_units.filter(func(entity): return is_instance_valid(entity) and not entity.is_queued_for_deletion())
	barricades = barricades.filter(func(entity): return is_instance_valid(entity) and not entity.is_queued_for_deletion())

func _average_panic() -> float:
	if civilians.is_empty():
		return 0.0
	var total := 0.0
	for civilian in civilians:
		total += civilian.panic_level
	return total / float(civilians.size())
