extends SceneTree

const Sim := preload("res://scripts/eclipse_sim.gd")
const Motion := preload("res://tools/style_motion.gd")
const Settings := preload("res://scripts/settings.gd")

func _initialize() -> void:
	start.call_deferred()

func start() -> void:
	var args := OS.get_cmdline_user_args()
	var state := args[0]
	print("CAPTURE staging")
	var out := OS.get_environment("EDD_CAPTURE_DIR")
	Settings.load_settings()
	var game := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	current_scene = game
	var capture := Capture.new()
	capture.main = game
	capture.out_dir = out
	capture.row_state = state
	game.add_child(capture)

class Capture:
	extends "res://tests/benchmark.gd"

	var row_state: String

	# Sample the live cloud field in camera rays along the whole row.
	func daylight_cover(start_time: float) -> float:
		var focal := tan(deg_to_rad(main.player.camera.fov) * 0.5)
		var n := 0
		var cloud := 0
		for sec in range(16):
			var rotation := Basis(Vector3.UP, Motion.yaw_at(sec + 0.5))
			for x in range(-5, 6):
				for y in range(2, 7):
					var ray := (rotation * Vector3(float(x) / 6.0 * 16.0 / 9.0 * focal, float(y) / 7.0 * focal, -1.0)).normalized()
					var uv: Vector2 = Vector2(ray.x, ray.z) / maxf(ray.y, 0.06) * Sim.CLOUD_SCALE - main.sim.wind * (start_time + sec + 0.5)
					var density := lerpf(main.sim._sample(uv), 0.97, 1.0 - smoothstep(0.05, 0.35, ray.y))
					cloud += int(density >= 0.53)
					n += 1
		return float(cloud) / n

	func totality_range(start_time: float, rate: float) -> Vector2:
		var bounds := Vector2(1.0, 0.0)
		for i in range(65):
			var density: float = main.sim.cloud_over_sun(start_time + 0.25 * i * rate)
			bounds = Vector2(minf(bounds.x, density), maxf(bounds.y, density))
		return bounds

	func _run() -> void:
		_hide_groups()
		main.ui.visible = false
		for tag in main.find_children("*", "Label3D", true, false):
			tag.visible = not tag.fixed_size
		var player = main.player
		player.can_move = false
		player.can_look = false
		main.set_process(false)
		player.set_physics_process(false)
		var total: bool = row_state.begins_with("totality_")
		var partial := row_state == "partial_cloud"
		var contact := 1.0 if total else (0.62 if partial else 0.0)
		var darkness := float(total)
		var rate := 1.0
		var start_cloud := -150.0
		if total:
			var target := Vector2(0.10, 0.25) if row_state == "totality_clear" else Vector2(0.35, 0.60)
			for candidate_rate in [Sim.TIME_SCALE, 1.0, 0.5, 0.25]:
				var best_score := INF
				for i in range(1 + int((Sim.TOTALITY_S - 16 * candidate_rate) * 4)):
					var t := 0.25 * i
					var interval := totality_range(t, candidate_rate)
					var score := 100.0 * (maxf(0.0, target.x - interval.x) + maxf(0.0, interval.y - target.y)) + absf((interval.x + interval.y - target.x - target.y) * 0.5)
					if score < best_score:
						best_score = score
						start_cloud = t
						rate = candidate_rate
				var bounds := totality_range(start_cloud, rate)
				if bounds.x >= target.x and bounds.y <= target.y:
					break
			var actual := totality_range(start_cloud, rate)
			if actual.x < target.x or actual.y > target.y:
				push_error("ROW2 %s cannot hold the requested density over the route: %s" % [row_state, actual])
				get_tree().quit(1)
				return
		else:
			var best := -INF if partial else INF
			for candidate in range(-180, -59):
				var cover := daylight_cover(candidate)
				if (partial and cover > best) or (not partial and cover < best):
					best = cover
					start_cloud = candidate
			print("[ROW2] daylight camera-ray density >=0.53 share (elevation above near-horizon band): ", best)
			if partial and best <= 0.5:
				push_error("ROW2 partial_cloud could not find majority cloud cover")
				get_tree().quit(1)
				return

		totality_cloud_t = start_cloud
		_light("totality" if total else "prep_early")
		player.global_position = Motion.position_at(0.0) + Vector3.UP * 0.001
		await _frames(20)
		var camera := FileAccess.open(out_dir.path_join("camera.tsv"), FileAccess.WRITE)
		camera.store_line("index\tsim_s\tx\ty\tz\tyaw_rad\tfov_deg\tcloud_s\tcloud_over_sun")
		print("[ROW2] state=", row_state, " seed=", main.sim.run_seed, " contact=", contact, " darkness=", darkness, " before_second_contact=", partial, " cloud_start=", start_cloud, " cloud_rate=", rate, " sun_density_range=", totality_range(start_cloud, rate), " fov=", player.camera.fov, " style=", main._style.id, " locale=en text_scale=", Settings.text_scale, " reduced_motion=", Settings.reduced_motion)
		var space: PhysicsDirectSpaceState3D = player.get_world_3d().direct_space_state
		print("CAPTURE draw expected")
		for i in Motion.COUNT:
			var t := float(i + 1) / Motion.FPS
			var pos := Motion.position_at(t) + Vector3.UP * 0.001
			var movement: Vector3 = pos - player.global_position
			var query := PhysicsRayQueryParameters3D.create(pos + Vector3.UP * 0.1, pos - Vector3.UP * 0.1)
			query.exclude = [player.get_rid()]
			var hit := space.intersect_ray(query)
			if player.test_move(player.global_transform, movement) or hit.is_empty() or absf(hit.position.y) > 0.002:
				push_error("ROW2 path obstructed or off ground at frame %d (position %s, ground %s)" % [i + 1, pos, hit.get("position")])
				get_tree().quit(1)
				return
			player.global_position = pos
			player.yaw = Motion.yaw_at(t)
			player.rotation.y = player.yaw
			player.camera.rotation.x = 0.0
			var cloud_t: float = start_cloud + t * rate
			main._apply_light(contact, darkness, cloud_t, 0.0, partial)
			await RenderingServer.frame_post_draw
			var img: Image = get_viewport().get_texture().get_image()
			if img.get_size() != Vector2i(1280, 720) or img.save_png(out_dir.path_join("f_%05d.png" % (i + 1))) != OK:
				push_error("ROW2 frame save failed at frame %d, viewport %s" % [i + 1, img.get_size()])
				get_tree().quit(1)
				return
			if i == 0:
				print("CAPTURE first frame saved")
			var eye: Vector3 = player.camera.global_position
			camera.store_line("%d\t%.9f\t%.9f\t%.9f\t%.9f\t%.9f\t%.9f\t%.9f\t%.9f" % [i + 1, t, eye.x, eye.y, eye.z, player.yaw, player.camera.fov, cloud_t, main.sim.cloud_over_sun(cloud_t)])
			await get_tree().process_frame
		camera.close()
		print("CAPTURE done")
		get_tree().quit()
