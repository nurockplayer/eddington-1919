extends SceneTree

const UI := preload("res://scripts/ui.gd")
const Prompts := preload("res://scripts/prompts.gd")
const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Plan := preload("res://scripts/cambridge/plan_board.gd")
const Checklist := preload("res://scripts/cambridge/departure_checklist.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const Settings := preload("res://scripts/settings.gd")
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const Render := preload("res://scripts/plate_render.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
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


func _ending_layout(ui: UI) -> void:
	var original_size := root.size
	var original_scale_size := root.content_scale_size
	var original_scale := Settings.text_scale
	var buttons := ui.ending_replay.get_parent().get_children()
	var hint := ui.ending_panel.get_child(ui.ending_panel.get_child_count() - 1) as Label
	var replay_hint := ui.ending_panel.find_child("EndingReplayHint", true, false) as Label
	var original_scroll_bottom := ui.ending_scroll.offset_bottom
	for window_size in [Vector2i(1600, 900), Vector2i(1280, 960), Vector2i(800, 900)]:
		# The third case forces wrapping even with the expand aspect's base width.
		root.content_scale_size = window_size if window_size.x == 800 else Vector2i(1600, 900)
		root.size = window_size
		for scale in [1.0, 1.2]:
			Settings.text_scale = scale
			Settings.refresh_fonts(self)
			ui.show_ending("結局", "雲層之後\n".repeat(80), "歷史", "證據與評語")
			for frame in 6:
				await process_frame
			var context := "%s scale %s" % [window_size, scale]
			var expected_size := Vector2(1600, 1200) if window_size.x == 1280 else Vector2(window_size)
			check(root.get_visible_rect().size.is_equal_approx(expected_size), "expanded canvas: " + context)
			if window_size.x == 800:
				check(buttons[-1].position.y > buttons[0].position.y, "narrow canvas wraps buttons: " + context)
			check(root.gui_get_focus_owner() == buttons[0], "Replay starts focused: " + context)
			check(replay_hint != null and root.get_visible_rect().encloses(replay_hint.get_global_rect()), "replay hint fits: " + context)
			for i in buttons.size():
				var rect: Rect2 = buttons[i].get_global_rect()
				check(root.get_visible_rect().encloses(rect), "ending button fits: %s %s" % [buttons[i].text, context])
				check(not rect.intersects(ui.ending_scroll.get_global_rect()), "button clears ending scroll: " + context)
				check(not rect.intersects(hint.get_global_rect()), "button clears scroll hint: " + context)
				check(not rect.intersects(replay_hint.get_global_rect()), "button clears replay hint: " + context)
				for j in range(i):
					check(not rect.intersects(buttons[j].get_global_rect()), "ending buttons do not overlap: " + context)
				if i > 0:
					var previous: Rect2 = buttons[i - 1].get_global_rect()
					check(rect.position.y > previous.position.y or (is_equal_approx(rect.position.y, previous.position.y)
						and rect.position.x > previous.position.x), "buttons follow visual reading order: " + context)
				check(root.gui_get_focus_owner() == buttons[i], "ui_right reaches button %d: %s" % [i, context])
				await button(JOY_BUTTON_DPAD_DOWN)
				check(root.gui_get_focus_owner() == buttons[i], "ui_down scrolls without stranding focus: " + context)
				if i == 4:
					await button(JOY_BUTTON_A)
					check(ui.credits_panel.visible, "focused credits opens: " + context)
					await button(JOY_BUTTON_B)
					check(not ui.credits_panel.visible and root.gui_get_focus_owner() == buttons[i],
						"credits restores Credits focus: " + context)
				await button(JOY_BUTTON_DPAD_RIGHT)
			check(root.gui_get_focus_owner() == buttons[0], "ui_right wraps to Replay: " + context)
			for i in range(buttons.size() - 1, -1, -1):
				await button(JOY_BUTTON_DPAD_LEFT)
				check(root.gui_get_focus_owner() == buttons[i], "ui_left reverses reading order: " + context)
	# Returning to standard size must release any space used by wrapped rows.
	root.size = original_size
	root.content_scale_size = original_scale_size
	Settings.text_scale = original_scale
	Settings.refresh_fonts(self)
	ui.show_ending("結局", "雲層之後\n".repeat(80), "歷史", "證據與評語")
	for frame in 6:
		await process_frame
	check(is_equal_approx(ui.ending_scroll.offset_bottom, original_scroll_bottom), "returning to original layout releases wrapped row space")


func _run() -> void:
	var player = load("res://scripts/player.gd").new()
	var look_event := InputEventMouseMotion.new()
	look_event.relative = Vector2(0, 10)
	Settings.look_speed = 1.0
	Settings.invert_y = false
	player._unhandled_input(look_event)
	var normal_pitch: float = player.pitch
	player.pitch = 0.0
	Settings.invert_y = true
	player._unhandled_input(look_event)
	check(is_equal_approx(player.pitch, -normal_pitch) and normal_pitch < 0.0, "invert Y reverses mouse pitch")
	look_event.relative = Vector2(10, 0)
	player._unhandled_input(look_event)
	var normal_yaw: float = player.yaw
	player.yaw = 0.0
	Settings.look_speed = 1.5
	player._unhandled_input(look_event)
	check(is_equal_approx(player.yaw, normal_yaw * 1.5) and normal_yaw != 0.0, "look speed scales mouse yaw")
	Settings.look_speed = 1.0
	Settings.invert_y = false
	player.free()
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
	var title_buttons := ui.prologue_btn.get_parent().get_children()
	var credits: Button = title_buttons[2]
	var settings: Button = title_buttons[3]
	credits.grab_focus()
	await button(JOY_BUTTON_DPAD_RIGHT)
	check(root.gui_get_focus_owner() == settings, "D-pad right reaches title settings")
	await button(JOY_BUTTON_DPAD_LEFT)
	check(root.gui_get_focus_owner() == credits, "D-pad left returns to credits")
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
	ScorePlayer.set_music_enabled(true)
	ui.music_button.pressed.emit()
	check(not ScorePlayer.music_enabled() and not ui.music_slider.editable and ui.music_slider.focus_mode == Control.FOCUS_NONE and is_equal_approx(ui.music_row.modulate.a, 0.4),
		"music off dims and locks the music slider")
	ui.music_button.pressed.emit()
	check(ScorePlayer.music_enabled() and ui.music_slider.editable and is_equal_approx(ui.music_row.modulate.a, 1.0),
		"music on restores the music slider")
	ui.restart_button.grab_focus()
	await button(JOY_BUTTON_A)
	check(ui.restart_button.text == "再按一次：從頭開始" and root.gui_get_focus_owner() == ui.restart_button,
		"pause restart asks twice and keeps focus")
	ui.quit_button.pressed.emit()
	check(ui.quit_button.text == "再按一次：離開（進度不會保留）", "pause quit asks twice")
	await button(JOY_BUTTON_B)
	check(not paused and not ui.pause_panel.visible, "B closes pause")
	check(ui.restart_button.text == "從頭開始" and ui.quit_button.text == "離開遊戲",
		"closing pause disarms the destructive rows")
	# Long real ending text must stay at its beginning even with history available.
	ui.show_ending("結局", "雲層之後\n".repeat(80), "歷史")
	for frame in 4:
		await process_frame
	var ending_scroll := ui.ending_scroll
	check(ending_scroll.get_v_scroll_bar().max_value > ending_scroll.size.y, "ending regression text overflows the scroll container")
	check(ending_scroll.scroll_vertical == 0, "opening ending keeps narrative scrolled to the top")
	check(not ending_scroll.is_ancestor_of(root.gui_get_focus_owner()), "ending focuses a button outside the narrative scroll")
	check(not ui.ending_review_toggle.visible, "three-argument ending has no empty review toggle")
	ending_scroll.scroll_vertical = int(ending_scroll.get_v_scroll_bar().max_value)
	ui.show_ending("結局", "雲層之後\n".repeat(80), "歷史", "Eddington 的回應\n你留下的證據")
	for frame in 4:
		await process_frame
	check(ending_scroll.scroll_vertical == 0, "reopening ending resets narrative scroll to the top")
	var ending_focus := root.gui_get_focus_owner()
	check(ending_focus == ui.ending_replay, "ending initially focuses Replay with review available")
	for ending_button in ui.ending_replay.get_parent().get_children():
		check(root.get_visible_rect().encloses(ending_button.get_global_rect()), "ending button fits viewport: " + ending_button.text)
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
	check(root.gui_get_focus_owner() == ui.ending_review_toggle, "D-pad right reaches the external review button")
	await button(JOY_BUTTON_A)
	for frame in 4:
		await process_frame
	check(ui.ending_review.visible and root.gui_get_focus_owner() == ui.ending_review_toggle
		and not ending_scroll.is_ancestor_of(ui.ending_review_toggle)
		and ending_scroll.scroll_vertical == before_history, "gamepad opens review without moving focus or jumping the scroll")
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
	await _ending_layout(ui)
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
	for i in 4:
		await process_frame
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
	for i in 4:
		await process_frame
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
	var sim := Sim.new(1919)
	var plate := {"index": 0, "number": 1, "start": 10.0, "duration": 6.0, "sunlit": false,
		"fog": 0.0, "trail": 0.0, "stars": 12, "included": true, "usable": true, "value": 1.1, "sigma": 0.2}
	var eclipse := Render.render(sim, plate)
	var oxford := Render.render(sim, null)
	ui.open_viewer([plate], oxford, [eclipse], false)
	await process_frame
	ui.thumbs.get_child(1).grab_focus()
	await button(JOY_BUTTON_A)
	ui.loupe_btn.grab_focus()
	await button(JOY_BUTTON_DPAD_RIGHT)
	check(ui.blink_btn.has_focus(), "D-pad reaches blink next to loupe")
	await button(JOY_BUTTON_A)
	check(ui.blink_btn.button_pressed and ui.loupe_btn.button_pressed, "gamepad A starts blink and loupe")
	var crop: Rect2 = ui.big_plate.texture.region
	await button(JOY_BUTTON_DPAD_RIGHT)
	check(ui.blink_btn.has_focus() and ui.big_plate.texture.region.position.x > crop.position.x, "D-pad pans while blink retains focus")
	crop = ui.big_plate.texture.region
	for phase in 2:
		var current: Texture2D = ui.big_plate.texture.atlas
		var deadline := Time.get_ticks_msec() + 2000
		while ui.big_plate.texture.atlas == current and Time.get_ticks_msec() < deadline:
			await process_frame
		var expected: Texture2D = oxford if phase == 0 else eclipse
		check(ui.big_plate.texture.atlas == expected and ui.big_plate.texture.region == crop, "gamepad blink alternates atlas with same crop: %d" % phase)
		check(ui.blink_label.text == ("牛津（無日）" if phase == 0 else "第 1 號（全食）・位移已放大（示意）"), "gamepad blink label follows atlas: %d" % phase)
	await button(JOY_BUTTON_A)
	check(not ui.blink_btn.button_pressed and ui.big_plate.texture == eclipse, "gamepad A stops blink and restores full plate")
	ui.loupe_btn.grab_focus()
	await key(KEY_RIGHT, true)
	await key(KEY_RIGHT, false)
	check(ui.blink_btn.has_focus(), "keyboard right arrow reaches blink from loupe")
	await key(KEY_ENTER, true)
	await key(KEY_ENTER, false)
	check(ui.blink_btn.button_pressed, "keyboard Enter activates blink")
	await button(JOY_BUTTON_A)
	ui.loupe_btn.grab_focus()
	await button(JOY_BUTTON_A)
	crop = ui.big_plate.texture.region
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	check(ui.blink_btn.has_focus() and ui.big_plate.texture.region == crop, "R1 reaches blink from an active loupe without recentering")
	await button(JOY_BUTTON_A)
	await button(JOY_BUTTON_A)
	check(ui.loupe_btn.button_pressed and not ui.blink_btn.button_pressed, "blink off preserves a pre-existing loupe")
	await button(JOY_BUTTON_DPAD_LEFT)
	check(ui.loupe_btn.has_focus() and ui.big_plate.texture.region == crop, "blink off allows D-pad focus recovery without panning")
	await key(KEY_E, true)
	await key(KEY_E, false)
	check(ui.blink_btn.has_focus(), "keyboard E reaches blink from active loupe")
	await key(KEY_Q, true)
	await key(KEY_Q, false)
	check(ui.loupe_btn.has_focus() and ui.big_plate.texture.region == crop, "keyboard Q returns to loupe without recentering")
	await button(JOY_BUTTON_RIGHT_SHOULDER)
	await button(JOY_BUTTON_A)
	ui.thumbs.get_child(0).grab_focus()
	await button(JOY_BUTTON_A)
	check(not ui.blink_btn.button_pressed and ui.blink_btn.disabled and ui.big_plate.texture == oxford, "gamepad Oxford selection stops blink")
	var blank := plate.duplicate(true)
	blank.duration = 0.1
	ui.open_viewer([blank], oxford, [Render.render(sim, blank)], false)
	check(ui.blink_btn.disabled, "blank plate disables blink")
	ui.close_viewer()
	ui.open_viewer([], null, [], false)
	await process_frame
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
	ui.open_viewer([plate], oxford, [eclipse], true)
	await process_frame
	ui.blink_btn.grab_focus()
	await button(JOY_BUTTON_A)
	ui.report_pressed.connect(func():
		ui.set_viewer_report(true)
		ui.play([{"s": "Eddington", "t": "看著證據選擇。", "key": "answer", "choices": ["甲", "乙"]}])
	)
	ui.report_btn.grab_focus()
	await button(JOY_BUTTON_A)
	check(not ui.blink_btn.button_pressed and not ui.blink_label.visible and ui.big_plate.texture == eclipse, "gamepad report stops blink")
	check(ui.viewer.visible and root.gui_get_focus_owner() == ui._choice_buttons[0], "report A keeps evidence visible and focuses dialogue")
	await button(JOY_BUTTON_B)
	check(ui.viewer.visible and ui.dialog_active(), "B cannot dismiss evidence during judgment")
	await button(JOY_BUTTON_DPAD_DOWN)
	check(root.gui_get_focus_owner() == ui._choice_buttons[1], "judgment D-pad navigates dialogue choices")
	await key(KEY_TAB, true)
	await key(KEY_TAB, false)
	check(ui.log_open() and ui.viewer.visible, "judgment Tab opens the log without dismissing evidence")
	await button(JOY_BUTTON_BACK)
	check(not ui.log_open() and root.gui_get_focus_owner() in ui._choice_buttons, "closing judgment log restores dialogue choice focus")
	await key(KEY_DOWN, true)
	await key(KEY_DOWN, false)
	check(root.gui_get_focus_owner() in ui._choice_buttons, "judgment keyboard arrows stay on dialogue choices")
	await button(JOY_BUTTON_A)
	check(not ui.dialog_active() and ui._results.has("answer"), "judgment A chooses without triggering a viewer action")
	ui.close_viewer()
	ui.open_viewer([], null, [], false)
	check(not ui._viewer_reporting and not ui.measure_btn.disabled and ui.measure_btn.is_visible_in_tree(), "reopening restores editable viewer controls")
	ui.free()
	# UI stops its viewer SFX on exit; let AudioServer release the playback
	# before this harness immediately shuts down the engine.
	await create_timer(0.1).timeout
	print("test_gamepad: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
