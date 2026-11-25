extends SceneTree

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
	TranslationServer.set_locale("zh_TW")
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.sim = Sim.new(7)
	game._start_game()
	game.prep_left = 5.0
	for frame in 300:
		game._process_prep(STEP)
		if game.prep_left > STEP:
			check(not game.ui.clock_label.text.contains("倒數 0:00"), "frame %d: countdown reaches zero early at %.4f s" % [frame, game.prep_left])
	check(game.prep_left <= STEP, "simulation reaches second contact")
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	print("%d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
