extends SceneTree

const DT := 1.0 / 60.0
var game: Node
var records: Array = []
var out := ""

func _initialize() -> void:
	_run.call_deferred()

func eye(npc: Node3D) -> Vector3:
	var skeletons := npc.find_children("*", "Skeleton3D", true, false)
	if skeletons.is_empty():
		return npc.to_global(Vector3(0, 1.63, -0.12))
	var sk: Skeleton3D = skeletons[0]
	var bone := sk.find_bone("head")
	assert(bone >= 0, "Missing head bone")
	return sk.global_transform * sk.get_bone_global_pose(bone).origin + Vector3(0, 0.08, 0)

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	assert(not out.is_empty(), "Provide --out")
	seed(7)
	load("res://scripts/main.gd").next_seed = 7
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	game.ui.show_toast("", 0.0)
	await survey("day")
	await game._begin_totality()
	await survey_totality()
	await game._begin_night()
	# The night introduction opens dialogue; close it to restore walking.
	game.ui.dialog_panel.hide()
	game.player.can_move = true
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
		var camera_position: Vector3 = game.player.camera.global_position
		var distance: float = camera_position.distance_to(eye(npc))
		records.append({"scene": "totality", "character": character,
			"metres": distance, "camera_position": [camera_position.x, camera_position.y, camera_position.z],
			"diagnostic": "eye point and visibility not validated"})

func survey(scene_name: String) -> void:
	for character in ["eddington", "cottingham"]:
		var npc: Node3D = game.world[character]
		for direction in range(4):
			var angle: float = npc.rotation.y + direction * PI / 2.0
			var offset := Vector3(sin(angle), 0, cos(angle))
			game.player.global_position = npc.global_position + offset * 2.0 + Vector3(0, 0.05, 0)
			game.player.velocity = Vector3.ZERO
			game.player.can_move = true
			game.player.can_look = true
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
				"metres": minimum, "position": [best.x, best.y, best.z]})
