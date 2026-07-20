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
	var evacuation: EvacuationSystem = game.get_node("EvacuationSystem")
	var placement: PlacementController = game.get_node("PlacementController")
	_assert(manager.civilians.size() == GameConfig.CIVILIAN_COUNT, "população inicial criada")

	var barricade_position := Vector2(705, 350)
	placement.select_tool("barricade")
	placement._try_place(barricade_position)
	_assert(manager.barricades.size() == 1, "ferramenta constrói barricada em uma rua")
	_assert(not navigation.is_position_walkable(barricade_position), "barricada bloqueia a navegação")
	manager.barricades[0].health = GameConfig.BARRICADE_ZOMBIE_DAMAGE
	var breaker_zombie = manager.spawn_zombie(Vector2(650, 350))
	await create_timer(1.4).timeout
	_assert(manager.barricades.is_empty(), "zumbi próximo destrói a barricada")
	_assert(navigation.is_position_walkable(barricade_position), "rota é liberada após a destruição")
	if is_instance_valid(breaker_zombie) and not breaker_zombie.is_queued_for_deletion():
		manager.remove_zombie(breaker_zombie)
	await process_frame

	var panic_source = manager.civilians[0]
	var panic_receiver = manager.civilians[1]
	panic_source.global_position = Vector2(460, 350)
	panic_receiver.global_position = Vector2(485, 350)
	manager.update_spatial_position(panic_source)
	manager.update_spatial_position(panic_receiver)
	panic_source.panic_level = 1.0
	panic_source.state = CivilianAgent.State.FLEE
	panic_receiver.panic_level = 0.0
	panic_receiver._update_social_state()
	_assert(panic_receiver.panic_level > 0.4, "pânico se propaga entre civis próximos")
	panic_source.panic_level = 0.0
	panic_receiver.panic_level = 0.0
	panic_source.state = CivilianAgent.State.WANDER
	panic_receiver.state = CivilianAgent.State.WANDER
	panic_receiver._update_social_state()
	_assert(panic_receiver.group_leader != null, "civis próximos formam um grupo leve")

	var civilian_to_rescue = manager.civilians[0]
	placement.select_tool("evacuation")
	placement._try_place(civilian_to_rescue.global_position)
	_assert(evacuation.active_zone_count() == 1, "ferramenta cria zona de evacuação em área válida")
	_assert(placement.evacuation_cooldown > 0.0, "ferramenta de evacuação entra em recarga")
	await create_timer(3.0).timeout
	_assert(manager.rescued_count >= 1, "civil alcança a zona e é resgatado")
	_assert(manager.civilians.size() <= GameConfig.CIVILIAN_COUNT - 1, "civil resgatado sai da população ativa")

	var civilian = manager.civilians[0]
	var outbreak_position: Vector2 = civilian.global_position
	_assert(civilian.infect(0.12), "civil pode ser infectado")
	await create_timer(1.1).timeout
	_assert(manager.zombies.size() == 1, "incubação transforma civil em zumbi")

	if not manager.zombies.is_empty():
		var zombie = manager.zombies[0]
		zombie.health = GameConfig.POLICE_DAMAGE
		var police_position := _nearby_walkable(navigation, zombie.global_position, 110.0)
		manager.spawn_police(police_position)
		_assert(manager.police_units.size() == 1, "policial pode ser posicionado")
		await create_timer(1.5).timeout
		_assert(not is_instance_valid(zombie) or zombie.is_queued_for_deletion() or zombie.health <= 0.0, "policial detecta e neutraliza zumbi")

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
