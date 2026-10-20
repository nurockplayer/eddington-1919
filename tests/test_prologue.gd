extends SceneTree
## Headless checks for the Cambridge prologue's matching, decisions, and persistence.
## Run: godot --headless --path . --script res://tests/test_prologue.gd

const Overlay = preload("res://scripts/cambridge/overlay_viewer.gd")
const MathModel = preload("res://scripts/cambridge/overlay_math.gd")
const ReportSheet = preload("res://scripts/cambridge/report_sheet.gd")
const PlanBoard = preload("res://scripts/cambridge/plan_board.gd")
const C17 = preload("res://scripts/cambridge/content_1917.gd")
const UI = preload("res://scripts/ui.gd")
const Room = preload("res://scripts/cambridge/room_builder.gd")

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func option_ids(options: Array) -> Array[String]:
	var ids: Array[String] = []
	for option in options:
		ids.append(str(option.get("id", "")))
	return ids


func contains_all(values: Array, expected: Array) -> bool:
	for value in expected:
		if not values.has(value):
			return false
	return true


func _test_overlay_math() -> void:
	var unflipped := MathModel.transformed_copy(false, 0.0, Vector2.ZERO)
	var flipped_partial := MathModel.transformed_copy(true, 0.0, Vector2.ZERO)
	var aligned := MathModel.transformed_copy(true, MathModel.SOURCE_TILT_DEG, Vector2.ZERO)
	check(MathModel.match_count(unflipped) == 0, "unflipped tracing has no star matches")
	var partial_count := MathModel.match_count(flipped_partial)
	check(partial_count > 0 and partial_count < 17, "flipped but unrotated tracing only partially matches (%d)" % partial_count)
	check(MathModel.match_count(aligned) == 17, "flipped and rotated tracing matches exactly 17 of 18 dots")
	check(MathModel.match_count(MathModel.transformed_copy(true, 17.0, Vector2.ZERO)) < 17, "wrong rotation prevents full matching")
	check(MathModel.match_count(MathModel.transformed_copy(true, MathModel.SOURCE_TILT_DEG, Vector2(0.10, -0.04))) < 17, "wrong translation prevents full matching")
	var stars := MathModel.star_points()
	check(MathModel.match_count([stars[0], stars[0]]) == 1, "matching is one-to-one when an input point is duplicated")
	check(MathModel.alignment(true, MathModel.SOURCE_TILT_DEG, Vector2.ZERO), "exact flip and rotation align")
	check(MathModel.alignment(true, MathModel.SOURCE_TILT_DEG + 0.59, Vector2.ZERO), "rotation error below 0.6 degrees remains eligible")
	check(not MathModel.alignment(true, MathModel.SOURCE_TILT_DEG + 0.6, Vector2.ZERO), "rotation error at the 0.6 degree boundary is rejected")
	check(not MathModel.alignment(true, MathModel.SOURCE_TILT_DEG - 0.6, Vector2.ZERO), "negative rotation error at the 0.6 degree boundary is rejected")
	check(MathModel.alignment(true, MathModel.SOURCE_TILT_DEG, Vector2(0.001, 0.0)), "small translation remains within alignment tolerance")
	check(not MathModel.alignment(true, MathModel.SOURCE_TILT_DEG, Vector2(0.026, 0.0)), "translation beyond 0.025 is rejected")
	check(not MathModel.alignment(false, MathModel.SOURCE_TILT_DEG, Vector2.ZERO), "alignment requires the tracing to be flipped")


func _test_report_gating() -> void:
	var rows := C17.report_rows()
	check(rows.size() == 4, "report contract provides four rows")
	var cause_row: Dictionary = rows[0]
	var original_row: Dictionary = rows[1]
	var residual_row: Dictionary = rows[2]
	var kit_row: Dictionary = rows[3]
	for mirrored in [false, true]:
		for tilted in [false, true]:
			for residual in [false, true]:
				for kit_checked in [false, true]:
					var state := {
						"label_mirrored": mirrored,
						"arrow_tilted": tilted,
						"residual": residual,
						"kit_checked": kit_checked,
					}
					var cause := option_ids(ReportSheet.available_options(cause_row, state))
					var expected_cause := ["unknown", "accuse"]
					if mirrored:
						expected_cause.append("mirror")
					if tilted:
						expected_cause.append("tilt")
					if mirrored and tilted:
						expected_cause.append("both")
					check(cause.size() == expected_cause.size() and contains_all(cause, expected_cause), "cause choices match clue combination m=%s t=%s" % [mirrored, tilted])
					check(option_ids(ReportSheet.available_options(original_row, state)) == ["keep", "redraw"], "original-image choices are always available")
					var residual_options := ReportSheet.available_options(residual_row, state)
					check(residual_options.size() == (3 if residual else 0), "residual choices are gated by residual clue=%s" % residual)
					var kit_options := ReportSheet.available_options(kit_row, state)
					check(kit_options.size() == (1 if kit_checked else 0), "Kit credit is gated by independent check=%s" % kit_checked)
	check(ReportSheet.available_options(residual_row, {"residual_found": true}).size() == 3, "residual_found state alias unlocks residual choices")


func _test_plan_rules() -> void:
	var cards := C17.plan_cards()
	var non_bias := ["comparison", "far_stars", "rules_first", "two_sites", "conditions", "go_anyway"]
	var valid_three := 0
	var valid_four := 0
	for mask in range(1 << non_bias.size()):
		var ids: Array = []
		for bit in non_bias.size():
			if mask & (1 << bit):
				ids.append(non_bias[bit])
		if ids.size() == 3:
			valid_three += 1
			check(PlanBoard.can_finish(ids, cards), "all three-card non-bias plan combinations are valid")
		elif ids.size() == 4:
			valid_four += 1
			check(PlanBoard.can_finish(ids, cards), "all four-card non-bias plan combinations are valid")
	check(valid_three == 20 and valid_four == 15, "enumerated all 20 three-card and 15 four-card non-bias plans")
	check(not PlanBoard.can_finish(["comparison", "far_stars", "keep_agreeing"], cards), "discard bias card blocks finishing")
	check(not PlanBoard.can_finish(["comparison", "far_stars", "nearest_only"], cards), "prove bias card blocks finishing")
	check(not PlanBoard.can_finish(["comparison", "far_stars", "missing"], cards), "unknown card IDs are rejected")
	check(not PlanBoard.can_finish(["comparison", "comparison", "far_stars"], cards), "duplicate card IDs are rejected")
	check(not PlanBoard.can_finish(["comparison", "far_stars"], cards), "plans with fewer than three cards are rejected")
	check(not PlanBoard.can_finish(["comparison", "far_stars", "two_sites", "conditions", "go_anyway"], cards), "plans with more than four cards are rejected")


func _packed_dummy(name: String) -> PackedScene:
	var node := Node.new()
	node.name = name
	var packed := PackedScene.new()
	var error := packed.pack(node)
	node.free()
	check(error == OK, "packed dummy scene %s" % name)
	return packed


func _test_story_scene_persistence() -> void:
	await process_frame
	var story := root.get_node_or_null("Story")
	check(is_instance_valid(story), "Story autoload is ready before deferred tests")
	if not is_instance_valid(story):
		return
	story.from_prologue = true
	story.prologue_done = true
	story.clues = {"label_mirrored": true, "residual": true}
	story.report = {"cause": "mirror", "original": "keep", "residual": "unresolved", "kit_credited": false}
	story.plan = ["comparison", "far_stars", "rules_first"]
	story.kit_choice = 1
	var first := _packed_dummy("PrologueDummyOne")
	var second := _packed_dummy("PrologueDummyTwo")
	check(change_scene_to_packed(first) == OK, "replace current scene with first dummy scene")
	await process_frame
	check(change_scene_to_packed(second) == OK, "replace first dummy scene with second dummy scene")
	await process_frame
	check(story.from_prologue and story.prologue_done, "Story flags survive scene replacement")
	check(story.clues.label_mirrored and story.clues.residual, "Story clues survive scene replacement")
	check(story.report.cause == "mirror" and story.report.residual == "unresolved", "Story report survives scene replacement")
	check(story.plan == ["comparison", "far_stars", "rules_first"] and story.kit_choice == 1, "Story plan and choice survive scene replacement")


func _test_report_ui() -> void:
	var sheet = ReportSheet.new()
	var modal_layer := CanvasLayer.new()
	root.add_child(modal_layer)
	modal_layer.add_child(sheet)
	await process_frame
	check(not sheet.visible, "report sheet starts hidden")
	sheet.open({"label_mirrored": true, "arrow_tilted": true, "kit_checked": false})
	await process_frame
	check(sheet.selected.get("residual", "") == "not_found", "report defaults absent residual to not_found")
	check(not sheet.option_buttons.has("kit_credited/credited"), "Kit credit checkbox is unavailable before independent check")
	var viewport_rect := Rect2(Vector2.ZERO, sheet.get_viewport_rect().size)
	for key in sheet.option_buttons:
		var option_button: Button = sheet.option_buttons[key]
		check(option_button.is_visible_in_tree() and viewport_rect.encloses(option_button.get_global_rect()), "visible report option %s is inside viewport (%s)" % [key, option_button.get_global_rect()])
	for button in [sheet.close_btn, sheet.submit_btn]:
		check(button.is_visible_in_tree() and viewport_rect.encloses(button.get_global_rect()), "report action button is inside viewport (%s)" % button.get_global_rect())
	var accuse: Button = sheet.option_buttons["cause/accuse"]
	accuse.button_pressed = true
	accuse.pressed.emit()
	check(accuse.text.begins_with("✓"), "selected report option has a visible check mark")
	var accuse_style := accuse.get_theme_stylebox("pressed") as StyleBoxFlat
	check(accuse_style != null and accuse_style.border_width_left >= 2, "selected report option has a strong paper border")
	var unknown: Button = sheet.option_buttons["cause/unknown"]
	unknown.button_pressed = true
	unknown.pressed.emit()
	check(unknown.text.begins_with("✓") and not accuse.text.begins_with("✓"), "report mark follows the active choice when selection changes")
	accuse.button_pressed = true
	accuse.pressed.emit()
	var emissions: Array = []
	sheet.submitted.connect(func(report: Dictionary): emissions.append({"report": report, "hidden": not sheet.visible}))
	sheet.submit_btn.pressed.emit()
	check(emissions.size() == 1, "report submission signal emitted")
	if not emissions.is_empty():
		var emission: Dictionary = emissions[0]
		check(emission.hidden, "report sheet hides before emitting submission")
		check(emission.report.cause == "accuse" and emission.report.original == "keep", "report controls update the selected dictionary")
		check(emission.report.residual == "not_found" and emission.report.kit_credited == false, "report submit records missing residual and unchecked Kit credit")
	sheet.open({"label_mirrored": false, "arrow_tilted": false, "kit_checked": true})
	check(sheet.option_buttons.has("kit_credited/credited"), "Kit checkbox appears after independent check")
	check(sheet.option_buttons["kit_credited/credited"] is CheckBox, "independent credit uses a real checkbox control")
	check((sheet.option_buttons["kit_credited/credited"] as Button).button_pressed, "Kit checkbox reflects completed independent check")
	sheet.queue_free()
	modal_layer.queue_free()
	await process_frame
	check(not is_instance_valid(sheet), "report sheet queue_free releases the control tree")
	check(not is_instance_valid(modal_layer), "report modal layer queue_free releases its children")


func _test_plan_ui() -> void:
	var board = PlanBoard.new()
	root.add_child(board)
	await process_frame
	check(not board.visible, "plan board starts hidden")
	board.open()
	check(board.card_buttons.size() == 8, "plan board presents all eight cards")
	var blocked_events: Array = []
	var finished_events: Array = []
	var reactions: Array = []
	board.blocked.connect(func(card: Dictionary): blocked_events.append(card))
	board.finished.connect(func(ids: Array): finished_events.append(ids))
	board.reaction.connect(func(seq: Array): reactions.append(seq))
	for id in ["comparison", "far_stars", "keep_agreeing"]:
		var button: Button = board.card_buttons[id]
		button.button_pressed = true
		button.pressed.emit()
	check(board.selected.size() == 3 and reactions.size() == 3, "selecting plan cards fills slots and emits reactions (selected=%d reactions=%d)" % [board.selected.size(), reactions.size()])
	var discard: Button = board.card_buttons["keep_agreeing"]
	var selected_style := discard.get_theme_stylebox("pressed") as StyleBoxFlat
	check(discard.text.begins_with("✓") and selected_style != null and selected_style.border_width_left >= 3, "selected plan card has a visible check mark and heavy border")
	var slot_one := board.find_child("PlanSlot1", true, false) as Label
	var slot_three := board.find_child("PlanSlot3", true, false) as Label
	check(slot_one != null and slot_one.text.contains("比對片") and slot_three != null and slot_three.text.contains("只留下"), "plan slots show selected card text in order")
	board.finish_btn.pressed.emit()
	check(blocked_events.size() == 1 and finished_events.is_empty(), "biased plan emits blocked and does not finish")
	discard.button_pressed = false
	discard.pressed.emit()
	check(not discard.text.begins_with("✓"), "deselected plan card loses its selection mark")
	var helpful: Button = board.card_buttons["conditions"]
	helpful.button_pressed = true
	helpful.pressed.emit()
	check(helpful.text.begins_with("✓") and slot_three.text.contains("狀況"), "replacement plan card gains its mark and replaces the numbered slot text")
	board.finish_btn.pressed.emit()
	check(finished_events.size() == 1 and finished_events[0].size() == 3, "removing bias allows a valid three-card plan to finish")
	board.queue_free()
	await process_frame
	check(not is_instance_valid(board), "plan board queue_free releases the control tree")


func _send_tab(ui: CanvasLayer) -> void:
	await _send_key(KEY_TAB)


func _send_key(code: Key) -> void:
	var pressed := InputEventKey.new()
	pressed.keycode = code
	pressed.physical_keycode = code
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventKey.new()
	released.keycode = code
	released.physical_keycode = code
	released.pressed = false
	Input.parse_input_event(released)
	await process_frame


func _test_dialogue_history() -> void:
	var added_actions: Array[String] = []
	for action in ["pause", "interact", "shutter"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			added_actions.append(action)
	var ui = UI.new()
	ui.history.clear()
	root.add_child(ui)
	await process_frame
	var sequence: Array = []
	for i in 61:
		sequence.append({"s": "Speaker", "t": "line_%d" % i})
	ui.play(sequence)
	check(ui.history.size() == 1 and ui._seq_i == 0, "first dialogue line enters history")
	await _send_tab(ui)
	check(ui.log_open() and ui._seq_i == 0, "Tab opens log without advancing active dialogue")
	await _send_tab(ui)
	check(not ui.log_open() and ui._seq_i == 0, "Tab closes log without advancing active dialogue")
	for _i in 60:
		ui._advance()
	check(ui.history.size() == 60, "dialogue history retains only the last 60 lines")
	if ui.history.size() == 60:
		check(ui.history[0] == "Speaker：line_1" and ui.history[59] == "Speaker：line_60", "history window contains the newest 60 lines in order")
	await _send_tab(ui)
	check(ui.log_open() and ui._seq_i == 60, "Tab opens populated history without advancing the final dialogue line")
	await _send_tab(ui)
	check(not ui.log_open() and ui._seq_i == 60, "Tab closes populated history without advancing the final dialogue line")
	ui.history.clear()
	var speakers: Array[String] = []
	ui.dialogue_entry.connect(func(speaker: String): speakers.append(speaker))
	ui.play([
		{"s": "Ashby", "t": "Opening line."},
		{"s": "Kit", "t": "A question.", "choices": ["First", "Second"], "then": [[{"s": "Kit", "t": "First branch."}], [{"s": "Eddington", "t": "Second branch."}]]},
	])
	ui._advance()
	ui._choose(1)
	check(speakers == ["Ashby", "Kit", "Eddington"], "dialogue_entry reports each displayed speaker across a selected choice branch")
	ui._advance()
	check(is_equal_approx(ui.dialog_panel.offset_top, -214.0) and is_equal_approx(ui.dialog_panel.offset_bottom, -18.0), "default dialogue panel uses the low-third placement in every chapter (speaker faces stay visible)")
	# The authored three-choice trial must grow upward from the Cambridge bottom edge.
	ui.dialog_panel.offset_top = -214
	ui.dialog_panel.offset_bottom = -18
	ui.dialog_panel.custom_minimum_size.y = 196
	ui.play([C17.trial_task()[3]])
	for _i in 4:
		await process_frame
	var within_view: bool = ui.dialog_panel.get_global_rect().end.y <= root.get_visible_rect().end.y
	for button in ui._choice_buttons:
		within_view = within_view and button.get_global_rect().end.y <= root.get_visible_rect().end.y
	check(within_view, "authored three-choice dialogue and all buttons stay above the viewport bottom")
	ui._advance()
	# The 1919 telegram prompt is the longest choice list (four cables) in the default placement.
	ui.play([{"s": "Eddington", "t": "我們得發電報給倫敦的 Dyson。只有幾個字的空間——你會寫什麼？", "key": "telegram",
		"choices": ["ECLIPSE SPLENDID. EINSTEIN CONFIRMED.", "THROUGH CLOUD. HOPEFUL.", "THROUGH CLOUD. STARS FEW. RESULT UNDECIDED.", "CLOUD. NO RESULTS."]}])
	for _i in 4:
		await process_frame
	var tele_rect: Rect2 = ui.dialog_panel.get_global_rect()
	var tele_ok: bool = tele_rect.position.y >= 0.0 and tele_rect.end.y <= root.get_visible_rect().end.y
	for button in ui._choice_buttons:
		tele_ok = tele_ok and root.get_visible_rect().encloses(button.get_global_rect())
	check(tele_ok, "four-choice telegram prompt stays fully on screen (%s)" % tele_rect)
	ui.toggle_log()
	check(not ui.hint_label.visible, "dialogue input hint hides while the Tab log is open")
	ui.toggle_log()
	check(ui.hint_label.visible, "dialogue input hint returns when the Tab log closes")
	ui.queue_free()
	await process_frame
	check(not is_instance_valid(ui), "dialogue UI queue_free releases its controls")
	for action in added_actions:
		InputMap.erase_action(action)


func _test_viewer_hint_progress() -> void:
	var viewer = Overlay.new()
	root.add_child(viewer)
	await process_frame
	var hints: Array = []
	viewer.hint_requested.connect(func(): hints.append(true))
	viewer.open()
	viewer._process(89.0)
	check(hints.is_empty(), "no viewer hint before inactivity threshold")
	viewer._process(1.1)
	check(hints.size() == 1, "viewer gives a gentle hint after 90 seconds without progress")
	viewer._process(180.0)
	check(hints.size() == 1, "hint is not repeated before new progress")
	viewer._found_clue("label_mirrored")
	viewer._process(90.1)
	check(hints.size() == 2, "new clue permits the next hint ladder step")
	viewer.hide()
	viewer._process(180.0)
	check(hints.size() == 2, "closed viewer does not accrue inactivity")
	viewer.queue_free()
	await process_frame


func _test_room_north_boundary() -> void:
	var room := Node3D.new()
	root.add_child(room)
	Room.build(room)
	await physics_frame
	await physics_frame
	# Standing-height rays must hit the wall beside the sash and curtain.
	# The original left pier ended at x=-2.5 while the sill began at -1.45.
	for x in [-2.4, -2.0, -1.6]:
		var query := PhysicsRayQueryParameters3D.create(Vector3(x, 0.9, -2.65), Vector3(x, 0.9, -3.3))
		var hit := room.get_world_3d().direct_space_state.intersect_ray(query)
		check(not hit.is_empty(), "north wall stops a player at x=%.1f beside the window" % x)
	room.free()


func _pause_round_trip(chapter, label: String, use_escape := true) -> void:
	if use_escape:
		await _send_key(KEY_ESCAPE)
	else:
		chapter.ui.toggle_pause()
	check(paused and chapter.ui.pause_panel.visible, "%s: pause is reachable" % label)
	check(not chapter.player.can_move and not chapter.player.can_look, "%s: pause locks chapter input" % label)
	if use_escape:
		await _send_key(KEY_ESCAPE)
	else:
		chapter.ui.toggle_pause()
	check(not paused and not chapter.ui.pause_panel.visible, "%s: resume is reachable" % label)
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not chapter.player.can_look, "%s: resume preserves modal cursor and input lock" % label)


func _test_cambridge_pause_restore() -> void:
	var chapter = load("res://scripts/cambridge/director.gd").new()
	root.add_child(chapter)
	# Exercise production signal connections after the ordinary opening finishes.
	var deadline := Time.get_ticks_msec() + 12000
	while not chapter.ui.dialog_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter.ui.dialog_active(), "Cambridge opening reaches dialogue before pause regressions")
	if not chapter.ui.dialog_active():
		chapter.free()
		return
	while chapter.ui.dialog_active():
		chapter.ui._advance()
	chapter.report_sheet.open(chapter.state())
	chapter._sync_player()
	await _pause_round_trip(chapter, "Cambridge report: Esc twice")
	check(chapter.report_sheet.visible, "report stays visible after Esc twice")
	# Closing a log layered over a report must retain the form's input lock too.
	await _send_key(KEY_TAB)
	await _pause_round_trip(chapter, "Cambridge log over report: Esc twice")
	await _send_key(KEY_TAB)
	check(chapter.report_sheet.visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "closing report log restores form input state")
	chapter.report_sheet.close_btn.pressed.emit()
	chapter.plan_board.open()
	chapter._sync_player()
	await _pause_round_trip(chapter, "Cambridge plan board: Esc twice")
	check(chapter.plan_board.visible, "plan board stays visible after Esc twice")
	chapter.plan_board.hide()
	chapter.overlay.open()
	chapter._sync_player()
	# The overlay owns Esc to close; pause/resume via the UI exercises its lock.
	await _pause_round_trip(chapter, "Cambridge overlay", false)
	check(chapter.overlay.visible, "pause/resume retains overlay")
	chapter.overlay.hide()
	chapter._say([{"s": "Kit", "t": "Input-state regression."}], "")
	await _pause_round_trip(chapter, "Cambridge dialogue: Esc twice")
	check(chapter.ui.dialog_active() and chapter.ui._seq_i == 0, "Esc twice leaves dialogue on the same line")
	chapter.ui._advance()
	await _send_key(KEY_TAB)
	await _pause_round_trip(chapter, "Cambridge log: Esc twice")
	check(chapter.ui.log_open(), "Esc twice preserves open log")
	await _send_key(KEY_TAB)
	check(chapter._free() and chapter.player.can_move and chapter.player.can_look, "closing log restores Cambridge investigation input")
	await _test_cambridge_report_and_kit(chapter)
	await _drain_chapter_audio(chapter)
	chapter.free()
	await process_frame


func _finish_test_dialogue(chapter) -> void:
	var guard := 50
	while chapter.ui.dialog_active() and guard > 0:
		guard -= 1
		if not chapter.ui._choice_buttons.is_empty():
			chapter.ui._choose(1)
		else:
			chapter.ui._advance()
	check(guard > 0, "test dialogue terminates")


func _test_cambridge_report_and_kit(chapter) -> void:
	var story := root.get_node("Story")
	for flags in [[true, false], [false, true], [false, false]]:
		chapter.aligned = flags[0]
		story.clues["log"] = flags[1]
		chapter.kit_checked = flags[0]
		chapter.viewer_opens = 1
		chapter.guess_offered = false
		var expected_guess: bool = not flags[0] and not flags[1]
		chapter._viewer_closed()
		check(chapter.guess_offered == expected_guess and chapter.ui.dialog_active() == expected_guess, "first-close Kit guess respects aligned=%s log=%s" % flags)
		_finish_test_dialogue(chapter)
		chapter.guess_offered = false
		chapter._interact("kit")
		check(chapter.guess_offered == expected_guess, "Kit interaction guess respects aligned=%s log=%s" % flags)
		_finish_test_dialogue(chapter)
	chapter.aligned = true
	chapter.kit_checked = false
	chapter.guess_offered = false
	chapter._interact("kit")
	check(chapter._pending == "double_check" and not chapter.guess_offered, "aligned copy still offers Kit independent check")
	_finish_test_dialogue(chapter)
	check(chapter.kit_checked, "Kit independent check completes after suppressing old guess")

	story.clues.merge({"label_mirrored": true, "arrow_tilted": true, "residual": true}, true)
	chapter.residual_found = true
	chapter.aligned = false
	chapter.report_sheet.open(chapter.state())
	for id in ["cause/accuse", "original/redraw", "residual/delete"]:
		var button: Button = chapter.report_sheet.option_buttons[id]
		button.button_pressed = true
		button.pressed.emit()
	var previous: Dictionary = chapter.report_sheet.selected.duplicate(true)
	chapter.report_sheet.submit_btn.pressed.emit()
	check(story.report.has("aligned") and not story.report.aligned and story.report.kit_checked, "director stamps false alignment and Kit check at submit")
	await _wait_for_mentor_review(chapter)
	check(chapter._pending == "mentor_review", "initial report submission starts mentor review")
	var guard := 50
	while chapter.ui.dialog_active() and chapter._pending == "mentor_review" and guard > 0:
		guard -= 1
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("choices"):
			chapter.ui._choose(0 if entry.get("key", "") == "revise_report" else 1)
		else:
			chapter.ui._advance()
	check(guard > 0 and chapter.report_sheet.visible and not chapter.report_done, "mentor revise choice reopens actual sheet for resubmission")
	for id in ["cause", "original", "residual", "kit_credited"]:
		check(chapter.report_sheet.selected.get(id) == previous.get(id), "director revision preserves prior %s selection" % id)
	for id in ["cause/both", "original/keep", "residual/new_object"]:
		var button: Button = chapter.report_sheet.option_buttons[id]
		button.button_pressed = true
		button.pressed.emit()
	chapter.aligned = true
	chapter.report_sheet.submit_btn.pressed.emit()
	check(story.report.aligned and story.report.residual == "new_object", "resubmission stamps current alignment and revised selection")
	await _wait_for_mentor_review(chapter)
	check(chapter._pending == "mentor_review", "revised report replays actual mentor review")
	guard = 50
	var revision_prompt_seen := false
	while chapter.ui.dialog_active() and chapter._pending == "mentor_review" and guard > 0:
		guard -= 1
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("choices"):
			revision_prompt_seen = revision_prompt_seen or entry.get("key", "") == "revise_report"
			chapter.ui._choose(1)
		else:
			chapter.ui._advance()
	check(guard > 0 and revision_prompt_seen and chapter._pending == "dyson", "accepting the second review advances to Dyson dialogue")


func _wait_for_mentor_review(chapter) -> void:
	var deadline := Time.get_ticks_msec() + 4000
	while chapter._pending != "mentor_review" and Time.get_ticks_msec() < deadline:
		await process_frame


func _drain_chapter_audio(chapter) -> void:
	chapter.set_process(false)
	for audio in chapter.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
	# Headless frames can outrun the audio thread; let it release stopped voices.
	await create_timer(0.06, true, false, true).timeout


func _test_totality_log_suspension() -> void:
	var chapter = load("res://scripts/main.gd").new()
	root.add_child(chapter)
	chapter.set_process(false)
	chapter.ui.hide_title()
	chapter.ui.pause_enabled = true
	for phase in [chapter.Phase.PREP, chapter.Phase.NIGHT]:
		chapter.phase = phase
		chapter._say([{"s": "Eddington", "t": "Input-state regression."}], "")
		await _pause_round_trip(chapter, "1919 dialogue in phase %s" % phase)
		await _send_key(KEY_TAB)
		await _send_key(KEY_TAB)
		check(not chapter.player.can_look, "closing dialogue log retains the input lock")
		chapter.ui._advance()
		check(chapter.player.can_move and chapter.player.can_look, "ending paused/logged dialogue restores walking and looking")
	chapter._open_viewer()
	await _pause_round_trip(chapter, "1919 plate viewer")
	chapter._on_viewer_closed()
	check(chapter.player.can_move and chapter.player.can_look, "closing paused viewer restores walking and looking")
	chapter.phase = chapter.Phase.TOTALITY
	chapter.plates_left = 3
	chapter.t_game = 100.0
	chapter.sim.open_shutter(chapter.t_game)
	await _send_key(KEY_TAB)
	check(chapter.ui.log_open(), "Tab opens log during totality with shutter open")
	var exposure: Dictionary = chapter.sim._open.duplicate(true)
	chapter._process_totality(20.0)
	check(chapter.t_game == 100.0 and chapter.sim._open == exposure, "totality log freezes both clock and accumulated exposure")
	await _pause_round_trip(chapter, "1919 totality log: Esc twice")
	chapter._process_totality(20.0)
	check(chapter.t_game == 100.0 and chapter.sim._open == exposure, "unpausing with log open keeps totality suspended")
	await _send_key(KEY_TAB)
	chapter._process_totality(0.4)
	check(is_equal_approx(chapter.t_game, 101.0) and chapter.sim._open.duration > exposure.duration, "closing log resumes totality and exposure")
	check(not chapter.player.can_move and chapter.player.can_look, "closing totality log restores looking without walking")
	chapter.sim.close_shutter(false)
	chapter.change_left = chapter.sim.PLATE_CHANGE_S
	await _send_key(KEY_TAB)
	var before: float = chapter.t_game
	chapter._process_totality(20.0)
	check(chapter.t_game == before and chapter.change_left == chapter.sim.PLATE_CHANGE_S, "log also freezes plate-change countdown")
	await _send_key(KEY_TAB)
	chapter._process_totality(0.4)
	check(is_equal_approx(chapter.change_left, chapter.sim.PLATE_CHANGE_S - 1.0), "plate-change countdown resumes after closing log")
	await _drain_chapter_audio(chapter)
	chapter.free()
	await process_frame


func _run() -> void:
	await process_frame
	await _test_room_north_boundary()
	_test_overlay_math()
	_test_report_gating()
	_test_plan_rules()
	await _test_story_scene_persistence()
	await _test_report_ui()
	await _test_plan_ui()
	await _test_dialogue_history()
	await _test_viewer_hint_progress()
	await _test_cambridge_pause_restore()
	await _test_totality_log_suspension()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
