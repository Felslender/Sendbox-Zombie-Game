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

func _assert(condition: bool, description: String) -> void:
	if condition:
		print("  PASS  ", description)
	else:
		failures += 1
		push_error("  FAIL  " + description)
