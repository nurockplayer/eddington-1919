extends SceneTree
## Step the real contact tweens at 60 Hz and inspect each would-be rendered frame.
const Sim := preload("res://scripts/eclipse_sim.gd")
const STEP := 1.0 / 60.0
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	root.size = Vector2i(1280, 720)
	for path in ["dialogue", "timer"]:
		print("Second contact entry: ", path)
		await _test_path(path)
	print("%d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_path(path: String) -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.sim = Sim.new(7)
	game._start_game()
	game._process_prep(0.0)
	await process_frame
	var camera: Transform3D = game.player.camera.global_transform
	var yaw: float = game.player.yaw
	var pitch: float = game.player.pitch
	var objectives: String = game.ui.objectives.text
	var clock: String = game.ui.clock_label.text
	var clock_rect: Rect2 = game.ui.clock_label.get_global_rect()
	var plates := var_to_bytes(game.sim.plates)
	check(game.ui.paper_hud and not objectives.is_empty() and not clock.is_empty(), "normal engraving PREP HUD is populated")
	if path == "dialogue":
		game._pending = "eddington_prep"
		game._on_dialogue_done({"prep": 0})
	else:
		game.prep_left = 0.0
		game._process_prep(0.0)
		# The expiry tick updates the countdown before the fade starts.
		clock = game.ui.clock_label.text
		clock_rect = game.ui.clock_label.get_global_rect()
	check(game.phase == game.Phase.TOTALITY and game._busy, path + " starts the real second-contact transition")
	var fade_out: Tween = get_processed_tweens().back()
	fade_out.pause()
	_check_prep_frame(game, camera, yaw, pitch, objectives, clock, clock_rect)
	var out_frames := 0
	for i in 44:
		game._process(STEP)
		fade_out.custom_step(STEP)
		out_frames += 1
		if game.ui.fade.color.a >= 0.999:
			break
		_check_prep_frame(game, camera, yaw, pitch, objectives, clock, clock_rect)
	check(out_frames >= 42 and out_frames <= 43, "fade-out still lasts 0.7 seconds")
	check(game.ui.fade.color.a == 1.0, "move and HUD handover happen at full black")
	check(game.player.global_position.is_equal_approx(game.world.station_pos + Vector3(0, 0.05, 0)), "player moves to the telescope under black")
	check(game.player.yaw != yaw or game.player.pitch != pitch, "view turns toward the Sun under black")
	check(not game.world.roof.visible and game.ui.objectives.text.is_empty(), "roof and checklist leave under black")
	_check_totality_frame(game)
	var fade_in: Tween = get_processed_tweens().back()
	fade_in.pause()
	var in_frames := 0
	for i in 74:
		game._process(STEP)
		fade_in.custom_step(STEP)
		in_frames += 1
		_check_totality_frame(game)
		check(game.t_game == 0.0, "contact clock stays frozen through fade-in frame %d" % i)
		check(var_to_bytes(game.sim.plates) == plates, "fade does not change exposures at frame %d" % i)
		if not game._busy:
			break
	check(in_frames >= 72 and in_frames <= 73, "fade-in still lasts 1.2 seconds")
	check(not game._busy and game.ui.fade.color.a == 0.0, "handover completes on the clear frame")
	game._process(STEP)
	_check_totality_frame(game)
	check(is_equal_approx(game.t_game, STEP * Sim.TIME_SCALE), "totality clock starts on the next process frame")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _check_prep_frame(game: Node, camera: Transform3D, yaw: float, pitch: float, objectives: String, clock: String, clock_rect: Rect2) -> void:
	check(game.player.camera.global_transform.is_equal_approx(camera) and game.player.yaw == yaw and game.player.pitch == pitch, "visible fade-out frame retains the PREP camera")
	check(game.ui.objectives.text == objectives and game.ui.objectives.get_parent().visible, "visible fade-out frame retains the checklist")
	check(game.ui.clock_label.text == clock and game.ui.clock_label.get_global_rect().is_equal_approx(clock_rect), "visible fade-out frame retains the clock and its position")
	check(not game.ui.tot_panel.visible and game.world.roof.visible, "visible fade-out frame retains the PREP view")


func _check_totality_frame(game: Node) -> void:
	check(game.ui.tot_panel.visible and not game.ui.tot_label.text.is_empty() and game.ui.tot_strip.visible, "totality panel is populated on every fade-in and handover frame")
	check(game.ui.clock_label.text.is_empty() and not game.ui.clock_label.visible, "totality panel replaces the clock without a gap")
	check(not game.ui.prompt_label.visible, "no prompt slip on any fade-in or handover frame")
