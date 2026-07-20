class_name PoliceAgent
extends AgentBase

enum State { PATROL, APPROACH, ENGAGE }

var state := State.PATROL
var target
var home_position := Vector2.ZERO
var decision_timer := 0.0
var attack_timer := 0.0
var patrol_timer := 0.0
var tracer_timer := 0.0
var tracer_end := Vector2.ZERO

func setup(manager, navigation: NavigationService, start_position: Vector2) -> void:
	entity_kind = "police"
	movement_speed = GameConfig.POLICE_SPEED
	body_color = GameConfig.COLORS.police
	radius = 9.0
	home_position = start_position
	setup_base(manager, navigation, start_position)
	decision_timer = randf_range(0.0, 0.3)
	_choose_patrol_destination()

func _physics_process(delta: float) -> void:
	decision_timer -= delta
	attack_timer -= delta
	patrol_timer -= delta
	tracer_timer = maxf(0.0, tracer_timer - delta)
	if tracer_timer > 0.0:
		queue_redraw()

	if decision_timer <= 0.0:
		_decide()
		decision_timer = randf_range(0.25, 0.4)

	if _is_valid_target(target):
		var offset: Vector2 = target.global_position - global_position
		var distance := offset.length()
		if distance > GameConfig.POLICE_ATTACK_RANGE:
			state = State.APPROACH
			if route_refresh_timer <= 0.0 or destination.distance_to(target.global_position) > 55.0:
				set_destination(target.global_position, true)
			follow_path(delta)
		elif distance < GameConfig.POLICE_SAFE_RANGE * 0.62:
			state = State.APPROACH
			set_destination(global_position - offset.normalized() * 90.0, true)
			follow_path(delta)
		else:
			state = State.ENGAGE
			stop_moving()
			facing = offset.normalized()
			if attack_timer <= 0.0:
				_attack_target()
	else:
		target = null
		state = State.PATROL
		if current_path.is_empty() or patrol_timer <= 0.0:
			_choose_patrol_destination()
		if follow_path(delta, 0.7):
			_choose_patrol_destination()

func _decide() -> void:
	if not _is_valid_target(target):
		target = entity_manager.find_nearest(global_position, GameConfig.POLICE_SIGHT_RADIUS, "zombie", self)
	if target != null and (route_refresh_timer <= 0.0 or state == State.PATROL):
		set_destination(target.global_position, true)

func _attack_target() -> void:
	if not _is_valid_target(target):
		return
	attack_timer = GameConfig.POLICE_ATTACK_COOLDOWN
	tracer_timer = 0.12
	tracer_end = to_local(target.global_position)
	target.take_damage(GameConfig.POLICE_DAMAGE)
	queue_redraw()

func _choose_patrol_destination() -> void:
	patrol_timer = randf_range(2.0, 4.5)
	for attempt in range(10):
		var candidate := home_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(45.0, 125.0)
		candidate = navigation_service.clamp_to_map(candidate)
		if navigation_service.is_position_walkable(candidate):
			set_destination(candidate, true)
			return

func _is_valid_target(candidate) -> bool:
	return candidate != null and is_instance_valid(candidate) and not candidate.is_queued_for_deletion() and candidate.health > 0.0

func _draw() -> void:
	super._draw()
	draw_rect(Rect2(-7, -4, 14, 5), Color("#173463"))
	draw_circle(Vector2.ZERO, 3.0, Color("#dbe7ff"))
	if tracer_timer > 0.0:
		draw_line(facing * 8.0, tracer_end, Color(1.0, 0.85, 0.35, tracer_timer * 8.0), 2.0)
