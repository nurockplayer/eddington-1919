extends SceneTree
# Temporary real-scene capture for #416/#417; removed with the temporary workflow.
const Bench := preload("res://tests/benchmark.gd")
const Settings := preload("res://scripts/settings.gd")
var game: Node
var base := ""
var motion := false

func _initialize() -> void:
	_run.call_deferred()

func frames(n: int) -> void:
	for i in n: await process_frame

func save_frame(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size() == root.content_scale_size, "capture must be native viewport size")
	assert(image.save_png(path) == OK, "capture save failed")

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): base = arg.trim_prefix("--out=")
		if arg == "--motion": motion = true
	assert(base != "" and DisplayServer.get_name() != "headless")
	DirAccess.make_dir_recursive_absolute(base)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(12)
	Settings.quality = "standard"
	Settings.apply_quality(self)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.player.can_move = false
	game.player.can_look = false
	var bench := Bench.new()
	bench.main = game
	for tag in game.find_children("*", "Label3D", true, false):
		tag.visible = not tag.fixed_size
	for size in [Vector2i(1280, 720), Vector2i(2560, 1440), Vector2i(1920, 1080)]:
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		root.content_scale_size = size
		root.size = Vector2i(1280, 720)
		var folder := base.path_join(str(size.y))
		DirAccess.make_dir_recursive_absolute(folder)
		for b in Bench.BOOKMARKS + Bench.AUDITION_BOOKMARKS:
			if b[0] not in ["arrival", "coelostat_still", "dialogue", "darkroom", "totality_wide", "totality_sky", "totality_horizon"]: continue
			if size.y == 1080 and b[0] != "coelostat_still": continue
			game.ui.visible = false
			game.world.cottingham.visible = b[0] != "coelostat_still"
			bench._light(b[3])
			game.player.global_position = b[1]
			game.player.camera.fov = 60.0
			await frames(2)
			var target: Vector3 = b[2]
			if b[0] == "totality_wide":
				var sd: Vector3 = game.sim.sun_dir
				var flat := Vector3(sd.x, 0, sd.z).normalized()
				game.player.global_position = Vector3(0, 0.05, -1.4) - flat * Bench.WIDE_BACK
				game.player.camera.fov = Bench.WIDE_FOV
				var pitch := asin(sd.y) - deg_to_rad(Bench.WIDE_FOV / 3.0)
				target = game.player.global_position + Vector3(0, 1.6, 0) + (flat * cos(pitch) + Vector3.UP * sin(pitch)) * 10.0
			if target == Vector3.INF: target = game._totality_aim_point()
			game.player.look_at_point(target)
			if b[0] == "dialogue":
				game.ui.visible = true
				game.ui.hud.visible = false
				game.ui.title_panel.visible = false
				game.ui.cambridge_portraits = true
				game.ui.play([{"s": "Eddington", "t": Bench.AUDITION_LINE}])
			await frames(8)
			await save_frame(folder.path_join(b[0] + ".png"))
			game.ui.dialog_panel.hide()
			game.ui.dialogue_portrait.hide()
		if size.y == 1080: continue
		# Real second-contact staging and deterministic gameplay time.
		game._start_game()
		await game._begin_totality()
		game.set_process(false)
		game.player.set_physics_process(false)
		for i in 150:
			game._process(1.0 / 60.0)
			await process_frame
			if i + 1 in [72, 150]: await save_frame(folder.path_join("play_p12.png" if i == 71 else "play_p25.png"))
		game.phase = game.Phase.PREP
	if motion:
		root.content_scale_size = Vector2i(1280, 720)
		bench._light("totality")
		game.ui.visible = false
		game.player.look_at_point(game._totality_aim_point())
		var start_pitch: float = game.player.camera.rotation.x
		var start_yaw: float = game.player.rotation.y
		var folder := base.path_join("motion")
		DirAccess.make_dir_recursive_absolute(folder)
		for i in 120:
			var t := float(i) / 119.0
			game.player.camera.rotation.x = start_pitch + deg_to_rad(12.0) * sin(t * TAU)
			game.player.rotation.y = start_yaw + deg_to_rad(18.0) * sin(t * TAU)
			await process_frame
			await save_frame(folder.path_join("f_%03d.png" % i))
	bench.free()
	print("TOTALITY CAPTURE PASS: native stills and requested motion saved")
	quit()
