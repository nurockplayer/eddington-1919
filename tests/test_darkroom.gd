extends SceneTree
## AA fun 04: consult the active print's notes and revise a plate choice.

const Sim := preload("res://scripts/eclipse_sim.gd")
const Render := preload("res://scripts/plate_render.gd")
const Settings := preload("res://scripts/settings.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _new_game(case_id: String) -> Node:
	load("res://scripts/main.gd")._ensure_inputs()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.ui.hide_title()
	game.ui.hud.hide()
	game.sim = Sim.new(77)
	game.sim.rule_id = "strict"
	game.sim.drive_wound = true
	game.sim.drive_error = 0.0
	if case_id == "pair":
		game.plates_left = 2
		for exposure in [[50.0, 24.0, 0.67], [100.0, 45.0, 0.0]]:
			game.t_game = exposure[0]
			game.change_left = 0.0
			game._toggle_shutter()
			game.sim.accumulate(exposure[1], exposure[2])
			game._toggle_shutter()
	elif case_id == "washout":
		game.sim.open_shutter(292.0)
		game.sim.accumulate(10.0, 0.0)
		game.sim.close_shutter(true)
	await process_frame
	game.ui.toast.hide()
	game.ui.set_totality(false)
	game.phase = game.Phase.NIGHT
	game.comparison_tex = Render.render(game.sim, null)
	for plate in game.sim.plates:
		game.plate_textures.append(Render.render(game.sim, plate))
	game._open_viewer()
	await process_frame
	return game


func _selection(game: Node) -> void:
	var ui = game.ui
	var fogged: Dictionary = game.sim.plates[0]
	var trailed: Dictionary = game.sim.plates[1]
	check(fogged.fog >= 0.6 and fogged.trail < 0.35 and fogged.usable, "first print is fogged")
	check(trailed.trail >= 0.35 and trailed.fog == 0.0 and trailed.usable, "second print is trailed")
	var notebook := ui.get("plate_notes_btn") as Button
	check(notebook != null, "the print has a notebook control")
	if notebook == null:
		print("Main-branch plate viewer on selection: ", ui.plate_info.get_parsed_text())
		return

	var notes: RichTextLabel = ui.plate_notes
	check(notebook.visible and not notes.visible and ui.big_plate.texture == game.plate_textures[0],
		"the fogged print is shown with its notebook closed")
	check(not ui.blink_btn.disabled and not ui.loupe_btn.disabled, "comparison tools are available")
	ui.include_box.button_pressed = true
	ui.thumbs.get_child(2).pressed.emit()
	check(fogged.included and not trailed.included and not notes.visible, "make a provisional choice from the prints")
	notebook.button_pressed = true
	var trailed_notes := notes.text
	check(notes.visible and not trailed_notes.is_empty() and not trailed.included, "consult the trailed print before inclusion")

	ui.thumbs.get_child(1).pressed.emit()
	check(not notes.visible and not notebook.button_pressed, "switching plates closes the notebook")
	notebook.button_pressed = true
	var fogged_notes := notes.text
	check(notes.visible and not fogged_notes.is_empty() and fogged_notes != trailed_notes,
		"consult the included fogged print and see its own notes")
	ui.measure_btn.pressed.emit()
	check(game.sim.measured and notes.visible and game.sim.measured_selection == [1], "lock the provisional choice")
	ui.reselect_btn.pressed.emit()
	ui.include_box.button_pressed = false
	ui.thumbs.get_child(2).pressed.emit()
	notebook.button_pressed = true
	check(notes.visible and notes.text == trailed_notes, "reopening the notebook restores the active print's notes")
	ui.include_box.button_pressed = true
	ui.measure_btn.pressed.emit()
	check(game._pending == "reselect_reason", "changing the locked selection asks for a reason")
	ui._choice_buttons[0].pressed.emit()
	check(game.sim.measured_selection == [2] and game.sim.reselect_reason == "quality"
		and game.sim.reselect_added == [2] and game.sim.reselect_removed == [1],
		"the original and revised choices and the stated reason are recorded")


func _report(case_id: String) -> void:
	var game := await _new_game(case_id)
	var ui = game.ui
	if case_id == "washout":
		ui.include_box.button_pressed = true
		check(game.sim.plates[0].included and game.sim.plates[0].sunlit and not game.sim.plates[0].usable,
			"the included washout cannot produce a reading")
		ui.plate_notes_btn.button_pressed = true
		check(ui.plate_notes.visible and not ui.plate_notes.text.is_empty(), "the washout has an on-demand fault note")
	else:
		check(not ui.plate_notes_btn.visible and not ui.include_box.visible, "zero plates shows only the reference")
	ui.measure_btn.pressed.emit()
	ui.report_btn.pressed.emit()
	check(game.sim.combined().n == 0 and game._pending == "judgment"
		and ui._seq[ui._seq_i].key == "telegram", case_id + " reaches the inconclusive telegram")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _run() -> void:
	Settings.language = "en"
	L.apply("en")
	var game := await _new_game("pair")
	_selection(game)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	if failures == 0:
		await _report("washout")
		await _report("empty")
	print("test_darkroom: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
