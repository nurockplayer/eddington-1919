extends SceneTree
## Conversion arc C: the plate's value comes from the player's micrometer
## setting, not from the generated value. Drives the real viewer and the real
## measure path through main.gd.
## Run: godot --headless --path . --script res://tests/test_micrometer.gd

const Settings := preload("res://scripts/settings.gd")
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
func _new_game(values: Array, with_reference := false) -> Node:
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
	if with_reference:
		game.comparison_tex = Render.render(game.sim, null)
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


func _comparator_press(pad: bool, code: Key, joy: JoyButton) -> void:
	if pad:
		await _button(joy)
	else:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = true
		root.push_input(event)
		await process_frame
		event.pressed = false
		root.push_input(event)
		await process_frame


func _check_comparator_focus(pad: bool) -> void:
	var game := await _new_game([1.75, 1.60], true)
	await process_frame
	var ui = game.ui
	var device := "pad" if pad else "keyboard"
	var records: Array[int] = []
	ui.reading_set.connect(func(i: int, _px: float): records.append(i))
	check(ui.thumbs.get_child(0).has_focus(), device + ": opening the table focuses the reference thumbnail")
	await _comparator_press(pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
	var focused := root.gui_get_focus_owner() as Button
	check(ui.thumbs.get_child(1).has_focus(), device + ": navigate to the first eclipse plate (focus %s at %s)"
		% [focused.accessibility_name + focused.text, focused.get_global_rect()])
	await _comparator_press(pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui._viewer_sel == 0 and ui.blink_btn.has_focus() and not ui.blink_btn.disabled,
		device + ": selecting the first plate focuses legal Blink")
	if not ui.blink_btn.has_focus():
		await _finish(game)
		return
	await _comparator_press(pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui.blink_btn.has_focus() and ui.blink_btn.button_pressed and ui.blink_label.is_visible_in_tree(),
		device + ": blink starts with focus on Blink")
	await _comparator_press(pad, KEY_ENTER, JOY_BUTTON_A)
	await _comparator_press(pad, KEY_DOWN, JOY_BUTTON_DPAD_DOWN)
	check(ui.mic_btn.has_focus(), device + ": navigate from Blink to the micrometer")
	await _comparator_press(pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui.mic_record_btn.has_focus() and ui.mic_record_btn.is_visible_in_tree(),
		device + ": opening the micrometer focuses visible Record")
	await _comparator_press(pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
	await _comparator_press(pad, KEY_ENTER, JOY_BUTTON_A)
	check(records == [0] and game.sim.plates[0].read and ui.thumbs.get_child(2).has_focus(),
		device + ": one confirm records once and focuses the next unread plate")
	await _comparator_press(pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui._viewer_sel == 1 and ui.mic_record_btn.has_focus() and records == [0],
		device + ": selecting plate two focuses Record without recording")
	await _comparator_press(pad, KEY_ESCAPE, JOY_BUTTON_B)
	check(ui.viewer.visible and not ui.micrometer_on and ui.mic_btn.has_focus() and records == [0],
		device + ": backing out restores the visible micrometer toggle")
	await _comparator_press(pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui.mic_record_btn.has_focus() and ui._viewer_sel == 1 and records == [0],
		device + ": resuming restores Record on the same plate")
	await _comparator_press(pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
	await _comparator_press(pad, KEY_ENTER, JOY_BUTTON_A)
	check(records == [0, 1] and game.sim.plates[1].read and ui.measure_btn.has_focus(),
		device + ": second confirm records once and focuses Measure")
	await _finish(game)


func _check_feel() -> void:
	var game := await _new_game([0.87, 1.75])
	var ui = game.ui
	ui.mic_btn.button_pressed = true
	var saved_window := root.size
	var saved_canvas := root.content_scale_size
	root.content_scale_size = Vector2i(1600, 900)
	for window in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.size = window
		await process_frame
		await process_frame
		check(root.get_visible_rect().size.is_equal_approx(Vector2(1600, 900)),
			"%s window uses the 1600x900 canvas" % window)
		for zoom in [false, true]:
			ui._set_loupe(zoom)
			var star: Vector2 = ui._mic_star_point()
			var one_px: Vector2 = ui._plate_to_local(star + ui._mic_dir()) - ui._plate_to_local(star)
			var pitch: float = ui._mic_window_unit_px(one_px)
			var context := "%s loupe=%s" % [window, zoom]
			check(is_equal_approx(pitch, one_px.length() * float(window.y) / 900.0),
				"ruler pitch includes window/canvas scaling: " + context)
			var tick_step: int = ui._mic_tick_step(pitch)
			var label_step: int = maxi(10, ui._mic_tick_step(pitch, 16.0))
			check(pitch * tick_step >= 5.0, "neighbouring ticks >= 5 window px: " + context)
			check(tick_step in [1, 2, 5, 10, 20, 50, 100], "1-2-5 decimal tick step: " + context)
			check(label_step in [5, 10, 20, 50, 100] and label_step % tick_step == 0,
				"round decimal numbered ticks: " + context)
			for unit in range(-14, 71):
				if unit % tick_step == 0 and unit % label_step == 0:
					check(unit % 5 == 0, "numbered value is a multiple of five: %s %s" % [unit, context])
			for reading in [0.0, 6.0, 23.0]:
				ui.set_micrometer_reading(reading)
				ui.mic_overlay.queue_redraw()
				await process_frame
	root.content_scale_size = saved_canvas
	root.size = saved_window
	ui._set_loupe(true)
	await process_frame
	var saved_step: float = Settings.mic_step
	for step in Settings.MIC_STEPS:
		Settings.mic_step = step
		for fine in [false, true]:
			ui.set_micrometer_reading(10.0)
			var delta: float = (0.05 if fine else 0.25) * step
			ui._nudge_micrometer(1.0, fine)
			check(is_equal_approx(ui.micrometer_px, 10.0 + delta),
				"scaled positive nudge step=%s fine=%s" % [step, fine])
			ui._nudge_micrometer(-1.0, fine)
			check(is_equal_approx(ui.micrometer_px, 10.0),
				"scaled negative nudge step=%s fine=%s" % [step, fine])
	Settings.mic_step = 1.0
	var signatures: Array = []
	for plate in 2:
		ui._select_plate(plate, game.plate_textures[plate], false)
		ui.set_micrometer_reading(0.0)
		ui.viewer_sfx_log.clear()
		ui._mic_last_tick_ms = Time.get_ticks_msec() - 50
		ui.set_micrometer_reading(0.0)
		ui.set_micrometer_reading(-1.0)
		check(ui.viewer_sfx_log.is_empty(), "unchanged/clamped reading is silent")
		var started := Time.get_ticks_msec()
		ui._nudge_micrometer(1.0, false)
		check(ui.viewer_sfx_log == ["tick"], "one reading change emits one tick")
		for i in 9:
			ui._nudge_micrometer(1.0, false)
		check(Time.get_ticks_msec() - started < 50, "ten nudges run within 50 ms")
		check(ui.viewer_sfx_log == ["tick"], "ten changes within 50 ms emit one tick")
		var sound: AudioStreamPlayer = ui._viewer_sfx["tick"]
		check(sound.stream == ui._viewer_sfx["mark"].stream and sound.playing,
			"tick plays the existing short click sample")
		check(sound.pitch_scale == 1.0 and sound.volume_db == -11.0 and sound.bus == "SFX",
			"tick uses fixed quiet volume, pitch and SFX bus")
		signatures.append([ui.viewer_sfx_log.duplicate(), sound.stream, sound.pitch_scale,
			sound.volume_db, ui._mic_star_point(), ui._mic_dir()])
		ui._mic_last_tick_ms = Time.get_ticks_msec() - 50
		ui._nudge_micrometer(1.0, true)
		check(ui.viewer_sfx_log == ["tick", "tick"], "tick resumes after the 50 ms interval")
		# Queue the actual draw path for both crosshair sizes on both real plates.
		for large in [false, true]:
			Settings.mic_large_cross = large
			ui.mic_overlay.queue_redraw()
			await process_frame
	check(signatures[0] == signatures[1],
		"different true shifts with identical nudges have identical ticks and scale anchors")
	var source := FileAccess.get_file_as_string("res://scripts/ui.gd")
	for method in ["set_micrometer_reading", "_draw_micrometer", "_mic_star_point", "_mic_dir", "_plate_geometry", "_plate_to_local", "_viewer_sound"]:
		var body := source.get_slice("func " + method + "(", 1).get_slice("\nfunc ", 0)
		check(not body.is_empty() and not body.contains("_viewer_plates[")
			and not body.contains("measurement_of") and not body.contains(".value")
			and not body.contains("reading_for_value"), method + " does not read the plate's true shift")
	Settings.mic_step = saved_step
	Settings.mic_large_cross = false
	await _finish(game)


func _check_two_settings(gap: float) -> void:
	var game := await _new_game([1.75, 1.60])
	var ui = game.ui
	ui.mic_btn.button_pressed = true
	var compare: Button = ui.get("mic_compare_btn")
	check(compare != null and compare.is_visible_in_tree(), "editable plate offers a second setting")
	if compare == null:
		await _finish(game)
		return
	var readings: Array[float] = []
	ui.reading_set.connect(func(_plate_index: int, reading: float): readings.append(reading))
	var second: float = game.sim.reading_for_value(1.75)
	var first := second + gap
	ui.set_micrometer_reading(first)
	await _button(JOY_BUTTON_DPAD_UP)
	check(compare.has_focus(), "the second setting is reachable from Record")
	await _button(JOY_BUTTON_A)
	check(ui.micrometer_px == 0.0 and ui.mic_readout.is_visible_in_tree() and is_nan(ui._mic_second)
		and not ui.mic_first_btn.is_visible_in_tree() and not ui.mic_second_btn.is_visible_in_tree(),
		"the second pass starts at Oxford zero with both comparison marks hidden")
	ui.set_micrometer_reading(second)
	check(is_nan(ui._mic_second) and not ui.mic_record_btn.is_visible_in_tree()
		and readings.is_empty() and not game.sim.plates[0].get("read", false),
		"turning the second setting neither reveals the first nor records a reading")
	await _button(JOY_BUTTON_A)
	check(is_equal_approx(ui._mic_first, first) and is_equal_approx(ui._mic_second, second)
		and ui.mic_first_btn.is_visible_in_tree() and ui.mic_second_btn.is_visible_in_tree(),
		"Compare reveals both marks for a gap of %.2f divisions" % gap)
	await _button(JOY_BUTTON_DPAD_UP)
	await _button(JOY_BUTTON_A)
	check(is_equal_approx(ui.micrometer_px, first) and ui.mic_first_btn.button_pressed and readings.is_empty(),
		"choosing the first mark selects it without recording")
	await _button(JOY_BUTTON_DPAD_UP)
	await _button(JOY_BUTTON_A)
	check(ui.mic_record_btn.has_focus() and is_equal_approx(ui.micrometer_px, second)
		and ui.mic_second_btn.button_pressed and readings.is_empty(),
		"choosing the second mark brings the chosen setting to Record")
	await _button(JOY_BUTTON_A)
	check(readings == [second] and is_equal_approx(game.sim.plates[0].reading, second)
		and not ui.mic_second_btn.is_visible_in_tree(), "Record stores the chosen mark once")
	_read_plate(game, 1, 1.60)
	ui.measure_btn.pressed.emit()
	await process_frame
	check(readings.size() == 2 and ui.chart.rows.size() == 2 and absf(ui.chart.rows[0].value - 1.75) < 0.01,
		"the compared plate and the single-pass plate each contribute one result")
	ui.report_btn.grab_focus()
	await _button(JOY_BUTTON_A)
	check(ui._viewer_reporting and ui.dialog_active(), "both readings reach the existing report")
	await _finish(game)


func _run() -> void:
	for gap in [8.0, 0.05]:
		await _check_two_settings(gap)
	for pad in [false, true]:
		await _check_comparator_focus(pad)
	await _check_feel()
	# No exposures and unusable plates must still reach the no-results judgment.
	for only_unusable in [false, true]:
		var empty_game := await _new_game([])
		if only_unusable:
			var plate := _plate(1, 1.75)
			plate.stars = 4
			plate.quality = "unusable"
			plate.usable = false
			empty_game.sim.plates.append(plate)
			empty_game.plate_textures.append(Render.render(empty_game.sim, plate))
			empty_game._open_viewer()
		var empty_ui = empty_game.ui
		empty_ui.measure_btn.pressed.emit()
		await process_frame
		check(empty_game.sim.measured and empty_game.sim.included_usable().is_empty(),
			"no-results selection locks without a usable reading (unusable=%s)" % only_unusable)
		empty_ui.report_btn.grab_focus()
		await _button(JOY_BUTTON_A)
		check(empty_ui._viewer_reporting and empty_ui.dialog_active() and empty_game._pending == "judgment",
			"Report reaches no-results judgment (unusable=%s)" % only_unusable)
		await _finish(empty_game)
	print("mic: no-results reporting done")
	# Usable plates outside the selection must not block a no-results report.
	for only_unusable in [false, true]:
		var excluded_game := await _new_game([1.75, 1.50])
		excluded_game._on_plate_toggled(0, false)
		if only_unusable:
			excluded_game.sim.plates[1].usable = false
			excluded_game.sim.plates[1].quality = "unusable"
		else:
			excluded_game._on_plate_toggled(1, false)
		var excluded_ui = excluded_game.ui
		excluded_ui.measure_btn.pressed.emit()
		await process_frame
		excluded_ui.report_btn.grab_focus()
		await _button(JOY_BUTTON_A)
		check(excluded_ui._viewer_reporting and excluded_ui.dialog_active() and excluded_game._pending == "judgment",
			"no-usable selection reaches judgment with excluded usable plates (unusable=%s)" % only_unusable)
		await _finish(excluded_game)
	print("mic: excluded usable plates reporting done")

	print("mic: 1 new game")
	# 1. A careful reading at the true displacement reproduces the plate's value.
	var game := await _new_game([1.75, 1.60])
	print("mic: 1 opened")
	var ui = game.ui
	ui.mic_btn.button_pressed = true
	check(ui.micrometer_on and ui.mic_row.is_visible_in_tree() and ui.mic_note.is_visible_in_tree(),
		"micrometer toggle shows the record row and the shared note")
	check(ui.mic_note.text == "把十字線對準參考星，再按「記下讀數」。"
		and ui.mic_note.get_theme_color("font_color") == ui.ACCENT,
		"unread plate shows the alignment hint in accent in the shared note")
	_read_plate(game, 0, 1.75)
	check(ui.mic_note.text == "位移為示意放大；真實的位移比一個星點還小得多。"
		and ui.mic_note.get_theme_color("font_color") == ui.DIM,
		"recording restores the exaggeration note in dim")
	check(game.sim.plates[0].read and is_equal_approx(float(game.sim.plates[0].reading), game.sim.reading_for_value(1.75)),
		"recording stores the crosshair position as the plate's reading")
	check(ui.mic_readout.text == "讀數：%.2f 格" % ui.micrometer_px, "readout shows the setting in 格")
	_read_plate(game, 1, 1.60)
	ui.measure_btn.pressed.emit()
	await process_frame
	check(ui.viewer_steps.text.contains("② 測微器讀數 2/2") and ui.viewer_steps.text.contains("[b][color=#e5bd7d]③"), "all readings highlight the report step")
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

	# 4. Lock, try to report without readings, then read and report through input.
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
	check(ui4.viewer_steps.text.contains("② 測微器讀數 0/2") and ui4.viewer_steps.text.contains("[b][color=#e5bd7d]②"),
		"locking shows 0/2 and highlights reading")
	check(not ui4.report_btn.disabled, "zero readings keep Report enabled for gamepad focus")
	var sounds_before: Array = ui4.viewer_sfx_log.duplicate()
	ui4.report_btn.grab_focus()
	await _button(JOY_BUTTON_A)
	check(ui4.viewer.visible and not ui4._viewer_reporting and not ui4.dialog_active(),
		"zero-reading report stays in the editable viewer")
	check(ui4.viewer_note.text == "一張都還沒讀。選中的底片要用測微器讀過，才有數字可以報告。",
		"zero-reading report shows Eddington's refusal")
	check(ui4.viewer_sfx_log == sounds_before, "refusal plays no report sound")
	if not ui4._viewer_reporting:
		ui4.mic_btn.button_pressed = true
		check(not ui4.mic_record_btn.disabled and ui4.include_box.disabled,
			"locked selection still allows micrometer readings")
		var reduced_before: bool = Settings.reduced_motion
		Settings.reduced_motion = false
		await _button(JOY_BUTTON_DPAD_RIGHT)
		await _button(JOY_BUTTON_A)
		check(game4.sim.plates[0].get("read", false) and is_equal_approx(ui4.micrometer_px, 0.25),
			"D-pad and A record after selection is locked")
		check(ui4.thumbs.get_child(1).accessibility_name.contains("✓讀") and ui4.thumbs.get_child(1).modulate != Color.WHITE,
			"recording flashes the thumbnail read mark")
		get_processed_tweens().back().custom_step(0.4)
		check(ui4.thumbs.get_child(1).modulate == Color.WHITE, "thumbnail pulse returns to normal")
		check(ui4.viewer_steps.text.contains("② 測微器讀數 1/2"), "reading updates the strip to 1/2")
		check(ui4.viewer_note.text.contains("第2號還沒讀數，不會算進去。"), "partial reading keeps the not-counted note")
		Settings.reduced_motion = true
		_read_plate(game4, 0, 1.75)
		check(ui4.thumbs.get_child(1).accessibility_name.contains("✓讀") and ui4.thumbs.get_child(1).modulate == Color.WHITE,
			"reduced motion records the mark without a pulse")
		Settings.reduced_motion = reduced_before
		ui4.mic_btn.button_pressed = false
		ui4.report_btn.grab_focus()
		await _button(JOY_BUTTON_A)
		check(ui4._viewer_reporting and ui4.dialog_active() and game4._pending == "verdict",
			"one reading proceeds to Eddington with the other plate unread")
	await _finish(game4)
	print("mic: 4 done")

	# The first result follows readings on the locked selection until it changes.
	var snapshot_game := await _new_game([1.75, 1.50])
	var snapshot_ui = snapshot_game.ui
	snapshot_ui.measure_btn.pressed.emit()
	await process_frame
	snapshot_ui.mic_btn.button_pressed = true
	_read_plate(snapshot_game, 0, 1.75)
	check(snapshot_game.sim.first_result.n > 0,
		"locked reading updates first_result before reselection")
	var first_result: Dictionary = snapshot_game.sim.first_result.duplicate(true)
	snapshot_ui.reselect_btn.pressed.emit()
	await process_frame
	snapshot_game._on_plate_toggled(0, false)
	_read_plate(snapshot_game, 1, 1.50)
	snapshot_ui.measure_btn.pressed.emit()
	await process_frame
	check(snapshot_game._pending == "reselect_reason", "changed selection asks for a reselection reason")
	snapshot_game._on_dialogue_done({"reselect_reason": 0})
	await process_frame
	check(snapshot_game.sim.measured and snapshot_game.sim.reselected_after_seeing,
		"changed selection locks after its reason is recorded")
	check(snapshot_game.sim.first_result == first_result and first_result.n > 0
		and not is_equal_approx(snapshot_game.sim.first_result.value, snapshot_game.sim.combined().value),
		"reselection preserves the first locked reading instead of the new result")
	_read_plate(snapshot_game, 1, 1.60)
	check(snapshot_game.sim.first_result == first_result,
		"reading after reselection preserves the first result")
	await _finish(snapshot_game)
	print("mic: first-result snapshot done")

	# 4.1. Recorded evidence locks; changing it after reopening is a revision.
	var locked_game := await _new_game([1.75, 1.50])
	var locked_ui = locked_game.ui
	locked_ui.mic_btn.button_pressed = true
	_read_plate(locked_game, 0, 1.75)
	_read_plate(locked_game, 1, 1.50)
	locked_ui.measure_btn.pressed.emit()
	await process_frame
	var locked_reading: float = locked_game.sim.plates[0].reading
	var locked_result: Dictionary = locked_game.sim.combined().duplicate(true)
	var locked_first: Dictionary = locked_game.sim.first_result.duplicate(true)
	check(locked_game.sim.measured_readings == {
		1: locked_game.sim.plates[0].reading, 2: locked_game.sim.plates[1].reading},
		"Measure snapshots recorded readings by plate number")
	locked_ui._select_plate(0, locked_game.plate_textures[0], false)
	locked_ui.set_micrometer_reading(locked_reading + 2.0)
	check(is_equal_approx(locked_ui.micrometer_px, locked_reading + 2.0),
		"the crosshair can still move on a locked recorded plate")
	locked_ui.mic_record_btn.pressed.emit()
	check(locked_ui.mic_record_btn.disabled, "record is disabled on a locked recorded plate")
	check(locked_game.sim.plates[0].reading == locked_reading,
		"pressing record cannot overwrite a locked reading")
	check(locked_game.sim.combined() == locked_result, "locked record leaves combined evidence unchanged")
	locked_ui.reading_set.emit(0, locked_reading + 2.0)
	check(locked_game.sim.plates[0].reading == locked_reading,
		"main also rejects a reading signal for a locked recorded plate")
	locked_ui.reselect_btn.pressed.emit()
	await process_frame
	check(not locked_ui.mic_record_btn.disabled, "reselect enables recording an already-read plate")
	_read_plate(locked_game, 0, 1.25)
	check(locked_game.sim.plates[0].reading != locked_reading, "unlocked record changes the reading")
	locked_ui.measure_btn.pressed.emit()
	await process_frame
	check(not locked_ui.dialog_active() and locked_game._pending != "reselect_reason",
		"readings-only revision needs no selection reason")
	check(locked_game.sim.measured and locked_game.sim.reselected_after_seeing,
		"changed reading locks as a revision")
	check(locked_game.sim.first_result == locked_first, "readings-only revision preserves first_result")
	check(locked_ui.viewer_note.text.contains("第一次量"), "readings-only revision shows the first measurement")
	check(locked_game.sim.measured_readings[1] == locked_game.sim.plates[0].reading,
		"remeasurement snapshots the revised reading")
	await _finish(locked_game)

	var unread_game := await _new_game([1.75, 1.50])
	var unread_ui = unread_game.ui
	unread_ui.mic_btn.button_pressed = true
	_read_plate(unread_game, 0, 1.75)
	unread_ui.measure_btn.pressed.emit()
	await process_frame
	check(unread_ui.mic_record_btn.disabled, "locking immediately disables record on the read plate")
	unread_ui._select_plate(1, unread_game.plate_textures[1], false)
	check(not unread_ui.mic_record_btn.disabled, "selecting an unread locked plate enables record")
	_read_plate(unread_game, 1, 1.50)
	check(unread_game.sim.plates[1].get("read", false)
		and is_equal_approx(unread_game.sim.plates[1].reading, unread_game.sim.reading_for_value(1.50)),
		"a still-unread plate can be recorded while locked")
	check(unread_ui.mic_record_btn.disabled, "record disables after the locked plate's first reading")
	unread_ui.reselect_btn.pressed.emit()
	await process_frame
	unread_ui.measure_btn.pressed.emit()
	await process_frame
	check(unread_game.sim.measured and not unread_game.sim.reselected_after_seeing,
		"a new reading absent from the previous snapshot is not a revision")
	await _finish(unread_game)
	print("mic: 4.1 reading lock and revision done")

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
	check(not game5.sim.reselected_after_seeing, "identical readings and selection are not a revision")
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
