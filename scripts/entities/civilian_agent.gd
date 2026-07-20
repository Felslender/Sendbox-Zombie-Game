class_name CivilianAgent
extends AgentBase

enum State {
	WANDER,
	IDLE,
	INVESTIGATE,
	FLEE,
	INFECTED,
	TRANSFORMING,
	RESCUED,
	REMOVED,
}

var state := State.WANDER
var decision_timer := 0.0
var state_timer := 0.0
var is_infected := false
var incubation_remaining := 0.0
var incubation_total := 0.0
var transforming_remaining := 0.0
var personality_caution := 1.0

func setup(manager, navigation: NavigationService, start_position: Vector2) -> void:
	entity_kind = "civilian"
	movement_speed = GameConfig.CIVILIAN_SPEED * randf_range(0.88, 1.13)
	body_color = GameConfig.COLORS.civilian
	personality_caution = randf_range(0.88, 1.18)
	setup_base(manager, navigation, start_position)
	decision_timer = randf_range(0.05, 0.55)
	_choose_wander_destination()

func _physics_process(delta: float) -> void:
	if state == State.REMOVED or state == State.RESCUED:
		return
	if state == State.TRANSFORMING:
		transforming_remaining -= delta
		rotation += delta * 7.0
		scale = Vector2.ONE * (1.0 + sin(transforming_remaining * 18.0) * 0.16)
		if transforming_remaining <= 0.0:
			entity_manager.transform_civilian(self)
		return

	if is_infected:
		incubation_remaining -= delta
		queue_redraw()
		if incubation_remaining <= 0.0:
			state = State.TRANSFORMING
			transforming_remaining = 0.8
			stop_moving()
			body_color = Color("#d5e34b")
			queue_redraw()
			return

	decision_timer -= delta
	state_timer -= delta
	if decision_timer <= 0.0:
		_decide()
		decision_timer = randf_range(0.28, 0.46)

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if state_timer <= 0.0:
				state = State.INFECTED if is_infected else State.WANDER
				_choose_wander_destination()
		State.FLEE:
			if follow_path(delta, GameConfig.CIVILIAN_FLEE_SPEED / movement_speed):
				_choose_flee_destination()
		State.INVESTIGATE:
			if follow_path(delta, 0.72) or state_timer <= 0.0:
				state = State.INFECTED if is_infected else State.WANDER
				_choose_wander_destination()
		_:
			if follow_path(delta):
				_begin_idle()

func infect(incubation: float = GameConfig.GAS_INCUBATION) -> bool:
	if is_infected or state in [State.TRANSFORMING, State.REMOVED, State.RESCUED]:
		return false
	is_infected = true
	incubation_total = incubation * randf_range(0.86, 1.15)
	incubation_remaining = incubation_total
	state = State.INFECTED
	body_color = GameConfig.COLORS.infected
	queue_redraw()
	return true

func _decide() -> void:
	var danger_radius := GameConfig.CIVILIAN_DANGER_RADIUS * personality_caution
	var danger = entity_manager.find_nearest(global_position, danger_radius, "zombie", self)
	if danger != null:
		state = State.FLEE
		_choose_flee_destination(danger.global_position)
		return
	var suspicious = entity_manager.find_nearest(global_position, danger_radius * 1.35, "zombie", self)
	if suspicious != null and state not in [State.FLEE, State.INVESTIGATE]:
		state = State.INVESTIGATE
		state_timer = randf_range(0.7, 1.3)
		var sideways: Vector2 = (global_position - suspicious.global_position).normalized().rotated(randf_range(-0.7, 0.7))
		set_destination(global_position + sideways * 65.0, true)
	elif state == State.FLEE:
		state = State.INFECTED if is_infected else State.WANDER
		_choose_wander_destination()
	elif route_refresh_timer <= 0.0 and state in [State.WANDER, State.INFECTED]:
		set_destination(destination, true)

func _choose_flee_destination(known_danger: Vector2 = Vector2.INF) -> void:
	var danger_position := known_danger
	if not danger_position.is_finite():
		var danger = entity_manager.find_nearest(global_position, GameConfig.CIVILIAN_DANGER_RADIUS * 1.4, "zombie", self)
		if danger == null:
			_choose_wander_destination()
			return
		danger_position = danger.global_position
	var away := (global_position - danger_position).normalized()
	if away.length_squared() < 0.1:
		away = Vector2.RIGHT.rotated(randf() * TAU)
	var candidate := global_position + away.rotated(randf_range(-0.45, 0.45)) * randf_range(150.0, 260.0)
	set_destination(candidate, true)

func _choose_wander_destination() -> void:
	for attempt in range(12):
		var candidate := global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(90.0, 280.0)
		candidate = navigation_service.clamp_to_map(candidate)
		if navigation_service.is_position_walkable(candidate):
			set_destination(candidate, true)
			return
	set_destination(navigation_service.random_walkable_position(), true)

func _begin_idle() -> void:
	state = State.IDLE
	state_timer = randf_range(0.7, 2.5)
	stop_moving()

func _draw() -> void:
	super._draw()
	if is_infected and incubation_total > 0.0:
		var progress := 1.0 - clampf(incubation_remaining / incubation_total, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius + 4.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 20, Color("#ffe45c"), 2.5)
	if state == State.FLEE:
		draw_line(Vector2(-3, -14), Vector2(0, -20), Color.WHITE, 2.0)
		draw_line(Vector2(3, -14), Vector2(0, -20), Color.WHITE, 2.0)
