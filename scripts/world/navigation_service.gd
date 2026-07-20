class_name NavigationService
extends Node

var astar := AStarGrid2D.new()
var map_size := Vector2.ZERO
var cell_size := GameConfig.NAV_CELL_SIZE
var static_solid_cells: Dictionary = {}
var dynamic_cell_counts: Dictionary = {}
var dynamic_obstacles: Dictionary = {}

func setup(p_map_size: Vector2, obstacles: Array[Rect2]) -> void:
	map_size = p_map_size
	var dimensions := Vector2i(
		ceili(map_size.x / cell_size),
		ceili(map_size.y / cell_size)
	)
	astar.region = Rect2i(Vector2i.ZERO, dimensions)
	astar.cell_size = Vector2(cell_size, cell_size)
	astar.offset = Vector2(cell_size * 0.5, cell_size * 0.5)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()

	for obstacle in obstacles:
		var expanded := obstacle.grow(GameConfig.CIVILIAN_RADIUS + 3.0)
		var start := world_to_cell(expanded.position)
		var finish := world_to_cell(expanded.end)
		for y in range(start.y, finish.y + 1):
			for x in range(start.x, finish.x + 1):
				var cell := Vector2i(x, y)
				if astar.is_in_boundsv(cell) and expanded.has_point(cell_to_world(cell)):
					static_solid_cells[cell] = true
					astar.set_point_solid(cell, true)

func world_to_cell(world_position: Vector2) -> Vector2i:
	var max_cell := astar.region.end - Vector2i.ONE
	return Vector2i(
		clampi(floori(world_position.x / cell_size), 0, max_cell.x),
		clampi(floori(world_position.y / cell_size), 0, max_cell.y)
	)

func cell_to_world(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size + Vector2.ONE * cell_size * 0.5

func is_position_walkable(world_position: Vector2) -> bool:
	if world_position.x < 8.0 or world_position.y < 8.0:
		return false
	if world_position.x > map_size.x - 8.0 or world_position.y > map_size.y - 8.0:
		return false
	var cell := world_to_cell(world_position)
	return astar.is_in_boundsv(cell) and not astar.is_point_solid(cell)

func find_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var start := nearest_walkable_cell(world_to_cell(from))
	var finish := nearest_walkable_cell(world_to_cell(to))
	if start.x < 0 or finish.x < 0:
		return PackedVector2Array()
	var path := astar.get_point_path(start, finish)
	if not path.is_empty():
		path[path.size() - 1] = cell_to_world(finish)
	return path

func nearest_walkable_cell(origin: Vector2i, max_radius: int = 8) -> Vector2i:
	if astar.is_in_boundsv(origin) and not astar.is_point_solid(origin):
		return origin
	for radius in range(1, max_radius + 1):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				if abs(x - origin.x) != radius and abs(y - origin.y) != radius:
					continue
				var candidate := Vector2i(x, y)
				if astar.is_in_boundsv(candidate) and not astar.is_point_solid(candidate):
					return candidate
	return Vector2i(-1, -1)

func random_walkable_position() -> Vector2:
	for attempt in range(80):
		var candidate := Vector2(
			randf_range(30.0, map_size.x - 30.0),
			randf_range(30.0, map_size.y - 30.0)
		)
		if is_position_walkable(candidate):
			return cell_to_world(world_to_cell(candidate))
	return Vector2(80, 80)

func clamp_to_map(world_position: Vector2) -> Vector2:
	return world_position.clamp(Vector2(16, 16), map_size - Vector2(16, 16))

func can_place_dynamic_obstacle(world_rect: Rect2) -> bool:
	if world_rect.position.x < 12.0 or world_rect.position.y < 12.0:
		return false
	if world_rect.end.x > map_size.x - 12.0 or world_rect.end.y > map_size.y - 12.0:
		return false
	var cells := _cells_for_rect(world_rect.grow(3.0))
	if cells.is_empty():
		return false
	for cell in cells:
		if static_solid_cells.has(cell) or dynamic_cell_counts.get(cell, 0) > 0:
			return false
	return true

func add_dynamic_obstacle(obstacle_id: int, world_rect: Rect2) -> bool:
	if dynamic_obstacles.has(obstacle_id) or not can_place_dynamic_obstacle(world_rect):
		return false
	var cells := _cells_for_rect(world_rect.grow(3.0))
	dynamic_obstacles[obstacle_id] = cells
	for cell in cells:
		dynamic_cell_counts[cell] = dynamic_cell_counts.get(cell, 0) + 1
		astar.set_point_solid(cell, true)
	return true

func remove_dynamic_obstacle(obstacle_id: int) -> void:
	if not dynamic_obstacles.has(obstacle_id):
		return
	for cell in dynamic_obstacles[obstacle_id]:
		var count: int = dynamic_cell_counts.get(cell, 0) - 1
		if count <= 0:
			dynamic_cell_counts.erase(cell)
			astar.set_point_solid(cell, static_solid_cells.has(cell))
		else:
			dynamic_cell_counts[cell] = count
	dynamic_obstacles.erase(obstacle_id)

func _cells_for_rect(world_rect: Rect2) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var start := world_to_cell(world_rect.position)
	var finish := world_to_cell(world_rect.end)
	for y in range(start.y, finish.y + 1):
		for x in range(start.x, finish.x + 1):
			var cell := Vector2i(x, y)
			if astar.is_in_boundsv(cell) and world_rect.has_point(cell_to_world(cell)):
				result.append(cell)
	return result
