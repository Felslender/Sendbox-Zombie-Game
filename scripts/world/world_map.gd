extends Node2D

func _ready() -> void:
	z_index = -20
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, GameConfig.MAP_SIZE), GameConfig.COLORS.grass)

	# Avenues form walkable blocks around the buildings.
	var roads: Array[Rect2] = [
		Rect2(0, 0, 1600, 72),
		Rect2(0, 330, 1600, 66),
		Rect2(0, 680, 1600, 58),
		Rect2(0, 920, 1600, 40),
		Rect2(0, 0, 72, 960),
		Rect2(435, 0, 72, 960),
		Rect2(820, 0, 90, 960),
		Rect2(1215, 0, 66, 960),
		Rect2(1525, 0, 75, 960),
	]
	for road in roads:
		draw_rect(road, GameConfig.COLORS.road)
		_draw_lane_markings(road)

	for obstacle in GameConfig.obstacle_rects():
		var sidewalk := obstacle.grow(14.0)
		draw_rect(sidewalk, GameConfig.COLORS.sidewalk)
		draw_rect(obstacle, GameConfig.COLORS.building)
		draw_rect(obstacle.grow(-8.0), GameConfig.COLORS.building_roof)
		_draw_building_details(obstacle)

	# Park and plaza details are decorative and remain walkable.
	draw_circle(Vector2(1375, 805), 38.0, Color("#426b4d"))
	draw_circle(Vector2(1450, 840), 26.0, Color("#426b4d"))
	draw_circle(Vector2(870, 820), 32.0, Color("#426b4d"))
	for pos in [Vector2(860, 480), Vector2(870, 560), Vector2(875, 620)]:
		draw_circle(pos, 13.0, Color("#264631"))
		draw_circle(pos, 8.0, Color("#4f7d55"))

	draw_rect(Rect2(Vector2.ZERO, GameConfig.MAP_SIZE), Color("#93a2a5"), false, 5.0)

func _draw_lane_markings(road: Rect2) -> void:
	var marking := Color(0.85, 0.78, 0.45, 0.55)
	if road.size.x > road.size.y:
		var y := road.position.y + road.size.y * 0.5
		var x := road.position.x + 18.0
		while x < road.end.x:
			draw_line(Vector2(x, y), Vector2(minf(x + 24.0, road.end.x), y), marking, 2.0)
			x += 45.0
	else:
		var x := road.position.x + road.size.x * 0.5
		var y := road.position.y + 18.0
		while y < road.end.y:
			draw_line(Vector2(x, y), Vector2(x, minf(y + 24.0, road.end.y)), marking, 2.0)
			y += 45.0

func _draw_building_details(rect: Rect2) -> void:
	var window_color := Color("#7ca2aa")
	var x := rect.position.x + 22.0
	while x < rect.end.x - 18.0:
		draw_rect(Rect2(x, rect.position.y + 15.0, 12.0, 7.0), window_color)
		x += 42.0
	var door_size := Vector2(22, 12)
	draw_rect(Rect2(rect.position + Vector2(rect.size.x * 0.5 - 11.0, rect.size.y - 12.0), door_size), Color("#182229"))
