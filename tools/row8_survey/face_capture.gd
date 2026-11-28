extends SceneTree
## Row 8d, using the survey's standing-pose search and first-person camera.

const STEP := 0.25
var game: Node
var player: CharacterBody3D
var space: PhysicsDirectSpaceState3D
var capsule: PhysicsShapeQueryParameters3D
var grid := AStarGrid2D.new()
var evidence: Array = []
var phase_walked := 0.0
var out := OS.get_environment("EDD_CAPTURE_DIR")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	print("CAPTURE staging")
	seed(7)
	load("res://scripts/main.gd").next_seed = 7
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	player = game.player
	if "--perf" in OS.get_cmdline_user_args():
		var bench := ShelterBenchmark.new()
		bench.main = game
		bench.out_dir = out
		game.add_child(bench)
		return
	await process_frame
	game._start_game()
	game.ui.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var shape := player.find_children("*", "CollisionShape3D", false, false)[0] as CollisionShape3D
	capsule = PhysicsShapeQueryParameters3D.new()
	capsule.shape = shape.shape
	capsule.collision_mask = player.collision_mask
	capsule.exclude = [player.get_rid()]
	print("CAPTURE draw expected")
	await survey("day", Rect2i(-20, -38, 40, 62))
	await game._begin_night()
	while game.ui.dialog_active():
		game.ui._advance()
		await process_frame
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await survey("safelight", Rect2i(24, 0, 27, 28))
	var receipt := FileAccess.open(out.path_join("walking.json"), FileAccess.WRITE)
	receipt.store_string(JSON.stringify(evidence, "\t"))
	receipt.close()
	game.stop_all_audio()
	print("CAPTURE done")
	quit()


func survey(state: String, region: Rect2i) -> void:
	await physics_frame
	assert(player.get("can_move"), "Survey needs the game's normal movement")
	phase_walked = 0.0
	space = player.get_world_3d().direct_space_state
	grid.region = region
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	grid.update()
	for z in range(region.position.y, region.end.y):
		for x in range(region.position.x, region.end.x):
			var cell := Vector2i(x, z)
			grid.set_point_solid(cell, not stand(Vector2(cell) * STEP).is_finite())
	for id in ["eddington", "cottingham"]:
		var npc: Node3D = game.world[id]
		await capture_view(state, id, npc, 0.0, 90.0)
		if id == "eddington":
			await capture_view(state, "hat-front", npc, 0.0, 25.0)
			await capture_view(state, "hat-side", npc, 90.0, 18.0)


func ray(start: Vector3, stop: Vector3, excluded: Array[RID]) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(start, stop, player.collision_mask, excluded)
	return space.intersect_ray(query)


func stand(xz: Vector2) -> Vector3:
	var floor := ray(Vector3(xz.x, 0.60, xz.y), Vector3(xz.x, -0.65, xz.y), [player.get_rid()])
	if floor.is_empty() or floor.normal.y < 0.8 or floor.collider.has_meta("interact_id"):
		return Vector3.INF
	capsule.transform.origin = floor.position + Vector3.UP * 0.881
	if not space.intersect_shape(capsule, 1).is_empty():
		return Vector3.INF
	return floor.position + Vector3.UP * 1.626


func capture_view(state: String, label: String, npc: Node3D, azimuth: float, spread: float) -> void:
	var mesh := npc.find_child("*_irises", true, false) as MeshInstance3D
	var face := mesh.to_global(mesh.mesh.get_aabb().get_center())
	var figure := npc.get_node("figure") as Node3D
	var front := (face - figure.global_position).slide(Vector3.UP).normalized()
	var candidates: Array[Vector3] = []
	var angles := [azimuth]
	if label == "hat-side":
		angles.append(-azimuth)
	for angle in angles:
		for i in range(-roundi(spread / 2.5), roundi(spread / 2.5) + 1):
			var direction := front.rotated(Vector3.UP, deg_to_rad(float(angle) + i * 2.5))
			for radius in range(8, 121):
				var point := face + direction * (radius * 0.025)
				var eye := stand(Vector2(point.x, point.z))
				if eye.is_finite() and ray(eye, face, [player.get_rid(), (npc as CollisionObject3D).get_rid()]).is_empty():
					candidates.append(eye)
					# Retain approach points behind the geometric limit for the route search.
					if radius % 4 == 0:
						break
	candidates.sort_custom(func(a: Vector3, b: Vector3) -> bool: return a.distance_squared_to(face) < b.distance_squared_to(face))
	var start := player.global_position
	for eye in candidates:
		var route := route_to(eye)
		if route.is_empty():
			continue
		var complete := true
		for point in route:
			var before := player.global_position
			var reached := await walk_to(point)
			phase_walked += before.distance_to(player.global_position)
			if not reached:
				complete = false
				break
		if not complete:
			continue
		var camera: Camera3D = player.get("camera")
		var target := face
		if label.begins_with("hat-"):
			var hat := npc.find_child("eddington_hat", true, false) as MeshInstance3D
			target = hat.to_global(hat.mesh.get_aabb().get_center())
		player.call("look_at_point", target)
		for i in 6:
			await physics_frame
		if not ray(camera.global_position, target, [player.get_rid(), (npc as CollisionObject3D).get_rid()]).is_empty():
			continue
		await RenderingServer.frame_post_draw
		var filename := "%s-%s.png" % [state, label]
		assert(root.get_texture().get_image().save_png(out.path_join(filename)) == OK)
		if evidence.is_empty():
			print("CAPTURE first frame saved")
		evidence.append({"state": state, "view": label, "file": filename,
			"eye_to_iris_m": camera.global_position.distance_to(face), "walked_m": phase_walked,
			"estimated_minimum_m": candidates[0].distance_to(face),
			"start": xyz(start), "standing": xyz(player.global_position), "camera": xyz(camera.global_position)})
		return
	assert(false, "No walked view for %s %s" % [state, label])


func xyz(point: Vector3) -> Array:
	return [point.x, point.y, point.z]


func route_to(eye: Vector3) -> Array[Vector3]:
	var start := cell_at(player.global_position)
	var start_blocked := grid.is_point_solid(start)
	grid.set_point_solid(start, false)
	var finish := cell_at(eye)
	var best: Array[Vector3] = []
	for offset in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT,
			Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var cell: Vector2i = finish + offset
		if not grid.is_in_boundsv(cell) or grid.is_point_solid(cell):
			continue
		var path := grid.get_id_path(start, cell)
		if path.is_empty():
			continue
		var point := Vector3(cell.x * STEP, eye.y, cell.y * STEP)
		capsule.transform.origin = point - Vector3.UP * 0.745
		capsule.motion = (eye - point).slide(Vector3.UP)
		var fraction := space.cast_motion(capsule)[0]
		capsule.motion = Vector3.ZERO
		if fraction < 0.98:
			continue
		if best.is_empty() or path.size() < best.size():
			best.clear()
			for waypoint in path.slice(1):
				best.append(Vector3(waypoint.x * STEP, eye.y, waypoint.y * STEP))
			best.append(eye)
	grid.set_point_solid(start, start_blocked)
	return best


func cell_at(point: Vector3) -> Vector2i:
	return Vector2i(roundi(point.x / STEP), roundi(point.z / STEP))


func walk_to(point: Vector3) -> bool:
	for i in 12:
		var delta := (point - player.global_position).slide(Vector3.UP)
		if delta.length() <= 0.058:
			return true
		player.call("look_at_point", player.get("camera").global_position + delta)
		Input.action_press("move_forward")
		await physics_frame
		Input.action_release("move_forward")
	return false


class ShelterBenchmark extends "res://tests/benchmark.gd":
	func _run() -> void:
		main.set_process(false)
		main.player.set_physics_process(false)
		main.ui.hide()
		main.player.global_position = Vector3(-1.5, 0.05, -3.7)
		main.player.look_at_point(Vector3(-15, 3.25, -20))
		main.player.rotation.y = main.player.yaw
		main.player.camera.rotation.x = main.player.pitch
		_light("totality")
		print("CAPTURE draw expected")
		await _frames(SETTLE_FRAMES)
		assert(await _shot(out_dir.path_join("shelter-totality.png")))
		print("CAPTURE first frame saved")
		var samples := PackedFloat32Array()
		for i in FORCED_FRAMES:
			var start := Time.get_ticks_usec()
			RenderingServer.force_draw(false)
			samples.append((Time.get_ticks_usec() - start) / 1000.0)
		var receipt := FileAccess.open(out_dir.path_join("perf.json"), FileAccess.WRITE)
		receipt.store_string(JSON.stringify({"p95_ms": _p95(samples), "samples_ms": samples}))
		receipt.close()
		print("CAPTURE done")
		get_tree().quit()
