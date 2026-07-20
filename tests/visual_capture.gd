extends SceneTree

func _init() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	await process_frame
	var manager: EntityManager = game.get_node("EntityManager")
	var evacuation: EvacuationSystem = game.get_node("EvacuationSystem")
	evacuation.deploy_zone(Vector2(860, 350))
	manager.spawn_barricade(Vector2(705, 350), false)
	manager.spawn_barricade(Vector2(860, 520), true)
	for index in range(mini(4, manager.civilians.size())):
		manager.civilians[index].panic_level = 0.88 - float(index) * 0.1
	for frame in range(20):
		await process_frame
	var image := root.get_viewport().get_texture().get_image()
	var output := ProjectSettings.globalize_path("user://zona-zero-smoke.png")
	var error := image.save_png(output)
	if error == OK:
		print("CAPTURE=", output)
		quit(0)
	else:
		push_error("Falha ao salvar captura: %s" % error_string(error))
		quit(1)
