extends SceneTree
## Chapter checkpoints: one automatic file per chapter, the title's 繼續 button and
## the ending that clears it. Run: godot --headless --path . --script res://tests/test_checkpoint.gd

const StoryScript := preload("res://scripts/story.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func settle(frames := 4) -> void:
	for i in frames:
		await process_frame


func _wait_for(cond: Callable, seconds: float) -> bool:
	var deadline := Time.get_ticks_msec() + int(seconds * 1000.0)
	while not cond.call() and Time.get_ticks_msec() < deadline:
		await process_frame
	return cond.call()


func _pad(index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _run() -> void:
	Checkpoint.force_enabled = true
	Checkpoint.clear()
	var story := root.get_node("Story")
	story.reset()
	_check_round_trip(story)
	_check_guard(story)
	_check_plate(story)
	_check_peek()
	_check_enabled()
	_check_automation_leaves_checkpoints_alone()
	await _check_title(story)
	await _check_ending_clear(story)
	Checkpoint.clear()
	check(not FileAccess.file_exists(Checkpoint.path()), "the suite leaves no checkpoint file")
	Checkpoint.force_enabled = false
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _fill(story) -> void:
	story.runs.assign([
		{"seed": 1919, "score": 1.5, "readings": [1.75, 2],
			"meta": {"nested": {"name": "a", "vals": [1, 2.5]}}},
		{"seed": 7, "score": 0.0, "readings": [3.5],
			"meta": {"nested": {"name": "b", "vals": [3, 4.25]}}},
	])
	story.from_prologue = true
	story.prologue_done = true
	story.clues = {"a": 1, "b": {"c": [1, 2.5]}}
	story.report = {"sigmas": [0.5, 1.25], "verdict": "strict"}
	story.plan = ["one", 2, 3.5]
	story.kit_choice = 2
	story.want = 1
	story.kit_first = 1
	story.trial_note = 2
	story.exam = {"q1": 1, "q2": 0, "box": 2, "box_light": 1}
	story.bet = {"pick": 2, "sure": 1, "ashby": 0, "year": 1919, "value": 1.9, "n": 3}
	story.bet_1917 = {"pick": 1, "sure": 0, "ashby": 1, "year": 1917, "value": 1.8, "n": 4}
	story.orrery = {"neptune": 1, "halley": 0, "mercury": 1}
	story.mercury_suspect = 2
	story.sky_promise = 1
	story.bond_tone = "warm"
	story.slip_fix = 1
	story.departure_done = true
	story.epilogue_done = true
	story.ending_plate_caption = "1919 年 10 月"


func _check_round_trip(story) -> void:
	_fill(story)
	var expected: Dictionary = story.to_save()
	Checkpoint.save("principe")
	check(FileAccess.file_exists(Checkpoint.path()), "a checkpoint writes its file")
	check(Checkpoint.peek() == "principe", "peek names the saved chapter")
	story.reset()
	check(story.clues.is_empty() and story.runs.is_empty(), "reset wipes the state before the restore")
	check(Checkpoint.restore() == "principe", "restore returns the chapter")
	for key in StoryScript.SAVED:
		check(typeof(story.get(key)) == typeof(expected[key]) and story.get(key) == expected[key],
			"%s comes back with its type and value" % key)
	check(story.departure_done and story.epilogue_done, "the chapter flags come back true")
	check(typeof(story.runs[0]["seed"]) == TYPE_INT and typeof(story.runs[0]["score"]) == TYPE_FLOAT,
		"a run keeps int and float values")
	check(story.runs[1]["meta"]["nested"]["vals"][1] == 4.25
		and typeof(story.runs[1]["meta"]["nested"]["vals"][1]) == TYPE_FLOAT,
		"a nested float in a run stays a float")
	check(typeof(story.bet["value"]) == TYPE_FLOAT and typeof(story.bet["n"]) == TYPE_INT,
		"a bet keeps int and float values")


func _check_guard(story) -> void:
	var properties: Array = story.get_script().get_script_property_list()
	check(properties.size() > 10, "the Story script lists its fields")
	for prop in properties:
		# The first entry is the script itself; only the script variables are fields.
		if int(prop.usage) & PROPERTY_USAGE_SCRIPT_VARIABLE == 0:
			continue
		var field := str(prop.name)
		check(StoryScript.SAVED.has(field) or field == "ending_plate",
			"Story field %s is saved or is the plate" % field)


func _check_plate(story) -> void:
	var image := Image.create(3, 2, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.4, 0.5, 0.6))
	story.ending_plate = ImageTexture.create_from_image(image)
	Checkpoint.save("departure")
	story.reset()
	check(Checkpoint.restore() == "departure", "a checkpoint with a plate restores")
	check(story.ending_plate != null, "a saved plate comes back")
	if story.ending_plate != null:
		check(story.ending_plate.get_size() == Vector2(3, 2),
			"the plate keeps its size (%s)" % story.ending_plate.get_size())
	story.ending_plate = null
	Checkpoint.save("departure")
	story.reset()
	Checkpoint.restore()
	check(story.ending_plate == null, "a null plate stays null")


func _check_peek() -> void:
	Checkpoint.clear()
	check(Checkpoint.peek() == "", "no file peeks empty")
	var file := FileAccess.open(Checkpoint.path(), FileAccess.WRITE)
	file.store_buffer(PackedByteArray([1, 2, 3, 4, 5, 6, 7, 8]))
	file.close()
	check(Checkpoint.peek() == "", "garbage bytes peek empty")
	file = FileAccess.open(Checkpoint.path(), FileAccess.WRITE)
	file.close()
	check(Checkpoint.peek() == "", "an empty file peeks empty")
	file = FileAccess.open(Checkpoint.path(), FileAccess.WRITE)
	file.store_var({"version": 0, "chapter": "principe", "story": {}}, false)
	file.close()
	check(Checkpoint.peek() == "", "another version peeks empty")
	check(Checkpoint.restore() == "", "a rejected file restores nothing")
	Checkpoint.clear()


func _check_automation_leaves_checkpoints_alone() -> void:
	Checkpoint.save("principe")
	var test_file := Checkpoint.path()
	check(test_file.ends_with("checkpoint.test.save"), "a forced suite uses its own file")
	Checkpoint.force_enabled = false
	check(Checkpoint.path().ends_with("/checkpoint.save") and Checkpoint.path() != test_file, "the real path is a different file")
	check(Checkpoint.peek() == "", "under --script a checkpoint does not show")
	check(Checkpoint.restore() == "", "under --script a checkpoint does not restore")
	Checkpoint.clear()
	Checkpoint.force_enabled = true
	check(FileAccess.file_exists(Checkpoint.path()) and Checkpoint.peek() == "principe", "a forced-off clear deletes nothing")
	Checkpoint.clear()


func _check_enabled() -> void:
	Checkpoint.force_enabled = false
	check(OS.get_cmdline_args().has("--script"), "the suite itself runs under --script")
	check(not Checkpoint.enabled(), "a --script suite never writes a checkpoint")
	Checkpoint.force_enabled = true


func _open_title() -> bool:
	var started := change_scene_to_file("res://scenes/main.tscn") == OK
	var ready: bool = await _wait_for(func(): return current_scene != null and current_scene.scene_file_path == "res://scenes/main.tscn" and current_scene.ui != null, 20.0)
	await settle()
	return started and ready


## The continued scene is up: Príncipe is the same path as the title, so its phase tells.
func _arrived(scene: String) -> bool:
	if current_scene == null or current_scene.scene_file_path != scene:
		return false
	if scene == "res://scenes/main.tscn":
		return current_scene.phase != current_scene.Phase.TITLE
	return true


func _check_title(story) -> void:
	story.reset()
	check(await _open_title(), "the title loads")
	var ui = current_scene.ui
	check(ui.continue_btn == null, "no checkpoint: no continue button")
	check(root.gui_get_focus_owner() == ui.prologue_btn, "no checkpoint: focus starts on the prologue button")
	await _case(story, "departure", "res://scenes/departure.tscn")
	await _case(story, "principe", "res://scenes/main.tscn")
	await _case(story, "epilogue", "res://scenes/epilogue.tscn")


func _case(story, chapter: String, scene: String) -> void:
	story.reset()
	story.prologue_done = true
	story.departure_done = true
	story.epilogue_done = chapter == "epilogue"
	story.runs.assign([{"seed": 1919, "score": 1.5, "meta": {"vals": [1, 2.5]}}])
	story.bet = {"pick": 2, "sure": 1, "ashby": 0, "year": 1919, "value": 1.9}
	story.ending_plate_caption = "1919 年 10 月"
	Checkpoint.save(chapter)
	check(Checkpoint.peek() == chapter, "the %s checkpoint is saved" % chapter)
	story.reset()
	check(await _open_title(), "the title loads for %s" % chapter)
	var ui = current_scene.ui
	check(ui.continue_btn != null, "with a %s checkpoint the title offers it" % chapter)
	if ui.continue_btn == null:
		return
	check(ui.prologue_btn.get_parent().get_child(0) == ui.continue_btn, "continue is the first button")
	check(ui.continue_btn.has_focus(), "with a %s checkpoint focus lands on continue" % chapter)
	check(ui.continue_btn.text == Checkpoint.label(chapter), "continue names the %s chapter" % chapter)
	await _pad(JOY_BUTTON_A)
	var changed: bool = await _wait_for(_arrived.bind(scene), 20.0)
	check(changed, "A on the checkpoint opens %s" % scene)
	await settle()
	if not changed:
		return
	if chapter == "principe":
		check(not current_scene.ui.title_panel.visible, "Príncipe resumes in the game, not on the title")
		check(current_scene.phase != current_scene.Phase.TITLE, "Príncipe leaves the title phase")
		check(story.departure_done, "the restored story keeps departure_done for the epilogue check")
	elif chapter == "departure":
		var opened: bool = await _wait_for(func(): return current_scene._pending == "opening", 20.0)
		check(opened, "the departure chapter reaches its opening")
	elif chapter == "epilogue":
		check(story.runs.size() == 1, "the epilogue checkpoint keeps the run")
		check(story.epilogue_done, "the epilogue checkpoint keeps epilogue_done")


func _run_snapshot() -> Dictionary:
	return {
		"seed": 1919,
		"combined": {"n": 0, "value": 0.0, "sigma": 0.0},
		"grade": {"title": "測試結局", "lines": [], "score": 0, "clean": false},
		"first_result": null,
		"plate_counts": {"good": 0, "poor": 0, "unusable": 0},
		"plate_total": 0, "plates_available": 0,
		"telegram_id": "cloud", "reason_id": "test", "reason_text": "",
		"rule_id": "", "bet": {}, "bet_pick": -1,
		"departure_kit": false, "kit_line": "",
	}


func _check_ending_clear(story) -> void:
	story.reset()
	check(await _open_title(), "the title loads before the ending")
	var game = current_scene
	story.runs.assign([_run_snapshot()])
	story.bet = {}
	Checkpoint.save("epilogue")
	check(FileAccess.file_exists(Checkpoint.path()), "a checkpoint exists before the ending")
	game._run_record_index = 0
	game._came_from_departure = false
	game._show_ending()
	check(FileAccess.file_exists(Checkpoint.path()), "a 1919-only ending keeps the story's checkpoint")
	game._came_from_departure = true
	game._show_ending()
	check(not FileAccess.file_exists(Checkpoint.path()), "the story's ending clears the checkpoint")
	check(Checkpoint.peek() == "", "nothing is left to continue after the ending")
