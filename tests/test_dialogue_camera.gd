extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	for id in ["eddington", "cottingham"]:
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game._start_game()
		var before: Transform3D = game.player.camera.transform
		var fov: float = game.player.camera.fov
		game._interact(id)
		var camera: Camera3D = game.dialogue_camera
		var eye: Vector3 = camera.eye_point
		check(camera.current, id + " dialogue camera is current")
		check(camera.global_position.distance_to(eye) >= 1.6 and camera.global_position.distance_to(eye) <= 2.5, id + " distance")
		var top := camera.unproject_position(eye + Vector3.UP * 0.12)
		var bottom := camera.unproject_position(eye - Vector3.UP * 0.12)
		var center := camera.unproject_position(eye)
		check(bottom.y - top.y >= 120.0, id + " face height")
		check(center.y >= 144.0 and center.y <= 288.0, id + " eye position")
		while game.ui.dialog_active():
			if game.ui._choice_buttons.is_empty():
				game.ui._advance()
			else:
				game.ui._choose(0)
		check(game.player.camera.current, id + " player camera restored")
		check(game.player.camera.transform == before and game.player.camera.fov == fov, id + " player camera unchanged")
		check(game.player.can_move and game.player.can_look, id + " input restored")
		game.stop_all_audio()
		game.queue_free()
		await process_frame
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_game()
	game.phase = game.Phase.NIGHT
	game.world.eddington.position = game.world.eddington_night
	game.player.global_position = Vector3(11.3, 0.05, 4.2)
	game.player.set_physics_process(false)
	await physics_frame
	game._interact("eddington")
	var camera: Camera3D = game.dialogue_camera
	check(camera.current, "night dialogue camera is current")
	var query := PhysicsRayQueryParameters3D.create(camera.eye_point, camera.global_position)
	query.exclude = [game.world.eddington.get_rid(), game.player.get_rid()]
	check(game.get_world_3d().direct_space_state.intersect_ray(query).is_empty(), "night camera remains on the face side of walls")
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
