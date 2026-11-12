extends SceneTree

var failures := 0
var checks := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func _initialize() -> void:
	_run.call_deferred()

func finish_dialogue(game: Node) -> void:
	while game.ui.dialog_active():
		if game.ui._choice_buttons.is_empty():
			game.ui._advance()
		else:
			game.ui._choose(0)

func make_game() -> Node:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_game()
	return game

func _run() -> void:
	var game := make_game()
	game._interact("eddington")
	game.ui._advance()
	game.ui._advance()
	check(game.ui.text_label.text.contains("我從早上就盯著"), "briefing includes the cloud gap")
	finish_dialogue(game)
	var hotspot := game.get_node_or_null("SundyHotspot")
	check(hotspot != null and hotspot.get_meta("interact_id") == "sundy", "Sundy hotspot exists in PREP")
	game._interact("sundy")
	check(game.ui.text_label.text.contains("Jerónimo Carneiro"), "Sundy dialogue credits the plantation")
	finish_dialogue(game)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	var replies := ["嗯。照實說", "那就帶一箱", "……我也是"]
	for choice in 3:
		game = make_game()
		game.sim.drive_rate_checked = true
		game._interact("cottingham")
		check(game.ui.text_label.text.contains("Dyson 先生跟我說"), "first talk recalls Dyson")
		game.ui._advance()
		check(game.ui._choice_buttons.size() == 3, "stakes has three choices")
		game.ui._choose(choice)
		check(game.ui.text_label.text.contains(replies[choice]), "choice has its reply")
		finish_dialogue(game)
		game._interact("cottingham")
		check(game.ui.text_label.text.contains("走速對上了"), "later talk uses the usual line")
		finish_dialogue(game)
		game.stop_all_audio()
		game.queue_free()
		await process_frame
	for exposed in [0, 1]:
		game = make_game()
		game.phase = game.Phase.TOTALITY
		if exposed:
			game.sim.open_shutter(1.0)
			game.sim.accumulate(2.0, 0.5)
			game.sim.close_shutter()
		game._end_totality()
		await create_timer(5.0).timeout
		check(game.ui.dialog_active() and game.ui.text_label.text.contains("我沒看到日食"), "third contact starts the eclipse dialogue")
		if game.ui.dialog_active():
			game.ui._advance()
			check(game.ui.text_label.text.contains("沒有底片" if exposed == 0 else "雲變薄了"), "plate count selects the right line")
			finish_dialogue(game)
		await create_timer(1.5).timeout
		check(game.phase == game.Phase.NIGHT, "dialogue completion reaches NIGHT")
		game.stop_all_audio()
		game.queue_free()
		await process_frame
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
