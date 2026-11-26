extends SceneTree

const Content := preload("res://scripts/content.gd")

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

func make_game(from_cambridge := false) -> Node:
	var story := root.get_node("Story")
	story.reset()
	story.prologue_done = from_cambridge
	story.from_prologue = from_cambridge
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	if not from_cambridge:
		game._start_game()
	return game

func walk_briefing(from_cambridge: bool) -> String:
	var game := make_game(from_cambridge)
	game._interact("eddington")
	var thoughts: Array[String] = []
	print("BRIEFING ", "CAMBRIDGE" if from_cambridge else "DIRECT", " ", L.current())
	while game.ui.dialog_active():
		var entry: Dictionary = game.ui._seq[game.ui._seq_i]
		print(game.ui.speaker_label.text, " | ", game.ui.text_label.get_parsed_text())
		if entry.s == Content.YOU and game.ui._choice_buttons.is_empty():
			thoughts.append(game.ui.text_label.get_parsed_text())
		if game.ui._choice_buttons.is_empty():
			game.ui._advance()
		else:
			check(thoughts.size() == 1, "assistant's thought appears before the optional briefing question")
			for button in game.ui._choice_buttons:
				print(button.text)
			game.ui._choice_buttons[0].pressed.emit()
	check(game.sim.briefed, "finishing the briefing unlocks preparation")
	game.sim.drive_rate_checked = true
	game._interact("cottingham")
	check(game.ui._choice_buttons.is_empty() and game.ui._seq.size() == 1 and game.ui._seq[0].s == Content.C,
		"calibrated drive opens only Cottingham's handoff")
	finish_dialogue(game)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	return "\n".join(thoughts)

func _run() -> void:
	var source_thoughts := []
	for locale in L.LOCALES:
		L.apply(locale)
		var direct := await walk_briefing(false)
		var cambridge := await walk_briefing(true)
		check(direct != cambridge, "briefing thought follows the entry route")
		if locale == "zh_TW":
			source_thoughts = [direct, cambridge]
		else:
			check(direct != source_thoughts[0] and cambridge != source_thoughts[1], "both briefing thoughts are localized")
	L.apply("zh_TW")
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
