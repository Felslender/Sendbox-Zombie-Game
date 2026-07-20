class_name PlacementController
extends Node2D

var navigation_service: NavigationService
var entity_manager
var infection_system: InfectionSystem
var evacuation_system: EvacuationSystem
var events: SimulationEvents
var selected_tool := ""
var gas_cooldown := 0.0
var police_cooldown := 0.0
var evacuation_cooldown := 0.0
var barricade_cooldown := 0.0
var barricade_vertical := false
var preview_position := Vector2.ZERO
var preview_valid := false

func setup(navigation: NavigationService, manager, infection: InfectionSystem, evacuation: EvacuationSystem, event_bus: SimulationEvents) -> void:
	navigation_service = navigation
	entity_manager = manager
	infection_system = infection
	evacuation_system = evacuation
	events = event_bus
	z_index = 50

func _process(delta: float) -> void:
	gas_cooldown = maxf(0.0, gas_cooldown - delta)
	police_cooldown = maxf(0.0, police_cooldown - delta)
	evacuation_cooldown = maxf(0.0, evacuation_cooldown - delta)
	barricade_cooldown = maxf(0.0, barricade_cooldown - delta)
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
	elif event is InputEventKey and event.pressed and event.physical_keycode == KEY_Q and selected_tool == "barricade":
		barricade_vertical = not barricade_vertical
		events.feedback_requested.emit("Barricada girada: %s" % ("vertical" if barricade_vertical else "horizontal"), false)
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
		"evacuation":
			if evacuation_cooldown > 0.0:
				events.feedback_requested.emit("Evacuação indisponível: %.1fs" % evacuation_cooldown, true)
				return
			if evacuation_system.deploy_zone(at_position) == null:
				events.feedback_requested.emit("Limite de zonas atingido ou área muito próxima", true)
				return
			evacuation_cooldown = GameConfig.EVACUATION_COOLDOWN
			events.feedback_requested.emit("Zona de evacuação ativada", false)
		"barricade":
			if barricade_cooldown > 0.0:
				events.feedback_requested.emit("Construção indisponível: %.1fs" % barricade_cooldown, true)
				return
			if entity_manager.spawn_barricade(at_position, barricade_vertical) == null:
				events.feedback_requested.emit("Não há espaço para a barricada", true)
				return
			barricade_cooldown = GameConfig.BARRICADE_COOLDOWN
			events.feedback_requested.emit("Barricada construída — Q para girar a próxima", false)

func _can_place_at(at_position: Vector2) -> bool:
	if selected_tool == "":
		return false
	if at_position.x < 0.0 or at_position.y < 0.0 or at_position.x > GameConfig.MAP_SIZE.x or at_position.y > GameConfig.MAP_SIZE.y:
		return false
	if selected_tool in ["police", "evacuation"]:
		if navigation_service == null or not navigation_service.is_position_walkable(at_position):
			return false
	if selected_tool == "evacuation":
		return evacuation_system != null and evacuation_system.can_deploy(at_position)
	if selected_tool == "police":
		return navigation_service != null and navigation_service.is_position_walkable(at_position)
	if selected_tool == "barricade":
		return entity_manager != null and entity_manager.can_place_barricade(at_position, barricade_vertical)
	return true

func cooldown_ratio(tool_name: String) -> float:
	match tool_name:
		"gas":
			return gas_cooldown / GameConfig.GAS_COOLDOWN
		"police":
			return police_cooldown / GameConfig.POLICE_COOLDOWN
		"evacuation":
			return evacuation_cooldown / GameConfig.EVACUATION_COOLDOWN
		"barricade":
			return barricade_cooldown / GameConfig.BARRICADE_COOLDOWN
	return 0.0

func cooldown_remaining(tool_name: String) -> float:
	match tool_name:
		"gas":
			return gas_cooldown
		"police":
			return police_cooldown
		"evacuation":
			return evacuation_cooldown
		"barricade":
			return barricade_cooldown
	return 0.0

func _display_name(tool_name: String) -> String:
	match tool_name:
		"gas":
			return "Gás infeccioso"
		"police":
			return "Policial"
		"evacuation":
			return "Zona de evacuação"
		"barricade":
			return "Barricada"
	return tool_name

func _draw() -> void:
	if selected_tool == "":
		return
	var valid_color := Color(0.55, 1.0, 0.42, 0.23)
	var invalid_color := Color(1.0, 0.25, 0.25, 0.24)
	var color := valid_color if preview_valid else invalid_color
	if selected_tool == "gas":
		draw_circle(preview_position, GameConfig.GAS_RADIUS, color)
		draw_arc(preview_position, GameConfig.GAS_RADIUS, 0.0, TAU, 48, color.lightened(0.35), 3.0)
	elif selected_tool == "police":
		draw_circle(preview_position, 15.0, color)
		draw_arc(preview_position, 15.0, 0.0, TAU, 24, color.lightened(0.35), 3.0)
		draw_line(preview_position - Vector2(10, 0), preview_position + Vector2(10, 0), color.lightened(0.5), 2.0)
		draw_line(preview_position - Vector2(0, 10), preview_position + Vector2(0, 10), color.lightened(0.5), 2.0)
	elif selected_tool == "evacuation":
		draw_circle(preview_position, GameConfig.EVACUATION_RADIUS, color)
		draw_arc(preview_position, GameConfig.EVACUATION_RADIUS, 0.0, TAU, 48, color.lightened(0.35), 3.0)
		draw_circle(preview_position, 22.0, Color(color, 0.45))
		draw_line(preview_position - Vector2(11, 0), preview_position + Vector2(11, 0), color.lightened(0.5), 3.0)
	else:
		var size := GameConfig.BARRICADE_SIZE
		if barricade_vertical:
			size = Vector2(size.y, size.x)
		draw_rect(Rect2(preview_position - size * 0.5, size), color)
		draw_rect(Rect2(preview_position - size * 0.5, size), color.lightened(0.35), false, 3.0)
