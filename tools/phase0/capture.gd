extends "res://tools/look_shots.gd"
## Process-local instrumentation. Reuse the look-shot frame/UI helpers and the
## seven original benchmark cameras; never modify a gameplay resource.
const Bench = preload("res://tests/benchmark.gd")
const Settings = preload("res://scripts/settings.gd")
const Content = preload("res://scripts/content.gd")
const Plate = preload("res://scripts/plate_render.gd")
const DT := 1.0 / 60.0
var game
var records: Array = []
var locale := "en"
var event_frame := 0

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
	assert(DisplayServer.get_name() != "headless", "Phase-0 requires windowed rendering")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	await fresh()
	var bench = Bench.new()
	bench.main = game
	for bookmark in Bench.BOOKMARKS.slice(0, 7):
		bench._light(bookmark[3])
		await pose(bookmark[1], bookmark[2])
		_hide_ui(game)
		await still("golden_" + bookmark[0], bookmark[3], "hidden")
	for size in [Vector2i(1920, 1080), Vector2i(2560, 1440)]:
		root.size = size
		root.content_scale_size = size
		for index in [0, 4]:
			var bookmark = Bench.BOOKMARKS[index]
			bench._light(bookmark[3])
			await pose(bookmark[1], bookmark[2])
			await still("%s_%dx%d" % [bookmark[0], size.x, size.y], bookmark[3], "hidden")
	bench.free()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	await fresh()
	game._start_game()
	await pose(Vector3(-1.1, 0.05, 0.9), game.world.eddington.global_position + Vector3.UP * 1.55)
	await still("nearest_npc", "prep", "hud")
	await pose(Vector3(-15, 0.05, -10), Vector3(-15, 4.4, -15.9))
	await still("sign_approach", "prep", "hud")
	await pose(Vector3(-1.5, 0.05, -3.7), Vector3(0, 2.95, -4.5))
	await still("under_roof", "prep", "hud")
	await fresh()
	await still("title", "title", "title")
	game._start_game()
	game.ui.open_settings()
	await still("settings", "prep", "settings")
	game.ui.close_settings()
	game.ui.toggle_pause()
	await still("pause", "prep", "pause")
	game.ui.toggle_pause()
	for language in ["en", "ja", "zh_TW", "ko"]:
		locale = language
		await fresh()
		game._start_game()
		game._process(DT)
		await still("hud_" + locale, "prep", "hud")
		await pose(Vector3(-1.1, 0.05, 0.9), game.world.eddington.global_position + Vector3.UP * 1.55)
		game._say([Content.eddington_prep(2, false, false, 0)[0]], "")
		await still("dialogue_" + locale, "prep", "dialogue")
		game.ui._advance()
		await prepare_plates()
		game._open_viewer()
		await still("plate_" + locale, "night", "plate_inspection")
		for i in game.sim.plates.size():
			game._on_reading_set(i, game.sim.reading_for_value(0.87 if i == 0 else 1.75))
		game._finish_measurement()
		await still("results_" + locale, "night", "measurement_results")
	locale = "en"
	for kind in ["arrival_walk_turn", "second_contact", "dialogue_open_close"]:
		await clip(kind)
	var file := FileAccess.open(out_dir.path_join("receipts.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer": RenderingServer.get_current_rendering_method(),
		"godot_version": Engine.get_version_info().string, "captures": records}, "\t"))
	file.close()
	game.stop_all_audio()
	print("PHASE0 CAPTURE COMPLETE JST: %d captures" % records.size())
	quit(1 if failed else 0)

func fresh() -> void:
	paused = false
	if is_instance_valid(game):
		game.stop_all_audio()
		game.free()
		await frames(2)
	seed(7)
	L.apply(locale)
	load("res://scripts/main.gd").next_seed = 7
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.ui.set_process(false)
	Settings.text_scale = Settings.TEXT_SCALES.max()
	Settings.refresh_fonts(self)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	await frames(20)
	event_frame = 0

func pose(position: Vector3, target: Vector3) -> void:
	game.player.global_position = position
	game.player.velocity = Vector3.ZERO
	if target == Vector3.INF: target = game._totality_aim_point()
	await frames(2)
	game.player.look_at_point(target)
	game.player.rotation.y = game.player.yaw
	game.player.camera.rotation.x = game.player.pitch
	await frames(6)

func metadata(state: String, ui: String) -> Dictionary:
	var camera: Camera3D = game.player.camera
	var transform: Transform3D = camera.global_transform
	var basis: Array = []
	for vector in [transform.basis.x, transform.basis.y, transform.basis.z, transform.origin]:
		basis.append([snappedf(vector.x, 0.000001), snappedf(vector.y, 0.000001), snappedf(vector.z, 0.000001)])
	return {"scene": "res://scenes/main.tscn", "state": state, "camera_transform": basis,
		"fov": camera.fov, "resolution": [root.size.x, root.size.y], "locale": locale,
		"seed": 7, "ui_state": ui, "text_scale": Settings.text_scale,
		"event_time": {"frame": event_frame, "seconds": event_frame * DT, "clock": "simulation", "zone": "JST"}}

func still(id: String, state: String, ui: String) -> void:
	await frames(6)
	await _save(id)
	var record := metadata(state, ui)
	record.merge({"id": id, "file": id + ".png", "kind": "still"})
	records.append(record)

func prepare_plates() -> void:
	game.sim.rule_id = "strict"
	for i in 2:
		game.sim.open_shutter(210.0 + i * 12)
		game.sim.accumulate(6.0, 1.0 / 30.0)
		game.sim.close_shutter(false)
	for plate in game.sim.plates: plate.included = true
	# Native night entry, including actor placement, dress, lamps and plate render.
	await game._begin_night()
	while game.ui.dialog_panel.visible: game.ui._advance()

func clip(kind: String) -> void:
	await fresh()
	game._start_game()
	game.ui.show_toast("", 0.0)
	game.player.can_move = false
	game.player.can_look = false
	if kind == "second_contact":
		await pose(Vector3(0, 0.05, -0.9), game.player.camera.global_position + game.sim.sun_dir * 10)
	elif kind == "dialogue_open_close":
		await pose(Vector3(-1.1, 0.05, 0.9), game.world.eddington.global_position + Vector3.UP * 1.55)
	var folder := out_dir.path_join("scratch/" + kind)
	DirAccess.make_dir_recursive_absolute(folder)
	var trace: Array = []
	var count := 990 if kind == "arrival_walk_turn" else 330
	for i in count:
		event_frame = i - 30
		if i == 30:
			if kind == "second_contact": game.prep_left = DT
			if kind == "dialogue_open_close": game._say([Content.eddington_prep(2, false, false, 0)[0]], "")
		if kind == "dialogue_open_close" and i == 180: game.ui._advance()
		if kind == "arrival_walk_turn" and i >= 30:
			# A ten-second walking loop in the open arrival clearing, then a
			# six-second full turn. Each displacement checks the real collision shape.
			var t := float(i - 30) / 60.0
			var angle := TAU * minf(t, 10.0) / 10.0
			var position := Vector3(2.6 + 1.25 * sin(angle), 0.05, 4.2 + 1.25 * (1.0 - cos(angle)))
			var movement: Vector3 = position - game.player.global_position
			assert(not game.player.test_move(game.player.global_transform, movement), "Arrival walk obstructed")
			game.player.global_position = position
			game.player.yaw = -PI / 2.0 - angle if t < 10.0 else -PI / 2.0 + TAU * (t - 10.0) / 6.0
		game._process(DT)
		game.ui._process(DT)
		game.player.rotation.y = game.player.yaw
		game.player.camera.rotation.x = game.player.pitch
		await RenderingServer.frame_post_draw
		assert(root.get_texture().get_image().save_png(folder.path_join("f_%05d.png" % i)) == OK)
		var record := metadata(kind, "dialogue" if game.ui.dialog_panel.visible else "hud")
		record["fade_alpha"] = snappedf(game.ui.fade.color.a, 0.000001)
		trace.append(record)
		await process_frame
	var record: Dictionary = trace[0].duplicate(true)
	record.merge({"id": kind, "file": kind + ".mp4", "kind": "clip", "fps": 60,
		"frame_count": count, "trigger_frame": 30, "pre_trigger_seconds": 0.5,
		"close_trigger_frame": 180 if kind == "dialogue_open_close" else null,
		"frames": trace})
	records.append(record)
