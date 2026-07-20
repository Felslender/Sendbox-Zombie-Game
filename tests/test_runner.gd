extends SceneTree

class TestEntity:
	extends Node2D
	var entity_kind := "civilian"

var failures := 0

func _init() -> void:
	print("Zona Zero — testes de lógica")
	_test_navigation()
	_test_spatial_index()
	_test_configuration()
	if failures == 0:
		print("OK: todos os testes passaram.")
		quit(0)
	else:
		push_error("%d teste(s) falharam." % failures)
		quit(1)

func _test_navigation() -> void:
	var navigation := NavigationService.new()
	root.add_child(navigation)
	navigation.setup(GameConfig.MAP_SIZE, GameConfig.obstacle_rects())
	_assert(not navigation.is_position_walkable(Vector2(200, 180)), "edifício deve bloquear navegação")
	_assert(navigation.is_position_walkable(Vector2(460, 350)), "avenida deve ser navegável")
	var path := navigation.find_path(Vector2(80, 180), Vector2(520, 180))
	_assert(path.size() > 2, "A* deve contornar um edifício")
	for point in path:
		_assert(navigation.is_position_walkable(point), "todos os pontos da rota devem ser válidos")
	var dynamic_rect := Rect2(Vector2(424, 338), GameConfig.BARRICADE_SIZE)
	_assert(navigation.can_place_dynamic_obstacle(dynamic_rect), "rua deve aceitar obstáculo dinâmico")
	_assert(navigation.add_dynamic_obstacle(1001, dynamic_rect), "obstáculo dinâmico deve ser registrado")
	_assert(not navigation.is_position_walkable(dynamic_rect.get_center()), "obstáculo dinâmico deve bloquear a grade")
	var detour := navigation.find_path(Vector2(400, 350), Vector2(520, 350))
	_assert(not detour.is_empty(), "A* deve recalcular rota ao redor da barricada")
	for point in detour:
		_assert(navigation.is_position_walkable(point), "desvio dinâmico não pode atravessar a barricada")
	navigation.remove_dynamic_obstacle(1001)
	_assert(navigation.is_position_walkable(dynamic_rect.get_center()), "remoção deve liberar novamente a grade")
	navigation.queue_free()

func _test_spatial_index() -> void:
	var index := SpatialIndex.new()
	var nearby_entity := TestEntity.new()
	var distant_entity := TestEntity.new()
	nearby_entity.position = Vector2(100, 100)
	distant_entity.position = Vector2(700, 700)
	index.add(nearby_entity)
	index.add(distant_entity)
	_assert(index.nearby(Vector2(110, 110), 80.0, "civilian").size() == 1, "consulta espacial deve limitar o raio")
	nearby_entity.position = Vector2(650, 650)
	index.update(nearby_entity)
	_assert(index.nearby(Vector2(110, 110), 80.0, "civilian").is_empty(), "índice deve acompanhar movimento")
	index.remove(distant_entity)
	_assert(index.nearby(Vector2(700, 700), 100.0, "civilian").size() == 1, "remoção deve limpar somente a entidade correta")
	nearby_entity.free()
	distant_entity.free()

func _test_configuration() -> void:
	_assert(GameConfig.CIVILIAN_COUNT >= 30, "MVP deve iniciar com pelo menos 30 civis")
	_assert(GameConfig.GAS_INCUBATION > 0.0, "incubação deve ser positiva")
	_assert(GameConfig.POLICE_ATTACK_RANGE > GameConfig.POLICE_SAFE_RANGE, "alcance de ataque deve permitir distância segura")
	_assert(GameConfig.EVACUATION_CAPACITY > 0, "zona de evacuação deve ter capacidade")
	_assert(GameConfig.EVACUATION_MAX_ZONES >= 1, "ao menos uma zona de evacuação deve ser permitida")
	_assert(GameConfig.BARRICADE_HEALTH > GameConfig.BARRICADE_ZOMBIE_DAMAGE, "barricada deve resistir a mais de um ataque")
	_assert(GameConfig.PANIC_SPREAD_RADIUS > GameConfig.PANIC_GROUP_RADIUS, "pânico deve se espalhar além do grupo imediato")

func _assert(condition: bool, description: String) -> void:
	if condition:
		print("  PASS  ", description)
	else:
		failures += 1
		push_error("  FAIL  " + description)
