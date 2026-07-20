extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("Zona Zero — teste integrado")
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	await process_frame

	var manager: EntityManager = game.get_node("EntityManager")
	var navigation: NavigationService = game.get_node("NavigationService")
	_assert(manager.civilians.size() == GameConfig.CIVILIAN_COUNT, "população inicial criada")

	var civilian = manager.civilians[0]
	var outbreak_position: Vector2 = civilian.global_position
	_assert(civilian.infect(0.12), "civil pode ser infectado")
	await create_timer(1.1).timeout
	_assert(manager.zombies.size() == 1, "incubação transforma civil em zumbi")

	if not manager.zombies.is_empty():
		var zombie = manager.zombies[0]
		var police_position := _nearby_walkable(navigation, zombie.global_position, 165.0)
		manager.spawn_police(police_position)
		_assert(manager.police_units.size() == 1, "policial pode ser posicionado")
		await create_timer(4.0).timeout
		_assert(manager.zombies.is_empty(), "policial detecta e neutraliza zumbi")

	game.queue_free()
	await process_frame
	if failures == 0:
		print("OK: teste integrado passou.")
		quit(0)
	else:
		push_error("%d verificação(ões) integradas falharam." % failures)
		quit(1)

func _nearby_walkable(navigation: NavigationService, origin: Vector2, distance: float) -> Vector2:
	for index in range(16):
		var angle := TAU * float(index) / 16.0
		var candidate := navigation.clamp_to_map(origin + Vector2.RIGHT.rotated(angle) * distance)
		if navigation.is_position_walkable(candidate):
			return candidate
	return navigation.random_walkable_position()

func _assert(condition: bool, description: String) -> void:
	if condition:
		print("  PASS  ", description)
	else:
		failures += 1
		push_error("  FAIL  " + description)
