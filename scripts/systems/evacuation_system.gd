class_name EvacuationSystem
extends Node2D

const ZONE_SCRIPT := preload("res://scripts/systems/evacuation_zone.gd")

var entity_manager
var events: SimulationEvents
var zones: Array = []

func setup(manager, event_bus: SimulationEvents) -> void:
	entity_manager = manager
	events = event_bus

func deploy_zone(at_position: Vector2):
	if not can_deploy(at_position):
		return null
	var zone = ZONE_SCRIPT.new()
	add_child(zone)
	zone.setup(self, at_position)
	zones.append(zone)
	return zone

func can_deploy(at_position: Vector2) -> bool:
	_cleanup_zones()
	if zones.size() >= GameConfig.EVACUATION_MAX_ZONES:
		return false
	for zone in zones:
		if zone.global_position.distance_to(at_position) < GameConfig.EVACUATION_RADIUS * 2.2:
			return false
	return true

func nearest_available_zone(from_position: Vector2):
	var best = null
	var best_distance_squared := GameConfig.EVACUATION_ATTRACTION_RADIUS * GameConfig.EVACUATION_ATTRACTION_RADIUS
	for zone in zones:
		if not is_instance_valid(zone) or not zone.has_capacity():
			continue
		var distance_squared := from_position.distance_squared_to(zone.global_position)
		if distance_squared < best_distance_squared:
			best = zone
			best_distance_squared = distance_squared
	return best

func zone_deactivated(zone) -> void:
	zones.erase(zone)
	events.feedback_requested.emit("Zona de evacuação encerrada", false)

func active_zone_count() -> int:
	_cleanup_zones()
	return zones.size()

func _cleanup_zones() -> void:
	zones = zones.filter(func(zone): return is_instance_valid(zone) and not zone.is_queued_for_deletion() and zone.active)
