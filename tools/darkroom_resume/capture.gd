extends SceneTree
## Before quit and cold-process Continue frames for PR #475 / Refs #351.

const Settings := preload("res://scripts/settings.gd")

var out: String
var stage: String
var mode: String


func _initialize() -> void:
	_run.call_deferred()


func _until(condition: Callable) -> void:
	while not condition.call():
		await process_frame


func _dialogue(game, choices := {}) -> void:
	while game.ui.dialog_active():
		var entry: Dictionary = game.ui._seq[game.ui._seq_i]
		if entry.has("choices"):
			game.ui._choose(choices.get(entry.get("key"), 0))
		else:
			game.ui._advance()


func _include(game, index: int, included: bool) -> void:
	game.ui._select_plate(index, game.plate_textures[index], false)
	game.ui.include_box.toggled.emit(included)


func _frame(game, name: String) -> void:
	for i in 30:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	assert(image.get_size() == root.size, "capture must have native window dimensions")
	assert(image.save_png(out.path_join(name + ".png")) == OK, "cannot save frame")
	var receipt := {"frame": name + ".png", "pixels": [image.get_width(), image.get_height()],
		"locale": L.current(), "text_scale": Settings.text_scale,
		"display_server": DisplayServer.get_name(), "phase": game.phase,
		"continue_visible": game.ui.continue_btn != null and game.ui.continue_btn.is_visible_in_tree(),
		"viewer_visible": game.ui.viewer.visible, "viewer_locked": game.ui._viewer_locked,
		"first_result": game.sim.first_result, "combined": game.sim.combined(),
		"selection": game.sim.selection_report(), "note": game.ui.viewer_note.text}
	var file := FileAccess.open(out.path_join(name + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt, "  ") + "\n")
	print("saved ", out.path_join(name + ".png"))


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	out = args[0]
	stage = args[1]
	mode = args[2]
	root.size = Vector2i(int(args[4]), int(args[5]))
	Settings.language = args[3]
	Settings.text_scale = 1.2 if args[3] == "ko" else 1.0
	assert(Settings.save_settings() == OK, "cannot save isolated capture settings")
	L.apply(args[3])
	Checkpoint.force_enabled = true
	var story := root.get_node("Story")
	var main_script = load("res://scripts/main.gd")
	if mode == "before":
		Checkpoint.clear()
		story.from_prologue = true
		story.prologue_done = true
		story.departure_done = true
		story.bet_1917 = {"pick": 1, "sure": 2, "ashby": 1, "year": 1917}
		main_script.next_seed = 77
	assert(change_scene_to_file("res://scenes/main.tscn") == OK, "cannot open main scene")
	await _until(func(): return current_scene != null and current_scene.ui != null)
	var game = current_scene
	if mode == "before":
		game.sim.drive_wound = true
		game.sim.drive_rate_checked = true
		game.sim.drive_error = 0.025
		game.sim.plates_delivered = 2
		for exposure in [[100.0, 17.0, 0.12], [220.0, 35.0, 0.4]]:
			game.sim.open_shutter(exposure[0])
			game.sim.accumulate(exposure[1], exposure[2])
			game.sim.close_shutter()
		game.plate_changed = true
		await game._begin_night()
		_dialogue(game)
		game._interact("oxford_case")
		_dialogue(game)
		game._interact("departure_workbook")
		_dialogue(game)
		game._interact("measure")
		_dialogue(game, {"rule": 0, "bet": 2, "bet_sure": 1, "bet_keep": 3})
		_include(game, 0, true)
		game.ui.reading_set.emit(0, game.sim.reading_for_value(game.sim.plates[0].value))
		if stage == "reselected":
			_include(game, 1, true)
			game.ui.reading_set.emit(1, game.sim.reading_for_value(game.sim.plates[1].value))
			game.ui.measure_btn.pressed.emit()
			game.ui.reselect_btn.pressed.emit()
			_include(game, 1, false)
			game.ui.measure_btn.pressed.emit()
			_dialogue(game, {"reselect_reason": 1})
			assert(game.sim.first_result.n == 2 and game.sim.combined().n == 1,
				"capture must show first result and a changed selection")
		var file := FileAccess.open(out.path_join(stage + "-expected.save"), FileAccess.WRITE)
		file.store_var(game.sim.darkroom_state(), false)
		file.close()
		await _frame(game, stage + "-before-quit")
	else:
		assert(game.ui.continue_btn != null and game.ui.continue_btn.has_focus(), "cold title must offer Continue")
		await _frame(game, stage + "-title-continue")
		game.ui.continue_btn.pressed.emit()
		await _until(func(): return current_scene != null and current_scene.phase == main_script.Phase.NIGHT)
		game = current_scene
		var file := FileAccess.open(out.path_join(stage + "-expected.save"), FileAccess.READ)
		assert(game.sim.darkroom_state() == file.get_var(false), "Continue changed the captured simulation state")
		assert(game.ui.viewer.visible and game.ui._viewer_locked == (stage == "reselected"),
			"Continue must restore the unlocked or measured viewer")
		await _frame(game, stage + "-after-continue")
	game.stop_all_audio()
	print("capture complete: ", stage, " ", mode)
	quit()
