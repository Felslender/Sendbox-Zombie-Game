class_name CivilianAgent
extends AgentBase

enum State {
	WANDER,
	IDLE,
	INVESTIGATE,
	FLEE,
	EVACUATING,
	RESCUING,
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
var assigned_evacuation_zone
var rescue_remaining := 0.0
var panic_level := 0.0
var group_leader
var group_offset := Vector2.ZERO

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
	panic_level = maxf(0.0, panic_level - GameConfig.PANIC_DECAY_PER_SECOND * delta)
	if panic_level > 0.03:
		queue_redraw()
	if state == State.RESCUING:
		if not _is_valid_evacuation_zone(assigned_evacuation_zone):
			assigned_evacuation_zone = null
			state = State.WANDER
			_choose_wander_destination()
			return
		rescue_remaining -= delta
		queue_redraw()
		if rescue_remaining <= 0.0:
			entity_manager.rescue_civilian(self, assigned_evacuation_zone)
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
			if follow_path(delta, GameConfig.CIVILIAN_FLEE_SPEED / movement_speed * (1.0 + panic_level * 0.18)):
				if panic_level > 0.55:
					_choose_panic_destination()
				else:
					_choose_flee_destination()
		State.INVESTIGATE:
			if follow_path(delta, 0.72) or state_timer <= 0.0:
				state = State.INFECTED if is_infected else State.WANDER
				_choose_wander_destination()
		State.EVACUATING:
			if not _is_valid_evacuation_zone(assigned_evacuation_zone):
				assigned_evacuation_zone = null
				state = State.WANDER
				_choose_wander_destination()
			elif global_position.distance_to(assigned_evacuation_zone.global_position) <= 24.0 or follow_path(delta, 1.08):
				_begin_rescue()
		_:
			if follow_path(delta, 1.0 + panic_level * 0.12):
				_begin_idle()

func infect(incubation: float = GameConfig.GAS_INCUBATION) -> bool:
	if is_infected or state in [State.TRANSFORMING, State.REMOVED, State.RESCUED]:
		return false
	if state == State.RESCUING and _is_valid_evacuation_zone(assigned_evacuation_zone):
		assigned_evacuation_zone.cancel_reservation()
	assigned_evacuation_zone = null
	is_infected = true
	panic_level = maxf(panic_level, 0.65)
	incubation_total = incubation * randf_range(0.86, 1.15)
	incubation_remaining = incubation_total
	state = State.INFECTED
	body_color = GameConfig.COLORS.infected
	queue_redraw()
	return true

func _decide() -> void:
	_update_social_state()
	var danger_radius := GameConfig.CIVILIAN_DANGER_RADIUS * personality_caution
	var danger = entity_manager.find_nearest(global_position, danger_radius, "zombie", self)
	if danger != null:
		panic_level = maxf(panic_level, 0.92)
		_cancel_evacuation()
		state = State.FLEE
		_choose_flee_destination(danger.global_position)
		return
	var suspicious = entity_manager.find_nearest(global_position, danger_radius * 1.35, "zombie", self)
	if suspicious != null and state not in [State.FLEE, State.INVESTIGATE]:
		panic_level = maxf(panic_level, 0.42)
		state = State.INVESTIGATE
		state_timer = randf_range(0.7, 1.3)
		var sideways: Vector2 = (global_position - suspicious.global_position).normalized().rotated(randf_range(-0.7, 0.7))
		set_destination(global_position + sideways * 65.0, true)
		return

	if panic_level > 0.58 and not is_infected:
		_cancel_evacuation()
		state = State.FLEE
		if route_refresh_timer <= 0.0 or current_path.is_empty():
			_choose_panic_destination()
		return

	if not is_infected:
		var evacuation_zone = entity_manager.find_nearest_evacuation(global_position)
		if evacuation_zone != null:
			if assigned_evacuation_zone != evacuation_zone or state != State.EVACUATING:
				assigned_evacuation_zone = evacuation_zone
				state = State.EVACUATING
				set_destination(evacuation_zone.global_position, true)
			elif route_refresh_timer <= 0.0:
				set_destination(evacuation_zone.global_position, true)
			return

	if not is_infected and _is_valid_group_leader(group_leader) and state in [State.WANDER, State.IDLE]:
		var desired_group_position: Vector2 = group_leader.global_position + group_offset
		if global_position.distance_to(desired_group_position) > 42.0:
			state = State.WANDER
			if route_refresh_timer <= 0.0 or destination.distance_to(desired_group_position) > 48.0:
				set_destination(desired_group_position, true)
			return

	if state == State.EVACUATING:
		assigned_evacuation_zone = null
		state = State.WANDER
		_choose_wander_destination()
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

func _choose_panic_destination() -> void:
	for attempt in range(10):
		var candidate := global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(120.0, 230.0)
		candidate = navigation_service.clamp_to_map(candidate)
		if navigation_service.is_position_walkable(candidate):
			set_destination(candidate, true)
			return
	_choose_wander_destination()

func _begin_idle() -> void:
	if panic_level > 0.45:
		state = State.WANDER
		_choose_panic_destination()
		return
	state = State.IDLE
	state_timer = randf_range(0.7, 2.5) * (1.0 - panic_level * 0.6)
	stop_moving()

func _update_social_state() -> void:
	group_leader = null
	var best_group_distance_squared := GameConfig.PANIC_GROUP_RADIUS * GameConfig.PANIC_GROUP_RADIUS
	for neighbor in entity_manager.get_nearby(global_position, GameConfig.PANIC_SPREAD_RADIUS, "civilian"):
		if neighbor == self or neighbor.state in [State.REMOVED, State.RESCUED, State.TRANSFORMING]:
			continue
		var distance := global_position.distance_to(neighbor.global_position)
		if not neighbor.is_infected and neighbor.panic_level > 0.2:
			var falloff: float = 1.0 - clampf(distance / GameConfig.PANIC_SPREAD_RADIUS, 0.0, 1.0)
			var spread: float = neighbor.panic_level * falloff * 0.72
			if neighbor.state == State.FLEE:
				spread += 0.14 * falloff
			panic_level = maxf(panic_level, clampf(spread, 0.0, 0.88))
		if is_infected or neighbor.is_infected:
			continue
		if neighbor.get_instance_id() >= get_instance_id():
			continue
		if neighbor.state not in [State.WANDER, State.IDLE] or state not in [State.WANDER, State.IDLE]:
			continue
		var distance_squared := global_position.distance_squared_to(neighbor.global_position)
		if distance_squared < best_group_distance_squared:
			best_group_distance_squared = distance_squared
			group_leader = neighbor
	if group_leader != null:
		var angle := float(get_instance_id() % 12) / 12.0 * TAU
		group_offset = Vector2.RIGHT.rotated(angle) * 28.0

func _is_valid_group_leader(candidate) -> bool:
	return candidate != null and is_instance_valid(candidate) and not candidate.is_queued_for_deletion() and not candidate.is_infected and candidate.state in [State.WANDER, State.IDLE]

func _begin_rescue() -> void:
	if not _is_valid_evacuation_zone(assigned_evacuation_zone):
		assigned_evacuation_zone = null
		state = State.WANDER
		_choose_wander_destination()
		return
	if not assigned_evacuation_zone.reserve_civilian():
		assigned_evacuation_zone = null
		state = State.WANDER
		_choose_wander_destination()
		return
	state = State.RESCUING
	rescue_remaining = GameConfig.EVACUATION_BOARDING_TIME
	stop_moving()
	queue_redraw()

func _cancel_evacuation() -> void:
	if state == State.RESCUING and _is_valid_evacuation_zone(assigned_evacuation_zone):
		assigned_evacuation_zone.cancel_reservation()
	assigned_evacuation_zone = null

func _is_valid_evacuation_zone(zone) -> bool:
	return zone != null and is_instance_valid(zone) and not zone.is_queued_for_deletion() and zone.active

func _draw() -> void:
	super._draw()
	if is_infected and incubation_total > 0.0:
		var progress := 1.0 - clampf(incubation_remaining / incubation_total, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius + 4.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 20, Color("#ffe45c"), 2.5)
	if state == State.FLEE:
		draw_line(Vector2(-3, -14), Vector2(0, -20), Color.WHITE, 2.0)
		draw_line(Vector2(3, -14), Vector2(0, -20), Color.WHITE, 2.0)
	elif state == State.EVACUATING:
		draw_arc(Vector2.ZERO, radius + 4.0, 0.0, TAU, 18, GameConfig.COLORS.evacuation, 2.0)
	elif state == State.RESCUING:
		var rescue_progress := 1.0 - clampf(rescue_remaining / GameConfig.EVACUATION_BOARDING_TIME, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius + 5.0, -PI * 0.5, -PI * 0.5 + TAU * rescue_progress, 20, GameConfig.COLORS.evacuation, 3.0)
	if panic_level > 0.12:
		draw_arc(Vector2.ZERO, radius + 7.0, -PI * 0.5, -PI * 0.5 + TAU * panic_level, 18, Color(GameConfig.COLORS.panic, 0.85), 2.0)
	if _is_valid_group_leader(group_leader):
		draw_circle(Vector2(-3, -15), 2.0, Color(0.65, 0.85, 1.0, 0.8))
		draw_circle(Vector2(3, -15), 2.0, Color(0.65, 0.85, 1.0, 0.8))
