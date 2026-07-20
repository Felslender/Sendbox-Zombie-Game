class_name InfectionSystem
extends Node2D

var entity_manager
var events: SimulationEvents
var clouds: Array[Dictionary] = []

func setup(manager, event_bus: SimulationEvents) -> void:
	entity_manager = manager
	events = event_bus
	z_index = 5

func deploy_gas(at_position: Vector2) -> void:
	clouds.append({
		"position": at_position,
		"remaining": GameConfig.GAS_DURATION,
		"duration": GameConfig.GAS_DURATION,
		"pulse": 0.0,
		"touched": {},
	})
	_apply_cloud(clouds.size() - 1)
	queue_redraw()

func _process(delta: float) -> void:
	var changed := false
	for index in range(clouds.size() - 1, -1, -1):
		clouds[index].remaining -= delta
		clouds[index].pulse -= delta
		if clouds[index].remaining <= 0.0:
			clouds.remove_at(index)
			changed = true
			continue
		if clouds[index].pulse <= 0.0:
			clouds[index].pulse = 0.3
			_apply_cloud(index)
		changed = true
	if not clouds.is_empty() or changed:
		queue_redraw()

func _apply_cloud(index: int) -> void:
	if index < 0 or index >= clouds.size():
		return
	var cloud := clouds[index]
	for civilian in entity_manager.get_nearby(cloud.position, GameConfig.GAS_RADIUS, "civilian"):
		var id: int = civilian.get_instance_id()
		if cloud.touched.has(id):
			continue
		cloud.touched[id] = true
		if randf() <= GameConfig.GAS_INFECTION_CHANCE and civilian.infect(GameConfig.GAS_INCUBATION):
			events.feedback_requested.emit("Civil infectado — incubação iniciada", false)
	clouds[index] = cloud

func _draw() -> void:
	for cloud in clouds:
		var life_ratio: float = clampf(cloud.remaining / cloud.duration, 0.0, 1.0)
		var pulse := sin(cloud.remaining * 5.0) * 4.0
		var color := Color(0.52, 0.87, 0.28, 0.13 + life_ratio * 0.15)
		draw_circle(cloud.position, GameConfig.GAS_RADIUS + pulse, color)
		draw_arc(cloud.position, GameConfig.GAS_RADIUS + pulse, 0.0, TAU, 48, Color(0.65, 1.0, 0.35, life_ratio * 0.65), 3.0)
		for offset in [Vector2(-35, -12), Vector2(28, -30), Vector2(15, 31), Vector2(-18, 25)]:
			draw_circle(cloud.position + offset, 12.0 + pulse * 0.4, Color(0.65, 0.95, 0.35, 0.12))
