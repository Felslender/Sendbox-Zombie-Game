class_name ZombieAgent
extends AgentBase

enum State { WANDER, CHASE, ATTACK, BREAK_BARRICADE, NEUTRALIZED }

var state := State.WANDER
var health := GameConfig.ZOMBIE_HEALTH
var target
var decision_timer := 0.0
var wander_timer := 0.0
var attack_flash := 0.0
var attack_timer := 0.0

func setup(manager, navigation: NavigationService, start_position: Vector2) -> void:
	entity_kind = "zombie"
	movement_speed = GameConfig.ZOMBIE_SPEED * randf_range(0.9, 1.12)
	body_color = GameConfig.COLORS.zombie
	radius = 9.5
	setup_base(manager, navigation, start_position)
	decision_timer = randf_range(0.0, 0.4)
	_choose_wander_destination()

func _physics_process(delta: float) -> void:
	if state == State.NEUTRALIZED:
		return
	decision_timer -= delta
	wander_timer -= delta
	attack_flash = maxf(0.0, attack_flash - delta)
	attack_timer -= delta
	if decision_timer <= 0.0:
		_decide()
		decision_timer = randf_range(0.34, 0.52)

	if target != null and _is_valid_target(target):
		var distance := global_position.distance_to(target.global_position)
		if target.entity_kind == "barricade":
			state = State.BREAK_BARRICADE
			if distance <= GameConfig.BARRICADE_ZOMBIE_ATTACK_RANGE:
				stop_moving()
				if attack_timer <= 0.0:
					attack_timer = GameConfig.BARRICADE_ZOMBIE_ATTACK_COOLDOWN
					target.take_damage(GameConfig.BARRICADE_ZOMBIE_DAMAGE)
					attack_flash = 0.2
					queue_redraw()
			else:
				if route_refresh_timer <= 0.0 or current_path.is_empty():
					set_destination(target.global_position, true)
				follow_path(delta)
			return
		if distance <= GameConfig.ZOMBIE_ATTACK_RANGE:
			state = State.ATTACK
			stop_moving()
			if target.infect(GameConfig.GAS_INCUBATION * 0.72):
				attack_flash = 0.28
				queue_redraw()
			target = null
			return
		state = State.CHASE
		if route_refresh_timer <= 0.0 or destination.distance_to(target.global_position) > 48.0:
			set_destination(target.global_position, true)
		follow_path(delta)
	else:
		target = null
		state = State.WANDER
		if current_path.is_empty() or wander_timer <= 0.0:
			_choose_wander_destination()
		if follow_path(delta, 0.72):
			_choose_wander_destination()

func take_damage(amount: float) -> void:
	if state == State.NEUTRALIZED:
		return
	health -= amount
	queue_redraw()
	if health <= 0.0:
		state = State.NEUTRALIZED
		stop_moving()
		var tween := create_tween()
		tween.tween_property(self, "modulate", Color(0.45, 0.5, 0.45, 0.0), 0.35)
		tween.tween_callback(entity_manager.remove_zombie.bind(self))

func _decide() -> void:
	if not _is_valid_target(target):
		var civilian = entity_manager.find_nearest_healthy(global_position, GameConfig.ZOMBIE_SIGHT_RADIUS)
		var barricade = entity_manager.find_nearest(global_position, 95.0, "barricade", self)
		if barricade != null and (civilian == null or global_position.distance_to(barricade.global_position) <= 70.0 or current_path.is_empty()):
			target = barricade
		else:
			target = civilian
	if target != null:
		state = State.BREAK_BARRICADE if target.entity_kind == "barricade" else State.CHASE
		set_destination(target.global_position, true)
	elif route_refresh_timer <= 0.0:
		_choose_wander_destination()

func _is_valid_target(candidate) -> bool:
	if candidate == null or not is_instance_valid(candidate) or candidate.is_queued_for_deletion():
		return false
	if candidate.entity_kind == "barricade":
		return candidate.health > 0.0
	return not candidate.is_infected

func _choose_wander_destination() -> void:
	wander_timer = randf_range(2.2, 5.0)
	for attempt in range(10):
		var candidate := global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(80.0, 210.0)
		candidate = navigation_service.clamp_to_map(candidate)
		if navigation_service.is_position_walkable(candidate):
			set_destination(candidate, true)
			return
	set_destination(navigation_service.random_walkable_position(), true)

func _draw() -> void:
	super._draw()
	draw_circle(Vector2(-4, -2), 1.6, Color("#172713"))
	draw_circle(Vector2(4, -2), 1.6, Color("#172713"))
	var ratio := clampf(health / GameConfig.ZOMBIE_HEALTH, 0.0, 1.0)
	if ratio < 1.0:
		draw_rect(Rect2(-11, -17, 22, 3), Color(0.12, 0.13, 0.14, 0.85))
		draw_rect(Rect2(-11, -17, 22 * ratio, 3), Color("#ef5b5b"))
	if attack_flash > 0.0:
		draw_arc(Vector2.ZERO, 15.0 + attack_flash * 12.0, 0.0, TAU, 24, Color(0.8, 1.0, 0.45, attack_flash * 3.0), 3.0)
