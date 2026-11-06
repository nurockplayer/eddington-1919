extends SceneTree
## Conversion arc C: the plate's value comes from the player's micrometer
## setting, not from the generated value. Drives the real viewer and the real
## measure path through main.gd.
## Run: godot --headless --path . --script res://tests/test_micrometer.gd

const Sim := preload("res://scripts/eclipse_sim.gd")
const Render := preload("res://scripts/plate_render.gd")
const Judgment := preload("res://scripts/judgment.gd")

var failures := 0
var checks := 0


func _initialize() -> void:
	_run.call_deferred()


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL: ", msg)


func _plate(number: int, value: float, sigma := 0.1, included := true) -> Dictionary:
	return {"index": number - 1, "number": number, "start": 10.0 * number, "duration": 6.0, "sunlit": false,
		"stars": 7, "quality": "good", "trail": 0.1, "fog": 0.0,
		"included": included, "usable": true, "value": value, "sigma": sigma}


## A real main scene in NIGHT with real plate textures, viewer open.
func _new_game(values: Array) -> Node:
	load("res://scripts/main.gd")._ensure_inputs()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.phase = game.Phase.NIGHT
	game.sim.rule_id = "strict"
	for i in values.size():
		game.sim.plates.append(_plate(i + 1, values[i]))
		game.plate_textures.append(Render.render(game.sim, game.sim.plates[-1]))
	game.ui.hide_title()
	game._open_viewer()
	await process_frame
	return game


func _read_plate(game: Node, i: int, value: float) -> void:
	var ui = game.ui
	ui._select_plate(i, game.plate_textures[i], false)
	ui.set_micrometer_reading(game.sim.reading_for_value(value))
	ui.mic_record_btn.pressed.emit()


func _finish(game: Node) -> void:
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _button(index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _run() -> void:
	print("mic: 1 new game")
	# 1. A careful reading at the true displacement reproduces the plate's value.
	var game := await _new_game([1.75, 1.60])
	print("mic: 1 opened")
	var ui = game.ui
	ui.mic_btn.button_pressed = true
	check(ui.micrometer_on and ui.mic_row.is_visible_in_tree() and ui.mic_note.is_visible_in_tree(),
		"micrometer toggle shows the record row and the exaggeration note")
	check(ui.mic_note.text == "位移為示意放大；真實的位移比一個星點還小得多。", "exaggeration note is verbatim")
	_read_plate(game, 0, 1.75)
	check(game.sim.plates[0].read and is_equal_approx(float(game.sim.plates[0].reading), game.sim.reading_for_value(1.75)),
		"recording stores the crosshair position as the plate's reading")
	check(ui.mic_readout.text == "讀數：%.2f 格" % ui.micrometer_px, "readout shows the setting in 格")
	_read_plate(game, 1, 1.60)
	ui.measure_btn.pressed.emit()
	await process_frame
	check(game.sim.measured and game.sim.included_usable().size() == 2, "both read plates are measured")
	check(ui.chart.rows.size() == 2, "chart gets one row per read plate (%d)" % ui.chart.rows.size())
	check(absf(ui.chart.rows[0].value - 1.75) <= 0.01, "true reading reproduces plate 1 value (%.4f)" % ui.chart.rows[0].value)
	check(absf(ui.chart.rows[1].value - 1.60) <= 0.01, "true reading reproduces plate 2 value (%.4f)" % ui.chart.rows[1].value)
	check(ui.chart.rows[0].sigma > 0.1, "setting error widens the plate error (%.3f)" % ui.chart.rows[0].sigma)
	await _finish(game)
	print("mic: 1 done")

	# 2. A careless setting moves the value by exactly the amount the crosshair
	#    moved, converted back through the drawn exaggeration.
	print("mic: 2 new game")
	var game2 := await _new_game([1.75])
	print("mic: 2 opened")
	var ui2 = game2.ui
	var per_px: float = game2.sim.star_offsets[0].length() / Render.EXAGGERATION
	var true_px: float = game2.sim.reading_for_value(1.75)
	ui2.mic_btn.button_pressed = true
	ui2.set_micrometer_reading(true_px + 2.0)
	ui2.mic_record_btn.pressed.emit()
	ui2.measure_btn.pressed.emit()
	await process_frame
	check(ui2.chart.rows.size() == 1, "careless plate still produces a row")
	check(absf(ui2.chart.rows[0].value - (1.75 + 2.0 * per_px)) <= 0.01,
		"2.0 px past the true position raises the value by 2.0·%.4f″ (%.4f vs %.4f)"
			% [per_px, ui2.chart.rows[0].value, 1.75 + 2.0 * per_px])
	check(absf(game2.sim.combined().value - ui2.chart.rows[0].value) <= 0.01,
		"the combination uses the reader's value, not the generated one (%.4f vs %.4f)"
			% [game2.sim.combined().value, ui2.chart.rows[0].value])
	await _finish(game2)
	print("mic: 2 done")

	# 3. An included plate without a reading does not count, and the note says so.
	print("mic: 3 new game")
	var game3 := await _new_game([1.75, 1.50])
	print("mic: 3 opened")
	var ui3 = game3.ui
	ui3.mic_btn.button_pressed = true
	_read_plate(game3, 0, 1.75)
	ui3.measure_btn.pressed.emit()
	await process_frame
	check(game3.sim.included_usable().size() == 1 and ui3.chart.rows.size() == 1,
		"included but unread plate stays out of the chart")
	check(ui3.viewer_note.text.contains("第2號還沒讀數，不會算進去。"), "note names the unread plate")
	check(is_equal_approx(game3.sim.combined().value, 1.75), "combination uses only the read plate")
	await _finish(game3)
	print("mic: 3 done")

	# 4. Measuring with no readings at all still completes, with no value.
	print("mic: 4 new game")
	var game4 := await _new_game([1.75, 1.50])
	print("mic: 4 opened")
	var ui4 = game4.ui
	ui4.measure_btn.pressed.emit()
	await process_frame
	check(game4.sim.measured and game4.sim.combined().n == 0 and ui4.chart.rows.is_empty(),
		"a measurement with no readings completes with no value")
	check(ui4.viewer_note.text.contains("第1號還沒讀數") and ui4.viewer_note.text.contains("第2號還沒讀數"),
		"the no-value note names every unread plate")
	await _finish(game4)
	print("mic: 4 done")

	# 5. Readings survive 重新選片.
	print("mic: 5 new game")
	var game5 := await _new_game([1.75, 1.60])
	print("mic: 5 opened")
	var ui5 = game5.ui
	ui5.mic_btn.button_pressed = true
	_read_plate(game5, 0, 1.75)
	_read_plate(game5, 1, 1.60)
	ui5.measure_btn.pressed.emit()
	await process_frame
	ui5.reselect_btn.pressed.emit()
	await process_frame
	check(not game5.sim.measured, "reselect unlocks the viewer")
	ui5._select_plate(1, game5.plate_textures[1], false)
	check(game5.sim.plates[1].read and is_equal_approx(float(game5.sim.plates[1].reading), game5.sim.reading_for_value(1.60)),
		"reselection keeps the recorded reading")
	ui5.measure_btn.pressed.emit()
	await process_frame
	check(not ui5.dialog_active() and game5.sim.measured, "unchanged reselection measures again without a reason prompt")
	check(ui5.chart.rows.size() == 2, "both readings still count after reselection")
	await _finish(game5)
	print("mic: 5 done")

	# 6. D-pad moves the crosshair and A records, through the real input path.
	print("mic: 6 new game")
	var game6 := await _new_game([1.75])
	print("mic: 6 opened")
	var ui6 = game6.ui
	ui6.mic_btn.button_pressed = true
	for i in 4:
		await _button(JOY_BUTTON_DPAD_RIGHT)
	check(is_equal_approx(ui6.micrometer_px, 1.0), "four D-pad presses move the crosshair 1.00 格 (%.2f)" % ui6.micrometer_px)
	await _button(JOY_BUTTON_A)
	check(game6.sim.plates[0].read and is_equal_approx(float(game6.sim.plates[0].reading), 1.0),
		"A records the crosshair position as the reading")
	await _finish(game6)
	print("mic: 6 done")

	# 7. Turning on the micrometer recentres an already-open loupe on the reference star.
	print("mic: 7 new game")
	var game7 := await _new_game([1.75])
	var ui7 = game7.ui
	ui7.loupe_btn.button_pressed = true
	ui7._show_loupe(Vector2(100000.0, 100000.0))
	var half: Vector2 = ui7._plate_texture.get_size() * 0.5
	var expected_center: Vector2 = ui7.loupe_start.clamp(half * 0.5, ui7._plate_texture.get_size() - half * 0.5)
	ui7._set_micrometer(true)
	check(ui7._loupe_center == expected_center,
		"micrometer recentres an active loupe on the reference star (%s vs %s)" % [ui7._loupe_center, expected_center])
	await _finish(game7)
	print("mic: 7 done")

	# 8. Corroboration uses recorded readings and excludes included unread plates.
	print("mic: 8 new game")
	var game8 := await _new_game([1.0, 2.5])
	for i in 2:
		game8.sim.plates[i].read = true
		game8.sim.plates[i].reading = game8.sim.reading_for_value(1.75)
	var agree_readings: Dictionary = Judgment.grade(game8.sim, Judgment.TELEGRAMS[0].id, Judgment.REASONS[0].id)
	check(_has_line(agree_readings, "互相印證"), "agreeing readings corroborate despite differing hidden values")
	await _finish(game8)
	print("mic: 8 done")

	print("mic: 9 new game")
	var game9 := await _new_game([1.75, 1.75])
	game9.sim.plates[0].read = true
	game9.sim.plates[0].reading = game9.sim.reading_for_value(1.0)
	game9.sim.plates[1].read = true
	game9.sim.plates[1].reading = game9.sim.reading_for_value(2.5)
	var disagree_readings: Dictionary = Judgment.grade(game9.sim, Judgment.TELEGRAMS[0].id, Judgment.REASONS[0].id)
	check(not _has_line(disagree_readings, "互相印證"), "disagreeing readings do not corroborate despite matching hidden values")
	await _finish(game9)
	print("mic: 9 done")

	print("mic: 10 new game")
	var game10 := await _new_game([1.75, 1.75])
	game10.sim.plates[0].read = true
	game10.sim.plates[0].reading = game10.sim.reading_for_value(1.75)
	var unread_grade: Dictionary = Judgment.grade(game10.sim, Judgment.TELEGRAMS[0].id, Judgment.REASONS[0].id)
	check(not _has_line(unread_grade, "互相印證"), "included unread plate cannot corroborate")
	check(_has_line(unread_grade, "只有一張好片"), "a single read good plate gets the single-plate line")
	await _finish(game10)
	print("mic: 10 done")

	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _has_line(grade: Dictionary, phrase: String) -> bool:
	for line in grade.lines:
		if line.contains(phrase):
			return true
	return false
