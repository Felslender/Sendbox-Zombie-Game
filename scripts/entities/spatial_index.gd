class_name SpatialIndex
extends RefCounted

var cell_size := GameConfig.SPATIAL_CELL_SIZE
var buckets: Dictionary = {}
var entity_cells: Dictionary = {}

func add(entity: Node2D) -> void:
	var key := _cell_for(entity.global_position)
	var id := entity.get_instance_id()
	entity_cells[id] = key
	if not buckets.has(key):
		buckets[key] = []
	buckets[key].append(entity)

func update(entity: Node2D) -> void:
	var id := entity.get_instance_id()
	var new_cell := _cell_for(entity.global_position)
	if not entity_cells.has(id):
		add(entity)
		return
	var old_cell: Vector2i = entity_cells[id]
	if old_cell == new_cell:
		return
	_remove_from_bucket(entity, old_cell)
	entity_cells[id] = new_cell
	if not buckets.has(new_cell):
		buckets[new_cell] = []
	buckets[new_cell].append(entity)

func remove(entity: Node2D) -> void:
	var id := entity.get_instance_id()
	if not entity_cells.has(id):
		return
	var key: Vector2i = entity_cells[id]
	_remove_from_bucket(entity, key)
	entity_cells.erase(id)

func nearby(position: Vector2, radius: float, entity_kind: String = "") -> Array:
	var result: Array = []
	var min_cell := _cell_for(position - Vector2.ONE * radius)
	var max_cell := _cell_for(position + Vector2.ONE * radius)
	var radius_squared := radius * radius
	for y in range(min_cell.y, max_cell.y + 1):
		for x in range(min_cell.x, max_cell.x + 1):
			var key := Vector2i(x, y)
			if not buckets.has(key):
				continue
			for entity in buckets[key]:
				if not is_instance_valid(entity) or entity.is_queued_for_deletion():
					continue
				if entity_kind != "" and entity.entity_kind != entity_kind:
					continue
				if position.distance_squared_to(entity.global_position) <= radius_squared:
					result.append(entity)
	return result

func nearest(position: Vector2, radius: float, entity_kind: String, exclude: Node = null):
	var best = null
	var best_distance_squared := radius * radius
	for entity in nearby(position, radius, entity_kind):
		if entity == exclude:
			continue
		var distance_squared := position.distance_squared_to(entity.global_position)
		if distance_squared < best_distance_squared:
			best = entity
			best_distance_squared = distance_squared
	return best

func clear() -> void:
	buckets.clear()
	entity_cells.clear()

func _cell_for(position: Vector2) -> Vector2i:
	return Vector2i(floori(position.x / cell_size), floori(position.y / cell_size))

func _remove_from_bucket(entity: Node2D, key: Vector2i) -> void:
	if not buckets.has(key):
		return
	buckets[key].erase(entity)
	if buckets[key].is_empty():
		buckets.erase(key)
