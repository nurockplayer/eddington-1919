extends SceneTree

const DT := 1.0 / 60.0
var game: Node
var records: Array = []
var out := ""
var capture_dir := ""

func _initialize() -> void:
	_run.call_deferred()

func eye(npc: Node3D) -> Vector3:
	var irises := npc.find_children("*irises*", "MeshInstance3D", true, false)
	assert(irises.size() == 1, "Expected one iris mesh per character")
	var mesh: MeshInstance3D = irises[0]
	return mesh.to_global(mesh.mesh.get_aabb().get_center())

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--capture="): capture_dir = arg.trim_prefix("--capture=")
	assert(not out.is_empty(), "Provide --out")
	var dir_error := DirAccess.make_dir_recursive_absolute(out.get_base_dir())
	assert(dir_error == OK, "Cannot create output directory: %s" % error_string(dir_error))
	if not capture_dir.is_empty():
		assert(DirAccess.make_dir_recursive_absolute(capture_dir) == OK, "Cannot create capture directory")
	seed(7)
	load("res://scripts/main.gd").next_seed = 7
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	game.ui.show_toast("", 0.0)
	if capture_dir.is_empty():
		await survey("day")
	await game._begin_totality()
	await survey_totality()
	if not capture_dir.is_empty():
		var capture_file := FileAccess.open(out, FileAccess.WRITE)
		capture_file.store_string(JSON.stringify(records, "  "))
		capture_file.close()
		game.stop_all_audio()
		print("face reach: %d totality views" % records.size())
		quit()
		return
	await game._begin_night()
	# Advance the night introduction as a player can, restoring normal input.
	while game.ui.dialog_active():
		game.ui._advance()
		await process_frame
	await survey("darkroom")
	var file := FileAccess.open(out, FileAccess.WRITE)
	file.store_string(JSON.stringify(records, "  "))
	file.close()
	game.stop_all_audio()
	print("face reach: %d approaches" % records.size())
	quit()

func survey_totality() -> void:
	assert(not game.player.can_move, "Totality must retain the fixed player position")
	for character in ["eddington", "cottingham"]:
		var npc: Node3D = game.world[character]
		game.player.look_at_point(eye(npc))
		await physics_frame
		if not capture_dir.is_empty():
			await RenderingServer.frame_post_draw
			var err := root.get_texture().get_image().save_png(capture_dir.path_join("totality_" + character + ".png"))
			assert(err == OK, "Cannot save capture: %s" % error_string(err))
		var camera_position: Vector3 = game.player.camera.global_position
		var distance: float = camera_position.distance_to(eye(npc))
		records.append({"scene": "totality", "character": character,
			"metres": distance, "camera_position": [camera_position.x, camera_position.y, camera_position.z]})

func survey(scene_name: String) -> void:
	assert(game.player.can_move, "Walking must be enabled by the game")
	for character in ["eddington", "cottingham"]:
		var npc: Node3D = game.world[character]
		for direction in range(4):
			var angle: float = npc.rotation.y + direction * PI / 2.0
			var offset := Vector3(sin(angle), 0, cos(angle))
			var target: Vector3 = npc.global_position + offset * 2.0
			await walk_to(target)
			var start: Vector3 = game.player.global_position
			game.player.look_at_point(eye(npc))
			await physics_frame
			Input.action_press("move_forward")
			var minimum := INF
			var best := Vector3.ZERO
			for frame in 150:
				await physics_frame
				var distance: float = game.player.camera.global_position.distance_to(eye(npc))
				if distance < minimum:
					minimum = distance
					best = game.player.global_position
			Input.action_release("move_forward")
			records.append({"scene": scene_name, "character": character, "direction": direction,
				"metres": minimum, "start": [start.x, start.y, start.z], "position": [best.x, best.y, best.z]})

func walk_to(target: Vector3) -> void:
	# Sample the player's capsule against the actual collision world and walk a
	# connected grid route from the position reached by the preceding approach.
	var grid := AStarGrid2D.new()
	grid.region = Rect2i(-32, -32, 80, 64)
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.31
	shape.height = 1.65
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = game.player.collision_mask
	query.exclude = [game.player.get_rid()]
	var space: PhysicsDirectSpaceState3D = game.player.get_world_3d().direct_space_state
	for x in range(-32, 48):
		for z in range(-32, 32):
			query.transform = Transform3D(Basis.IDENTITY, Vector3(x * 0.5, 0.9, z * 0.5))
			if not space.intersect_shape(query, 1).is_empty():
				grid.set_point_solid(Vector2i(x, z))
	var from := Vector2i(roundi(game.player.global_position.x * 2), roundi(game.player.global_position.z * 2))
	grid.set_point_solid(from, false)
	var goal := Vector2i(roundi(target.x * 2), roundi(target.z * 2))
	var path: Array[Vector2i] = []
	var nearest := INF
	for x in range(goal.x - 2, goal.x + 3):
		for z in range(goal.y - 2, goal.y + 3):
			var cell := Vector2i(x, z)
			if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):
				continue
			var d := Vector2(x * 0.5 - target.x, z * 0.5 - target.z).length()
			if d >= nearest:
				continue
			var candidate := grid.get_id_path(from, cell)
			if not candidate.is_empty():
				path = candidate
				nearest = d
	assert(not path.is_empty(), "No reachable approach near %s" % target)
	for cell in path.slice(1):
		var point := Vector3(cell.x * 0.5, game.player.camera.global_position.y, cell.y * 0.5)
		var reached := false
		for frame in 60:
			var delta := Vector2(point.x - game.player.global_position.x, point.z - game.player.global_position.z)
			if delta.length() < 0.16:
				reached = true
				break
			game.player.look_at_point(point)
			Input.action_press("move_forward")
			await physics_frame
		Input.action_release("move_forward")
		assert(reached, "Player could not walk to grid point %s" % cell)
