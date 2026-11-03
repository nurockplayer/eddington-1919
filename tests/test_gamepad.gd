extends SceneTree

const UI := preload("res://scripts/ui.gd")
const Prompts := preload("res://scripts/prompts.gd")
const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Plan := preload("res://scripts/cambridge/plan_board.gd")
const Checklist := preload("res://scripts/cambridge/departure_checklist.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
var checks := 0
var failures := 0


class WorldInputProbe extends Node:
	var pause_events := 0

	func _unhandled_input(event: InputEvent) -> void:
		if event.is_action_pressed("pause"):
			pause_events += 1


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func button(index: JoyButton) -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = index
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event.duplicate())
	await process_frame


func scroll_stick(value: float, frames := 6) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = JOY_AXIS_RIGHT_Y
	event.axis_value = value
	Input.parse_input_event(event.duplicate())
	Input.flush_buffered_events()
	for frame in frames:
		await process_frame
		await physics_frame
	event.axis_value = 0.0
	Input.parse_input_event(event.duplicate())
	Input.flush_buffered_events()
	await process_frame


func motion(axis: JoyAxis, value: float) -> void:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame


func _run() -> void:
	var main := load("res://scripts/main.gd")
	# Exercise desktop ui_right defaults even when the headless server omits them.
	var ui_stick := InputEventJoypadMotion.new()
	ui_stick.axis = JOY_AXIS_LEFT_X
	ui_stick.axis_value = 1.0
	if not InputMap.action_has_event("ui_right", ui_stick):
		InputMap.action_add_event("ui_right", ui_stick)
	main._ensure_inputs()
	# Derive the action names from the authored map so new actions cannot escape this check.
	var source := FileAccess.get_file_as_string("res://scripts/main.gd")
	var setup := source.get_slice("static func _ensure_inputs()", 1).get_slice("# ------------------------------------------------------------------ Environment", 0)
	var pattern := RegEx.new()
	pattern.compile('"([a-z_]+)": \\[')
	var actions := {}
	for hit in pattern.search_all(setup):
		actions[hit.get_string(1)] = true
	for action in actions:
		if action == "toggle_fullscreen":
			continue
		var has_pad := false
		for event in InputMap.action_get_events(action):
			has_pad = has_pad or event is InputEventJoypadButton or event is InputEventJoypadMotion
		check(has_pad, action + " has a gamepad binding")
		if action.begins_with("move_") or action.begins_with("look_") or action.begins_with("gamepad_look_"):
			check(is_equal_approx(InputMap.action_get_deadzone(action), 0.25), action + " has 0.25 deadzone")
	var count := InputMap.action_get_events("shutter").size()
	main._ensure_inputs()
	check(InputMap.action_get_events("shutter").size() == count, "chapter startup does not duplicate bindings")
	var ui := UI.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(ui)
	await process_frame
	check(root.gui_get_focus_owner() == ui.prologue_btn, "title focuses its first button")
	await button(JOY_BUTTON_DPAD_RIGHT)
	check(root.gui_get_focus_owner() == ui.start_btn, "D-pad navigates title buttons")
	check(Prompts.key("interact") == "A 鍵", "joypad switches prompts")
	var keyboard := InputEventKey.new()
	keyboard.keycode = KEY_W
	keyboard.pressed = true
	root.push_input(keyboard)
	check(Prompts.key("interact") == "E", "keyboard restores prompts")
	keyboard.pressed = false
	root.push_input(keyboard)
	var motion := InputEventJoypadMotion.new()
	motion.axis = JOY_AXIS_RIGHT_X
	motion.axis_value = 0.5
	Input.parse_input_event(motion.duplicate())
	await process_frame
	check(Prompts.joypad, "analog input switches prompts")
	check(Input.get_axis("look_left", "look_right") > 0.0 and Input.get_axis("look_left", "look_right") < 1.0, "half stick preserves analog look strength")
	motion.axis_value = 0.0
	Input.parse_input_event(motion.duplicate())
	ui.hide_title()
	ui.play([{"s": "Kit", "t": "一"}, {"s": "Kit", "t": "二", "key": "answer", "choices": ["甲", "乙"]}])
	await button(JOY_BUTTON_A)
	check(ui._seq_i == 1 and ui.dialog_active(), "A advances exactly one dialogue entry")
	check(root.gui_get_focus_owner() == ui._choice_buttons[0], "first dialogue choice is highlighted")
	await button(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner() == ui._choice_buttons[1], "D-pad down highlights second choice")
	await button(JOY_BUTTON_A)
	check(not ui.dialog_active() and ui._results.get("answer") == 1, "A chooses highlighted second choice exactly once")
	ui.pause_enabled = true
	await button(JOY_BUTTON_START)
	check(paused and root.gui_get_focus_owner() is Button and ui.pause_panel.is_ancestor_of(root.gui_get_focus_owner()), "Start opens pause with button focus")
	await button(JOY_BUTTON_B)
	check(not paused and not ui.pause_panel.visible, "B closes pause")
	# Long real ending text must stay at its beginning even with history available.
	ui.show_ending("結局", "雲層之後\n".repeat(80), "歷史")
	for frame in 4:
		await process_frame
	var ending_scroll := ui.ending_text.get_parent().get_parent() as ScrollContainer
	check(ending_scroll.get_v_scroll_bar().max_value > ending_scroll.size.y, "ending regression text overflows the scroll container")
	check(ending_scroll.scroll_vertical == 0, "opening ending keeps narrative scrolled to the top")
	check(not ending_scroll.is_ancestor_of(root.gui_get_focus_owner()), "ending focuses a button outside the narrative scroll")
	ending_scroll.scroll_vertical = int(ending_scroll.get_v_scroll_bar().max_value)
	ui.show_ending("結局", "雲層之後\n".repeat(80), "歷史")
	for frame in 4:
		await process_frame
	check(ending_scroll.scroll_vertical == 0, "reopening ending resets narrative scroll to the top")
	var ending_focus := root.gui_get_focus_owner()
	check(ending_focus is Button and ui.ending_panel.is_ancestor_of(ending_focus), "ending focuses a button")
	await button(JOY_BUTTON_DPAD_DOWN)
	check(ending_scroll.scroll_vertical == 80 and root.gui_get_focus_owner() == ending_focus, "D-pad down scrolls ending 80 pixels with Replay still focused")
	var before_stick := ending_scroll.scroll_vertical
	await scroll_stick(0.5)
	check(ending_scroll.scroll_vertical > before_stick and root.gui_get_focus_owner() == ending_focus, "right stick scrolls ending continuously without changing Replay focus")
	var before_arrow := ending_scroll.scroll_vertical
	await key(KEY_UP, true)
	await key(KEY_UP, false)
	check(ending_scroll.scroll_vertical == maxi(before_arrow - 80, 0) and root.gui_get_focus_owner() == ending_focus, "up arrow scrolls ending without moving button focus")
	var before_history := ending_scroll.scroll_vertical
	await button(JOY_BUTTON_DPAD_RIGHT)
	check(root.gui_get_focus_owner() == ui.ending_history_toggle, "D-pad right reaches the external history button")
	await button(JOY_BUTTON_A)
	for frame in 4:
		await process_frame
	check(not ending_scroll.follow_focus and not ending_scroll.is_ancestor_of(ui.ending_history_toggle)
		and ending_scroll.scroll_vertical == before_history, "history toggle stays outside narrative and does not jump the scroll")
	ui.ending_replay.grab_focus()
	var before_pause := ending_scroll.scroll_vertical
	ui.toggle_pause()
	await button(JOY_BUTTON_DPAD_DOWN)
	await scroll_stick(0.5)
	check(ending_scroll.scroll_vertical == before_pause, "pause on top blocks ending D-pad and stick scrolling")
	ui.toggle_pause()
	await motion(JOY_AXIS_RIGHT_Y, 0.5)
	ui.toggle_pause()
	await motion(JOY_AXIS_RIGHT_Y, 0.0)
	ui.toggle_pause()
	var scroll_after_resume := ending_scroll.scroll_vertical
	for frame in 6:
		await process_frame
		await physics_frame
	check(ending_scroll.scroll_vertical == scroll_after_resume, "stick release while paused stops menu scrolling on resume")
	ui._open_credits()
	for frame in 4:
		await process_frame
	check(root.gui_get_focus_owner() is Button and ui.credits_panel.is_ancestor_of(root.gui_get_focus_owner()), "credits focus Return")
	var credits_scroll := ui.credits_panel.find_child("Scroll", true, false) as ScrollContainer
	var credits_focus := root.gui_get_focus_owner()
	await button(JOY_BUTTON_DPAD_DOWN)
	check(credits_scroll.scroll_vertical == 80 and root.gui_get_focus_owner() == credits_focus, "D-pad down scrolls credits with Return still focused")
	before_stick = credits_scroll.scroll_vertical
	await scroll_stick(0.5)
	check(credits_scroll.scroll_vertical > before_stick and root.gui_get_focus_owner() == credits_focus, "right stick scrolls credits continuously without changing Return focus")
	var ending_under_credits := ending_scroll.scroll_vertical
	await button(JOY_BUTTON_DPAD_DOWN)
	check(ending_scroll.scroll_vertical == ending_under_credits, "credits scrolling leaves ending underneath unchanged")
	await button(JOY_BUTTON_A)
	check(not ui.credits_panel.visible and root.gui_get_focus_owner() == ending_focus, "A on Return still closes scrolled credits")
	ui._open_credits()
	await button(JOY_BUTTON_B)
	check(not ui.credits_panel.visible and root.gui_get_focus_owner() == ending_focus, "B returns credits focus to ending")
	ui.ending_panel.hide()
	await button(JOY_BUTTON_BACK)
	check(ui.log_open(), "Back opens dialogue log")
	await button(JOY_BUTTON_B)
	check(not ui.log_open(), "B closes dialogue log")
	var overlay := Overlay.new()
	overlay.ui = ui
	root.add_child(overlay)
	overlay.open()
	check(root.gui_get_focus_owner() == overlay.buttons.flip, "overlay focuses Flip")
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	check(not overlay.visible and not paused, "Escape closes the focused overlay without pausing")
	if paused:
		ui.toggle_pause()
	overlay.open()
	var closed_events: Array = []
	overlay.closed.connect(func(): closed_events.append(true))
	var world_input := WorldInputProbe.new()
	world_input.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(world_input)
	ui.toggle_log()
	var offset_under_log := overlay.offset
	var angle_under_log := overlay.angle_deg
	await motion(JOY_AXIS_LEFT_X, 1.0)
	await motion(JOY_AXIS_RIGHT_X, 0.5)
	for frame in 6:
		await process_frame
		await physics_frame
	await motion(JOY_AXIS_LEFT_X, 0.0)
	await motion(JOY_AXIS_RIGHT_X, 0.0)
	check(overlay.offset.is_equal_approx(offset_under_log) and is_equal_approx(overlay.angle_deg, angle_under_log), "dialogue log blocks light-box stick movement and rotation")
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(is_equal_approx(overlay.angle_deg, angle_under_log), "dialogue log blocks light-box shoulder rotation")
	await key(KEY_ESCAPE, true)
	await key(KEY_ESCAPE, false)
	check(paused and ui.log_open() and overlay.visible and closed_events.is_empty() and not ui.dialog_active(), "log Escape opens pause without closing light-box or starting dialogue")
	check(world_input.pause_events == 0, "log Escape is consumed before unhandled world input")
	await button(JOY_BUTTON_B)
	await button(JOY_BUTTON_START)
	check(paused and ui.log_open() and overlay.visible and closed_events.is_empty(), "log Start opens pause while preserving light-box")
	check(world_input.pause_events == 0, "log Start is consumed before unhandled world input")
	await button(JOY_BUTTON_B)
	if ui.log_open():
		ui.toggle_log()
	world_input.free()
	var paper_before := overlay.offset
	var focus_before := root.gui_get_focus_owner()
	var move_stick := InputEventJoypadMotion.new()
	move_stick.axis = JOY_AXIS_LEFT_X
	move_stick.axis_value = 1.0
	Input.parse_input_event(move_stick.duplicate())
	await create_timer(0.08).timeout
	move_stick.axis_value = 0.0
	Input.parse_input_event(move_stick.duplicate())
	await process_frame
	check(overlay.offset.x > paper_before.x, "left stick moves the tracing paper")
	check(root.gui_get_focus_owner() == focus_before, "left stick leaves overlay button focus unchanged")
	await button(JOY_BUTTON_DPAD_RIGHT)
	check(root.gui_get_focus_owner() is Button and root.gui_get_focus_owner() != focus_before, "D-pad right still moves overlay button focus")
	overlay._reset()
	overlay.buttons.flip.grab_focus()
	var before_angle := overlay.angle_deg
	await key(KEY_RIGHT, true)
	await create_timer(0.08).timeout
	await key(KEY_RIGHT, false)
	check(root.gui_get_focus_owner() != overlay.buttons.flip, "right arrow moves overlay button focus")
	check(is_equal_approx(overlay.angle_deg, before_angle), "right arrow navigates focus without rotating the overlay")
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_RIGHT_X
	stick.axis_value = 0.5
	Input.parse_input_event(stick.duplicate())
	await create_timer(0.08).timeout
	stick.axis_value = 0.0
	Input.parse_input_event(stick.duplicate())
	await process_frame
	check(overlay.angle_deg > before_angle, "right stick still rotates the overlay smoothly")
	await motion(JOY_AXIS_RIGHT_X, 0.5)
	ui.toggle_pause()
	await motion(JOY_AXIS_RIGHT_X, 0.0)
	check(is_zero_approx(Input.get_axis("look_left", "look_right")), "stick release updates engine input while overlay is paused")
	ui.toggle_pause()
	var angle_after_resume := overlay.angle_deg
	for frame in 6:
		await process_frame
		await physics_frame
	check(is_equal_approx(overlay.angle_deg, angle_after_resume), "stick release while paused stops overlay rotation on resume")
	overlay._reset()
	overlay.buttons.flip.grab_focus()
	await button(JOY_BUTTON_A)
	check(overlay.flipped, "A flips tracing")
	for i in 6:
		await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(overlay.aligned, "RB rotates tracing into alignment")
	for inspect in overlay.find_children("*", "Button", true, false):
		if inspect.text in ["看標籤", "看箭頭", "放大未重合點"]:
			inspect.grab_focus()
			await button(JOY_BUTTON_A)
	check(overlay._clues.size() == 3 and overlay._loupe_open, "focused detail buttons inspect all three real clue hit targets")
	await button(JOY_BUTTON_B)
	check(not overlay.visible, "B closes overlay")
	overlay.free()
	var board := Plan.new()
	root.add_child(board)
	board.open()
	check(board.card_buttons.values().has(root.gui_get_focus_owner()), "plan board focuses a card")
	board.free()
	var report := Report.new()
	root.add_child(report)
	report.open({})
	check(root.gui_get_focus_owner() is BaseButton and report.is_ancestor_of(root.gui_get_focus_owner()), "report focuses a button")
	var old_report_focus_id := root.gui_get_focus_owner().get_instance_id()
	var previous_report := report.selected.duplicate(true)
	report._submit()
	report.open({}, previous_report)
	await process_frame
	var revised_focus := root.gui_get_focus_owner()
	check(is_instance_valid(revised_focus) and revised_focus is BaseButton and revised_focus.is_inside_tree()
		and report.is_ancestor_of(revised_focus) and revised_focus.get_instance_id() != old_report_focus_id
		and report.option_buttons.values().has(revised_focus), "revising report keeps focus on a new in-tree form button after old controls are freed")
	report.free()
	var checklist := Checklist.new()
	root.add_child(checklist)
	checklist.open()
	checklist.allow_mark()
	check(root.gui_get_focus_owner() == checklist.row_buttons[0][0], "checklist focuses first mark when reading finishes")
	await button(JOY_BUTTON_A)
	checklist.allow_mark()
	check(root.gui_get_focus_owner() == checklist.row_buttons[1][0], "next checklist row regains focus")
	checklist.free()
	ui.open_viewer([], null, [], false)
	check(root.gui_get_focus_owner() == ui.thumbs.get_child(0), "darkroom focuses comparison thumbnail")
	check(ui.include_box.focus_mode == Control.FOCUS_ALL, "darkroom checkbox accepts focus")
	ui.measure_pressed.connect(func(): ui.set_viewer_locked(true))
	ui.reselect_pressed.connect(func(): ui.set_viewer_locked(false))
	ui.measure_btn.grab_focus()
	await button(JOY_BUTTON_A)
	check(root.gui_get_focus_owner() == ui.reselect_btn, "measurement moves focus from disabled Measure to Reselect")
	await button(JOY_BUTTON_A)
	check(root.gui_get_focus_owner() == ui.measure_btn, "reselection restores Measure focus")
	ui.viewer_closed.connect(ui.close_viewer)
	await button(JOY_BUTTON_B)
	check(not ui.viewer.visible, "B leaves darkroom viewer")
	ui.free()
	print("test_gamepad: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
