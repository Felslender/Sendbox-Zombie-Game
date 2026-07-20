class_name PlacementController
extends Node2D

var navigation_service: NavigationService
var entity_manager
var infection_system: InfectionSystem
var events: SimulationEvents
var selected_tool := ""
var gas_cooldown := 0.0
var police_cooldown := 0.0
var preview_position := Vector2.ZERO
var preview_valid := false

func setup(navigation: NavigationService, manager, infection: InfectionSystem, event_bus: SimulationEvents) -> void:
	navigation_service = navigation
	entity_manager = manager
	infection_system = infection
	events = event_bus
	z_index = 50

func _process(delta: float) -> void:
	gas_cooldown = maxf(0.0, gas_cooldown - delta)
	police_cooldown = maxf(0.0, police_cooldown - delta)
	preview_position = get_global_mouse_position()
	preview_valid = _can_place_at(preview_position)
	queue_redraw()

func select_tool(tool_name: String) -> void:
	selected_tool = "" if selected_tool == tool_name else tool_name
	events.tool_changed.emit(selected_tool)
	if selected_tool != "":
		events.feedback_requested.emit("Ferramenta selecionada: %s" % _display_name(selected_tool), false)
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		selected_tool = ""
		events.tool_changed.emit(selected_tool)
		queue_redraw()
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if selected_tool == "":
			return
		_try_place(preview_position)
		get_viewport().set_input_as_handled()

func _try_place(at_position: Vector2) -> void:
	if not _can_place_at(at_position):
		events.feedback_requested.emit("Não é possível usar a ferramenta nesse local", true)
		return
	match selected_tool:
		"gas":
			if gas_cooldown > 0.0:
				events.feedback_requested.emit("Gás recarregando: %.1fs" % gas_cooldown, true)
				return
			infection_system.deploy_gas(at_position)
			gas_cooldown = GameConfig.GAS_COOLDOWN
			events.feedback_requested.emit("Nuvem infecciosa liberada", false)
		"police":
			if police_cooldown > 0.0:
				events.feedback_requested.emit("Reforço a caminho: %.1fs" % police_cooldown, true)
				return
			entity_manager.spawn_police(at_position)
			police_cooldown = GameConfig.POLICE_COOLDOWN
			events.feedback_requested.emit("Policial posicionado", false)

func _can_place_at(at_position: Vector2) -> bool:
	if selected_tool == "":
		return false
	if at_position.x < 0.0 or at_position.y < 0.0 or at_position.x > GameConfig.MAP_SIZE.x or at_position.y > GameConfig.MAP_SIZE.y:
		return false
	if selected_tool == "police":
		return navigation_service != null and navigation_service.is_position_walkable(at_position)
	return true

func cooldown_ratio(tool_name: String) -> float:
	match tool_name:
		"gas":
			return gas_cooldown / GameConfig.GAS_COOLDOWN
		"police":
			return police_cooldown / GameConfig.POLICE_COOLDOWN
	return 0.0

func cooldown_remaining(tool_name: String) -> float:
	return gas_cooldown if tool_name == "gas" else police_cooldown

func _display_name(tool_name: String) -> String:
	return "Gás infeccioso" if tool_name == "gas" else "Policial"

func _draw() -> void:
	if selected_tool == "":
		return
	var valid_color := Color(0.55, 1.0, 0.42, 0.23)
	var invalid_color := Color(1.0, 0.25, 0.25, 0.24)
	var color := valid_color if preview_valid else invalid_color
	if selected_tool == "gas":
		draw_circle(preview_position, GameConfig.GAS_RADIUS, color)
		draw_arc(preview_position, GameConfig.GAS_RADIUS, 0.0, TAU, 48, color.lightened(0.35), 3.0)
	else:
		draw_circle(preview_position, 15.0, color)
		draw_arc(preview_position, 15.0, 0.0, TAU, 24, color.lightened(0.35), 3.0)
		draw_line(preview_position - Vector2(10, 0), preview_position + Vector2(10, 0), color.lightened(0.5), 2.0)
		draw_line(preview_position - Vector2(0, 10), preview_position + Vector2(0, 10), color.lightened(0.5), 2.0)
