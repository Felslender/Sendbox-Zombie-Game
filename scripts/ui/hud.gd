class_name HUD
extends CanvasLayer

var events: SimulationEvents
var placement_controller: PlacementController
var stats_label: Label
var feedback_label: Label
var gas_button: Button
var police_button: Button
var evacuation_button: Button
var barricade_button: Button
var gas_cooldown_label: Label
var police_cooldown_label: Label
var evacuation_cooldown_label: Label
var barricade_cooldown_label: Label
var panic_label: Label
var pause_button: Button
var speed_buttons: Dictionary = {}
var feedback_timer := 0.0
var selected_tool := ""
var barricade_count := 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func setup(event_bus: SimulationEvents, controller: PlacementController) -> void:
	events = event_bus
	placement_controller = controller
	_build_interface()
	events.metrics_changed.connect(_on_metrics_changed)
	events.feedback_requested.connect(_show_feedback)
	events.tool_changed.connect(_on_tool_changed)
	set_simulation_speed(1.0)

func _process(delta: float) -> void:
	if placement_controller == null:
		return
	var gas_remaining := placement_controller.cooldown_remaining("gas")
	var police_remaining := placement_controller.cooldown_remaining("police")
	var evacuation_remaining := placement_controller.cooldown_remaining("evacuation")
	var barricade_remaining := placement_controller.cooldown_remaining("barricade")
	gas_cooldown_label.text = "PRONTO" if gas_remaining <= 0.0 else "RECARGA  %.1fs" % gas_remaining
	police_cooldown_label.text = "PRONTO" if police_remaining <= 0.0 else "REFORÇO  %.1fs" % police_remaining
	evacuation_cooldown_label.text = "PRONTO" if evacuation_remaining <= 0.0 else "CONTATO  %.1fs" % evacuation_remaining
	barricade_cooldown_label.text = "PRONTO · %d/%d" % [barricade_count, GameConfig.BARRICADE_MAX_COUNT] if barricade_remaining <= 0.0 else "CONSTRUINDO  %.1fs" % barricade_remaining
	if feedback_timer > 0.0:
		feedback_timer -= delta
		if feedback_timer <= 0.0:
			var tween := create_tween()
			tween.tween_property(feedback_label, "modulate:a", 0.0, 0.25)

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	pause_button.text = "▶  CONTINUAR" if get_tree().paused else "Ⅱ  PAUSAR"
	_show_feedback("Simulação pausada" if get_tree().paused else "Simulação retomada", false)

func set_simulation_speed(speed: float) -> void:
	get_tree().paused = false
	Engine.time_scale = speed
	if pause_button != null:
		pause_button.text = "Ⅱ  PAUSAR"
	for value in speed_buttons:
		speed_buttons[value].modulate = Color.WHITE if is_equal_approx(value, speed) else Color(0.62, 0.68, 0.72)
	_show_feedback("Velocidade %.0fx" % speed, false)

func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var top_panel := _make_panel(Color("#111a20e8"))
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 12
	top_panel.offset_top = 10
	top_panel.offset_right = -12
	top_panel.offset_bottom = 72
	root.add_child(top_panel)
	var top_row := HBoxContainer.new()
	top_row.add_theme_constant_override("separation", 12)
	top_panel.add_child(top_row)
	var logo := _make_label("ZONA ZERO", 20, Color("#d7ff64"))
	logo.custom_minimum_size.x = 145
	top_row.add_child(logo)
	stats_label = _make_label("CIVIS  --   INFECTADOS  --   ZUMBIS  --", 15, Color("#e8f0f2"))
	stats_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	top_row.add_child(stats_label)
	pause_button = _make_button("Ⅱ  PAUSAR")
	pause_button.pressed.connect(toggle_pause)
	top_row.add_child(pause_button)
	for speed in [1.0, 2.0, 4.0]:
		var button := _make_button("%.0fx" % speed)
		button.custom_minimum_size.x = 48
		button.pressed.connect(set_simulation_speed.bind(speed))
		speed_buttons[speed] = button
		top_row.add_child(button)
	var restart := _make_button("↻  REINICIAR")
	restart.pressed.connect(func(): events.simulation_reset_requested.emit())
	top_row.add_child(restart)

	var left_panel := _make_panel(Color("#15221fe8"))
	left_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_panel.offset_left = 12
	left_panel.offset_top = 84
	left_panel.offset_right = 232
	left_panel.offset_bottom = -22
	root.add_child(left_panel)
	var infection_column := VBoxContainer.new()
	infection_column.add_theme_constant_override("separation", 10)
	left_panel.add_child(infection_column)
	infection_column.add_child(_make_label("☣  INFECÇÃO", 20, Color("#b9f45b")))
	infection_column.add_child(_separator(Color("#5f7f3e")))
	infection_column.add_child(_make_label("ESPALHAR O CAOS", 11, Color("#7e9185")))
	gas_button = _make_button("☁  GÁS INFECCIOSO")
	gas_button.custom_minimum_size.y = 54
	gas_button.pressed.connect(func(): placement_controller.select_tool("gas"))
	infection_column.add_child(gas_button)
	gas_cooldown_label = _make_label("PRONTO", 12, Color("#b9f45b"))
	infection_column.add_child(gas_cooldown_label)
	infection_column.add_child(_make_label("Raio: 92 m\nDuração: 5,5 s\nInfecção: 82%\nIncubação: ~7 s", 13, Color("#aab8ad")))
	panic_label = _make_label("PÂNICO DA CIDADE  0%", 12, GameConfig.COLORS.panic)
	infection_column.add_child(panic_label)
	var spacer_left := Control.new()
	spacer_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	infection_column.add_child(spacer_left)
	infection_column.add_child(_make_label("Clique no mapa para liberar\na nuvem sobre os civis.", 12, Color("#788a80")))

	var right_panel := _make_panel(Color("#151d2be8"))
	right_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right_panel.offset_left = -232
	right_panel.offset_top = 84
	right_panel.offset_right = -12
	right_panel.offset_bottom = -22
	root.add_child(right_panel)
	var defense_column := VBoxContainer.new()
	defense_column.add_theme_constant_override("separation", 10)
	right_panel.add_child(defense_column)
	defense_column.add_child(_make_label("◆  DEFESA", 20, Color("#7fb0ff")))
	defense_column.add_child(_separator(Color("#3f5e87")))
	defense_column.add_child(_make_label("CONTER O SURTO", 11, Color("#7c8799")))
	police_button = _make_button("★  POLICIAL")
	police_button.custom_minimum_size.y = 54
	police_button.pressed.connect(func(): placement_controller.select_tool("police"))
	defense_column.add_child(police_button)
	police_cooldown_label = _make_label("PRONTO", 12, Color("#7fb0ff"))
	defense_column.add_child(police_cooldown_label)
	defense_column.add_child(_make_label("Alcance: 185 m\nDano: 34\nCadência: 0,7 s\nPatrulha automática", 13, Color("#a8b2c2")))
	evacuation_button = _make_button("H  ZONA DE EVACUAÇÃO")
	evacuation_button.custom_minimum_size.y = 48
	evacuation_button.pressed.connect(func(): placement_controller.select_tool("evacuation"))
	defense_column.add_child(evacuation_button)
	evacuation_cooldown_label = _make_label("PRONTO", 12, Color("#62e6b0"))
	defense_column.add_child(evacuation_cooldown_label)
	defense_column.add_child(_make_label("Capacidade: 10 civis\nDuração: 55 s · Máx.: 2", 12, Color("#9bcaba")))
	barricade_button = _make_button("▰  BARRICADA")
	barricade_button.custom_minimum_size.y = 44
	barricade_button.pressed.connect(func(): placement_controller.select_tool("barricade"))
	defense_column.add_child(barricade_button)
	barricade_cooldown_label = _make_label("PRONTO", 12, GameConfig.COLORS.barricade)
	defense_column.add_child(barricade_cooldown_label)
	defense_column.add_child(_make_label("Limite: 8 · Q para girar", 12, Color("#cbb08b")))
	var spacer_right := Control.new()
	spacer_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defense_column.add_child(spacer_right)
	defense_column.add_child(_make_label("Posicione em ruas ou áreas\nabertas. Edifícios são inválidos.", 12, Color("#788393")))

	feedback_label = _make_label("", 15, Color.WHITE)
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	feedback_label.position = Vector2(-230, -70)
	feedback_label.size = Vector2(460, 38)
	feedback_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(feedback_label)

	var help := _make_label("WASD / SETAS  Mover     RODA  Zoom     MEIO + ARRASTAR  Câmera     ESC  Cancelar", 11, Color("#9dafb6"))
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	help.position = Vector2(-330, -28)
	help.size = Vector2(660, 22)
	help.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(help)

func _on_metrics_changed(metrics: Dictionary) -> void:
	var total_seconds: int = floori(metrics.time)
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	stats_label.text = "CIVIS  %02d    INFECTADOS  %02d    ZUMBIS  %02d    RESGATADOS  %02d    DEFESA  %02d    %02d:%02d    %d FPS" % [
		metrics.healthy, metrics.infected, metrics.zombies, metrics.rescued,
		metrics.defense, minutes, seconds, metrics.fps
	]
	panic_label.text = "PÂNICO DA CIDADE  %d%%" % roundi(metrics.panic * 100.0)
	panic_label.add_theme_color_override("font_color", GameConfig.COLORS.panic.lerp(Color("#ff5f56"), metrics.panic))
	barricade_count = metrics.barricades

func _on_tool_changed(tool_name: String) -> void:
	selected_tool = tool_name
	gas_button.modulate = Color("#c9ff70") if tool_name == "gas" else Color.WHITE
	police_button.modulate = Color("#8ab9ff") if tool_name == "police" else Color.WHITE
	evacuation_button.modulate = Color("#75efbd") if tool_name == "evacuation" else Color.WHITE
	barricade_button.modulate = Color("#efb76f") if tool_name == "barricade" else Color.WHITE

func _show_feedback(message: String, is_error: bool) -> void:
	if feedback_label == null:
		return
	feedback_label.text = message
	feedback_label.modulate = Color("#ff7b72") if is_error else Color("#e7f2f0")
	feedback_timer = 2.2

func _make_panel(color: Color) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_constant_override("margin_left", 14)
	panel.add_theme_constant_override("margin_top", 12)
	panel.add_theme_constant_override("margin_right", 14)
	panel.add_theme_constant_override("margin_bottom", 12)
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color(0.32, 0.43, 0.47, 0.65)
	style.set_border_width_all(1)
	style.set_corner_radius_all(7)
	panel.add_theme_stylebox_override("panel", style)
	return panel

func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(90, 38)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#25323b")
	normal.border_color = Color("#465862")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate()
	hover.bg_color = Color("#344650")
	button.add_theme_stylebox_override("hover", hover)
	var pressed := normal.duplicate()
	pressed.bg_color = Color("#182128")
	button.add_theme_stylebox_override("pressed", pressed)
	return button

func _separator(color: Color) -> HSeparator:
	var separator := HSeparator.new()
	var line := StyleBoxFlat.new()
	line.bg_color = color
	line.content_margin_top = 1
	line.content_margin_bottom = 1
	separator.add_theme_stylebox_override("separator", line)
	return separator
