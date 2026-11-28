extends SceneTree
## F1 cameras and turn, with the paired row 9 sampling from the game benchmark.

class HouseBenchmark extends "res://tests/benchmark.gd":
	const POSITIONS := {
		"arrival": Vector3(2.6, 0.05, 4.2),
		"shelter": Vector3(-1.5, 0.05, -3.7),
	}
	const TARGET := Vector3(-15, 3.25, -20)

	func _run() -> void:
		main.set_process(false)
		main.player.set_physics_process(false)
		main.ui.visible = false
		for tag in main.find_children("*", "Label3D", true, false):
			tag.visible = not tag.fixed_size
		var stats: Array = []
		for view in POSITIONS:
			main.player.global_position = POSITIONS[view]
			main.player.look_at_point(TARGET)
			main.player.rotation.y = main.player.yaw
			main.player.camera.rotation.x = main.player.pitch
			for state in ["daylight", "early-partial", "totality"]:
				_house_light(state)
				var label: String = view + "-" + state
				var row := await _sample_bookmark(label, state)
				if row.screenshot.is_empty() or last_image.get_size() != Vector2i(1280, 720):
					push_error("Failed to capture 1280x720 " + label)
					get_tree().quit(1)
					return
				stats.append(row)
				if label == "shelter-totality":
					for rep in range(2, 4):
						await _frames(SETTLE_FRAMES)
						var samples := PackedFloat32Array()
						for i in FORCED_FRAMES:
							var start := Time.get_ticks_usec()
							RenderingServer.force_draw(false)
							samples.append((Time.get_ticks_usec() - start) / 1000.0)
						stats.append({"bookmark": label + "-rep%d" % rep,
							"forced_draw_ms_p95": _p95(samples), "forced_draw_ms_avg": _avg(samples)})
		var report := FileAccess.open(out_dir.path_join("metrics.json"), FileAccess.WRITE)
		report.store_string(JSON.stringify(stats, "\t"))
		report.close()
		main.player.global_position = POSITIONS.arrival
		main.player.camera.rotation.x = 0.0
		main.player.rotation.y = deg_to_rad(20)
		_house_light("daylight")
		await _frames(SETTLE_FRAMES)
		for frame in 240:
			main.player.rotation.y = deg_to_rad(20) + PI * frame / 239.0
			main._apply_light(0.0, 0.0, -200 + frame / 60.0, 0.0)
			await RenderingServer.frame_post_draw
			if frame % 2 == 0:
				var img := get_viewport().get_texture().get_image()
				if img.get_size() != Vector2i(1280, 720) or img.save_png(out_dir.path_join("turn-%03d.png" % frame)) != OK:
					push_error("Failed to capture turn frame %d" % frame)
					get_tree().quit(1)
					return
			await get_tree().process_frame
		print("F1: 6 stills, 120 turn frames, 3 shelter-totality samples")
		get_tree().quit()

	func _house_light(state: String) -> void:
		if state == "daylight":
			_light("prep_early")
			main._apply_light(0.0, 0.0, -200.0, 0.0)
		elif state == "early-partial":
			_light("prep_early")
		else:
			_light("totality")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game := load("res://scenes/main.tscn").instantiate() as Node
	root.add_child(game)
	var bench := HouseBenchmark.new()
	bench.main = game
	bench.out_dir = OS.get_cmdline_user_args()[0]
	game.add_child(bench)
