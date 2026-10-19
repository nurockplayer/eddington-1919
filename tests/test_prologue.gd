extends SceneTree
## Headless checks for the Cambridge prologue's matching, decisions, and persistence.
## Run: godot --headless --path . --script res://tests/test_prologue.gd

const Overlay = preload("res://scripts/cambridge/overlay_viewer.gd")
const MathModel = preload("res://scripts/cambridge/overlay_math.gd")
const ReportSheet = preload("res://scripts/cambridge/report_sheet.gd")
const PlanBoard = preload("res://scripts/cambridge/plan_board.gd")
const C17 = preload("res://scripts/cambridge/content_1917.gd")
const UI = preload("res://scripts/ui.gd")

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
	board.finish_btn.pressed.emit()
	check(blocked_events.size() == 1 and finished_events.is_empty(), "biased plan emits blocked and does not finish")
	var discard: Button = board.card_buttons["keep_agreeing"]
	discard.button_pressed = false
	discard.pressed.emit()
	var helpful: Button = board.card_buttons["conditions"]
	helpful.button_pressed = true
	helpful.pressed.emit()
	board.finish_btn.pressed.emit()
	check(finished_events.size() == 1 and finished_events[0].size() == 3, "removing bias allows a valid three-card plan to finish")
	board.queue_free()
	await process_frame
	check(not is_instance_valid(board), "plan board queue_free releases the control tree")


func _send_tab(ui: CanvasLayer) -> void:
	var pressed := InputEventKey.new()
	pressed.keycode = KEY_TAB
	pressed.physical_keycode = KEY_TAB
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventKey.new()
	released.keycode = KEY_TAB
	released.physical_keycode = KEY_TAB
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


func _run() -> void:
	await process_frame
	_test_overlay_math()
	_test_report_gating()
	_test_plan_rules()
	await _test_story_scene_persistence()
	await _test_report_ui()
	await _test_plan_ui()
	await _test_dialogue_history()
	await _test_viewer_hint_progress()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
