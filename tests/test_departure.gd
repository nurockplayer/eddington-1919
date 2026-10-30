extends SceneTree
## Headless checks for M2 dialogue branches and continuity.
## Run: godot --headless --path . --script res://tests/test_departure.gd

const Content = preload("res://scripts/cambridge/content_departure.gd")
const Checklist = preload("res://scripts/cambridge/departure_checklist.gd")

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func _has_choice(seq: Array, key: String) -> bool:
	for item in seq:
		if item is Dictionary:
			if str(item.get("key", "")) == key:
				return true
			for branch in item.get("then", []):
				if branch is Array and _has_choice(branch, key):
					return true
	return false


func _collect_text(seq: Array, result: Array[String]) -> void:
	for item in seq:
		if not item is Dictionary:
			continue
		result.append(str(item.get("t", "")))
		for choice in item.get("choices", []):
			result.append(str(choice))
		for branch in item.get("then", []):
			if branch is Array:
				_collect_text(branch, result)


func _packed_dummy(name: String) -> PackedScene:
	var node := Node.new()
	node.name = name
	var packed := PackedScene.new()
	var error := packed.pack(node)
	node.free()
	check(error == OK, "packed dummy scene %s" % name)
	return packed


func _test_content_branches() -> void:
	check(not Content.intro_caption().is_empty(), "departure intro caption is present")
	check(Content.check_entries().size() == 5, "checklist has five entries")
	var slip_count := 0
	for entry in Content.check_entries():
		if entry.get("slip", false):
			slip_count += 1
		check(entry.has("label") and entry.has("list") and entry.has("plate") and entry.has("hand"), "checklist entry includes its display fields")
	check(slip_count == 1, "checklist has exactly one slip")
	for caught in [false, true]:
		for false_alarm in [false, true]:
			var seq: Array = Content.slip_found(caught, false_alarm)
			var last_decision := ""
			for entry in seq:
				if entry.has("choices"):
					last_decision = str(entry.get("key", ""))
			# The authored reassurance after the choice stays in its original position.
			check(not seq.is_empty() and _has_choice(seq, "slip_fix") and last_decision == "slip_fix", "slip_found caught=%s false_alarm=%s ends its decisions with slip-fix choice" % [caught, false_alarm])
	for tone in ["close", "warm"]:
		check(not Content.sky_promise(tone).is_empty(), "sky promise exists for bond tone %s" % tone)
	for fix in [0, 1]:
		check(not Content.mentor_farewell(fix).is_empty(), "mentor farewell exists for slip fix %d" % fix)
		# Issue #37 loop 3: Ashby revisits the box with light, says no box could show it, still doubts.
		var bye: Array = Content.mentor_farewell(fix)
		var at := bye.find(bye.filter(func(l): return l.get("key", "") == "light_box").front())
		check(at > 0 and str(bye[at].t).contains("原子") and str(bye[at + 1].t).contains("不信"), "light in the box comes before Ashby's doubt, slip fix %d" % fix)
		var answers: Array = bye[at].then if at > 0 else []
		check(answers.size() == 2 and str(answers[0][0].t).contains("太陽") and str(answers[1][0].t).contains("量"), "both answers about the light get Ashby's reply, slip fix %d" % fix)
	var montage := Content.montage()
	check(not montage.is_empty(), "departure montage is present")
	for caption in montage:
		check(caption.get("tag", "") in ["HISTORICAL", "FICTION"], "montage caption has a recognized history tag")
	var text: Array[String] = []
	var dialogue: Array = [Content.opening(), Content.before_closing(), Content.sky_promise("close"), Content.sky_promise("warm"),
		Content.slip_found(false, false), Content.slip_found(false, true),
		Content.slip_found(true, false), Content.slip_found(true, true),
		Content.mentor_farewell(0), Content.mentor_farewell(1), Content.principe_workbook("close"),
		Content.principe_workbook("warm")]
	for entry in Content.check_entries():
		dialogue.append(Content.kit_reads(entry))
	for seq in dialogue:
		_collect_text(seq, text)
	for line in text:
		check(not line.contains("喜歡你") and not line.contains("愛"), "departure dialogue contains no confession: %s" % line)


func _test_checklist_logic() -> void:
	var entries: Array = Content.check_entries()
	for slip_rejected in [false, true]:
		for correct_rejected in [false, true]:
			var marks := {}
			for entry in entries:
				marks[entry.id] = true
			marks["s23"] = not slip_rejected
			if correct_rejected:
				marks["s21"] = false
			var result: Dictionary = Checklist.evaluate_marks(entries, marks)
			check(result.get("caught_by_player", false) == slip_rejected, "slip rejection computes caught_by_player")
			check(result.get("false_alarm", false) == correct_rejected, "correct-row rejection computes false_alarm")


func _test_checklist_controls() -> void:
	var layer := CanvasLayer.new()
	root.add_child(layer)
	var sheet = Checklist.new()
	layer.add_child(sheet)
	await process_frame
	sheet.open()
	check(sheet.visible and sheet.entries.size() == 5, "checklist opens with five paper rows")
	check(not sheet.ready_to_mark and sheet.row_buttons[0][0].disabled and sheet.row_buttons[0][1].disabled,
		"checklist marks stay locked before Kit reads a row")
	sheet.begin_read()
	check(sheet.plate_lines[0].text.contains(sheet.entries[0].plate), "Kit readback line shows the plate value")
	sheet.allow_mark()
	check(sheet.ready_to_mark and not sheet.row_buttons[0][0].disabled, "current row becomes markable after readback")
	var completion: Array[Dictionary] = []
	sheet.completed.connect(func(result: Dictionary): completion.append(result))
	for i in sheet.entries.size():
		if i > 0:
			sheet.begin_read()
			sheet.allow_mark()
		sheet._mark(i, i != 2)
	check(completion.size() == 1 and completion[0].caught_by_player, "five checklist marks emit caught result")
	sheet.show_correction(0)
	check(sheet.correction_fix == 0 and sheet.values[2].text.contains("[s]18.63[/s]") and sheet.values[2].text.contains("16.83"),
		"strike-through correction visibly keeps old and corrected values")
	sheet.show_correction(1)
	check(sheet.correction_fix == 1 and sheet.values[2].text.contains("16.83"), "overwrite correction visibly updates the slip row")
	layer.queue_free()
	await process_frame


func _test_story_persistence() -> void:
	await process_frame
	var story := root.get_node_or_null("Story")
	check(is_instance_valid(story), "Story autoload is ready")
	if not is_instance_valid(story):
		return
	story.bond_tone = "close"
	story.slip_fix = 1
	story.departure_done = true
	check(change_scene_to_packed(_packed_dummy("DeparturePersistenceOne")) == OK, "load first persistence scene")
	await process_frame
	check(change_scene_to_packed(_packed_dummy("DeparturePersistenceTwo")) == OK, "load second persistence scene")
	await process_frame
	check(story.bond_tone == "close" and story.slip_fix == 1 and story.departure_done,
		"M2 Story fields survive scene replacement")


func _drain_dialogue(chapter, choices: Dictionary = {}) -> void:
	var guard := 120
	while chapter.ui.dialog_active() and guard > 0:
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("choices"):
			chapter.ui._choose(int(choices.get(str(entry.get("key", "")), 0)))
		else:
			chapter.ui._advance()
		guard -= 1
		await process_frame
	check(guard > 0, "M2 dialogue sequence terminates")


func _test_director_input_and_story() -> void:
	var story = root.get_node("Story")
	story.bond_tone = "warm"
	story.slip_fix = 0
	story.departure_done = true
	story.reset()
	check(story.bond_tone == "" and story.slip_fix == -1 and not story.departure_done,
		"new-game reset clears M2 continuity fields")
	var chapter_script: Script = load("res://scripts/cambridge/departure_director.gd")
	var chapter = chapter_script.new()
	root.add_child(chapter)
	var deadline := Time.get_ticks_msec() + 12000
	while not chapter.ui.dialog_active() and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter.ui.dialog_active(), "departure arrival reaches opening dialogue")
	if not chapter.ui.dialog_active():
		chapter.free()
		return
	await _drain_dialogue(chapter)
	check(chapter.beat == chapter.Beat.CHECKLIST, "opening enables the walk to the light box")
	chapter._interact("lightbox")
	var sheet = chapter.checklist
	check(sheet.visible and not chapter.player.can_move, "checklist modal opens and locks player movement")
	chapter.ui.toggle_pause()
	check(paused and chapter.ui.pause_panel.visible and sheet.visible, "pause overlays an open checklist")
	chapter.ui.toggle_pause()
	chapter.ui.toggle_log()
	check(chapter.ui.log_open() and sheet.visible and not chapter.player.can_move, "history overlays checklist and preserves input lock")
	chapter.ui.toggle_log()
	check(not chapter.ui.log_open() and sheet.visible and not chapter.player.can_move, "closing history keeps checklist input lock")
	for i in sheet.entries.size():
		if chapter.ui.dialog_active():
			await _drain_dialogue(chapter)
		check(sheet.ready_to_mark, "row %d unlocks after Kit readback" % i)
		if i == 0:
			chapter.ui.toggle_log()
			sheet._mark(i, true)
			check(not sheet.marks.has(sheet.entries[i].id), "open dialogue history blocks exposed checklist buttons")
			chapter.ui.toggle_log()
		sheet._mark(i, i != 2)
	if chapter.ui.dialog_active():
		await _drain_dialogue(chapter, {"slip_fix": 0})
	await process_frame
	check(story.slip_fix == 0 and sheet.correction_fix == 0, "strike correction choice updates Story and sheet")
	var correction_deadline := Time.get_ticks_msec() + 5000
	while sheet.continue_btn.disabled and Time.get_ticks_msec() < correction_deadline:
		await process_frame
	check(not sheet.continue_btn.disabled, "correction pause eventually enables checklist continuation")
	sheet.continue_btn.pressed.emit()
	chapter.player.global_position = Vector3(-1.75, 0, 1.4)
	chapter.player.look_at_point(chapter.world.targets.kit)
	chapter.player.rotation.y = chapter.player.yaw
	chapter.player.camera.rotation.x = chapter.player.pitch
	chapter.player.force_update_transform()
	chapter.player.camera.force_update_transform()
	await physics_frame
	await physics_frame
	var kit_target: Node = chapter.player.aimed_interactable()
	check(kit_target != null and str(kit_target.get_meta("interact_id", "")) == "kit",
		"conversation stand ray reaches Kit instead of an overlapping room hotspot (got %s)" % (str(kit_target.get_meta("interact_id", "")) if kit_target else "none"))
	chapter._interact("kit")
	await _drain_dialogue(chapter, {"bond": 0, "promise": 0})
	check(story.bond_tone == "close" and chapter.beat == chapter.Beat.FAREWELL,
		"bond choice sets close tone and advances through promise")
	var date_label: Label3D = chapter.world.workbook.get_meta("date_label")
	check(date_label.visible, "authored sky promise visibly opens the dated workbook page")
	chapter.player.global_position = Vector3(0, 0, 5.0)
	chapter.player.look_at_point(chapter.world.targets.mentor)
	chapter.player.rotation.y = chapter.player.yaw
	chapter.player.camera.rotation.x = chapter.player.pitch
	chapter.player.force_update_transform()
	chapter.player.camera.force_update_transform()
	await physics_frame
	await physics_frame
	var mentor_target: Node = chapter.player.aimed_interactable()
	check(mentor_target != null and str(mentor_target.get_meta("interact_id", "")) == "mentor",
		"corridor stand ray reaches Ashby for the farewell (got %s)" % (str(mentor_target.get_meta("interact_id", "")) if mentor_target else "none"))
	chapter._interact("mentor")
	await _drain_dialogue(chapter, {"gift": 0})
	check(chapter.keepsake.visible, "farewell displays the mentor gift HUD icon")
	check(chapter.keepsake.visible and chapter.beat == chapter.Beat.FAREWELL, "farewell displays the gift before departure")
	chapter.ui.toggle_pause()
	await create_timer(2.1, true, false, true).timeout
	check(paused and chapter.beat == chapter.Beat.FAREWELL, "pause freezes the gift hold before montage")
	chapter.ui.toggle_pause()
	deadline = Time.get_ticks_msec() + 5000
	while chapter.beat != chapter.Beat.MONTAGE and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter.beat == chapter.Beat.MONTAGE, "unpausing resumes departure into montage")
	chapter.ui.toggle_pause()
	var fade_alpha: float = chapter.ui.fade.color.a
	await create_timer(1.1, true, false, true).timeout
	check(paused and is_equal_approx(chapter.ui.fade.color.a, fade_alpha), "pause freezes montage fade")
	chapter.ui.toggle_pause()
	deadline = Time.get_ticks_msec() + 4000
	while (not chapter.ui.caption.text.contains(str(Content.montage()[0].t)) or chapter.ui.caption.modulate.a < 0.5) and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter.ui.caption.text.contains(str(Content.montage()[0].t)), "montage reaches the first departure caption")
	chapter.ui.toggle_pause()
	var caption_text: String = chapter.ui.caption.text
	var caption_alpha: float = chapter.ui.caption.modulate.a
	await create_timer(5.0, true, false, true).timeout
	check(paused and chapter.ui.caption.text == caption_text and is_equal_approx(chapter.ui.caption.modulate.a, caption_alpha), "pause freezes caption timing and prevents the next scene")
	check(not story.departure_done, "paused departure never marks the next chapter ready")
	chapter.ui.toggle_pause()
	chapter.set_process(false)
	for audio in chapter.find_children("*", "AudioStreamPlayer", true, false):
		audio.stop()
	chapter.free()
	await create_timer(0.06, true, false, true).timeout
	await process_frame
	story.reset()


func _run() -> void:
	await process_frame
	_test_content_branches()
	_test_checklist_logic()
	await _test_checklist_controls()
	await _test_story_persistence()
	await _test_director_input_and_story()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
