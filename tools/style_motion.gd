extends RefCounted
## Driven only by tests/benchmark.gd's opt-in --bench-motion hook.
const FPS := 60
const COUNT := 16 * FPS
const Player := preload("res://scripts/player.gd")
const Benchmark := preload("res://tests/benchmark.gd")
# Metres on the clearing: house frontage, west shelter aisle, open camp.
const ROUTE := [Vector3(-10, 0, -11), Vector3(-5, 0, -11),
	Vector3(-4, 0, -8), Vector3(-4, 0, -3), Vector3(-4.3, 0, 0),
	Vector3(-4, 0, 3), Vector3(-4, 0, 6),
	Vector3(4, 0, 8), Vector3(7, 0, 8)]


static func position_at(t: float) -> Vector3:
	var distance := minf(t, 10.0) * Player.WALK
	for i in range(1, ROUTE.size()):
		var length: float = ROUTE[i - 1].distance_to(ROUTE[i])
		if distance <= length:
			return ROUTE[i - 1].lerp(ROUTE[i], distance / length)
		distance -= length
	return ROUTE[-1]


static func yaw_at(t: float) -> float:
	var finish := position_at(10.0)
	var end_direction := Vector3(25, 0, -90) - finish
	var end_yaw := atan2(-end_direction.x, -end_direction.z)
	if t >= 10.0:
		return end_yaw + TAU * (t - 10.0) / 6.0
	var direction := position_at(minf(t + 0.25, 10.0)) - position_at(t)
	var yaw := atan2(-direction.x, -direction.z)
	return lerp_angle(yaw, end_yaw, smoothstep(9.0, 10.0, t))


func run(bench: Benchmark, state: String) -> void:
	var main = bench.main
	var player = main.player
	main.set_process(false)
	player.set_physics_process(false)
	bench._light(state)
	var start_cloud: float = -150.0 if state == "prep_early" else bench.totality_cloud_t
	print("[MOTION] lighting=", state, " contact=", 0.62 if state == "prep_early" else 1.0,
		" darkness=", 0.0 if state == "prep_early" else 1.0, " cloud_start=", start_cloud,
		" cloud_rate=", 1.0 if state == "prep_early" else main.sim.TIME_SCALE,
		" seed=", main.sim.run_seed, " fps=60 duration=16 walk_speed=", Player.WALK,
		" eye_height=", player.camera.position.y, " style=", main._style.id,
		" params=", JSON.stringify(main._style.params))
	player.global_position = position_at(0.0) + Vector3.UP * 0.001
	# Let the real scene finish initialising before recording. All capture poses
	# and cloud times below derive from the index, never wall-clock time.
	await bench._frames(20)
	var table := FileAccess.open(bench.out_dir.path_join("camera.tsv"), FileAccess.WRITE)
	table.store_line("index\tsim_s\tx\ty\tz\tyaw_rad")
	var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
	for i in COUNT:
		var t := float(i + 1) / FPS
		var pos := position_at(t) + Vector3.UP * 0.001
		var movement: Vector3 = pos - player.global_position
		if player.test_move(player.global_transform, movement):
			push_error("MOTION path obstructed at frame %d" % (i + 1))
			bench.get_tree().quit(1)
			return
		var query := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.1, pos - Vector3.UP * 0.1)
		query.exclude = [player.get_rid()]
		var hit := space.intersect_ray(query)
		if hit.is_empty() or absf(hit.position.y) > 0.002:
			push_error("MOTION path left ground at frame %d" % (i + 1))
			bench.get_tree().quit(1)
			return
		player.global_position = pos
		player.yaw = yaw_at(t)
		player.rotation.y = player.yaw
		player.camera.rotation.x = 0.0
		var cloud_t: float = start_cloud + t * (1.0 if state == "prep_early" else main.sim.TIME_SCALE)
		main._apply_light(0.62 if state == "prep_early" else 1.0, 0.0 if state == "prep_early" else 1.0, cloud_t, 0.0)
		await RenderingServer.frame_post_draw
		var img: Image = bench.get_viewport().get_texture().get_image()
		if img.get_size() != Vector2i(1280, 720) or img.save_png(bench.out_dir.path_join("f_%05d.png" % (i + 1))) != OK:
			push_error("MOTION frame save failed at frame %d" % (i + 1))
			bench.get_tree().quit(1)
			return
		var eye: Vector3 = player.camera.global_position
		table.store_line("%d\t%.9f\t%.9f\t%.9f\t%.9f\t%.9f" % [i + 1, t, eye.x, eye.y, eye.z, player.yaw])
		await bench.get_tree().process_frame
	table.close()
	print("[MOTION] done frames=960 ground_checks=960 collision_checks=960 cloud_end=", start_cloud + 16.0 * (1.0 if state == "prep_early" else main.sim.TIME_SCALE))
	bench.get_tree().quit()
