extends Node2D

const HUD_SCRIPT := preload("res://scripts/ui/hud.gd")

@onready var events: SimulationEvents = $Events
@onready var navigation_service = $NavigationService
@onready var entity_manager = $EntityManager
@onready var infection_system = $InfectionSystem
@onready var evacuation_system = $EvacuationSystem
@onready var placement_controller = $PlacementController

var simulation_time := 0.0
var hud

func _ready() -> void:
	randomize()
	navigation_service.setup(GameConfig.MAP_SIZE, GameConfig.obstacle_rects())
	entity_manager.setup(navigation_service, events)
	infection_system.setup(entity_manager, events)
	evacuation_system.setup(entity_manager, events)
	entity_manager.set_evacuation_system(evacuation_system)
	placement_controller.setup(navigation_service, entity_manager, infection_system, evacuation_system, events)
	hud = HUD_SCRIPT.new()
	add_child(hud)
	hud.setup(events, placement_controller)
	events.simulation_reset_requested.connect(_reset_simulation)
	entity_manager.spawn_initial_population(GameConfig.CIVILIAN_COUNT)
	entity_manager.publish_metrics(simulation_time)

func _process(delta: float) -> void:
	if not get_tree().paused:
		simulation_time += delta
	entity_manager.publish_metrics(simulation_time)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event.is_pressed() or event.is_echo():
		return
	match event.physical_keycode:
		KEY_SPACE:
			hud.toggle_pause()
		KEY_1:
			hud.set_simulation_speed(1.0)
		KEY_2:
			hud.set_simulation_speed(2.0)
		KEY_4:
			hud.set_simulation_speed(4.0)
		KEY_R:
			_reset_simulation()

func _reset_simulation() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
