extends SceneTree
## F22: real chapter handoffs and dialogue choices, both routes x four verdicts.
## Headless disables waveform playback in ScorePlayer, but retains every cue start.
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const MAIN := "res://scripts/main.gd"
const CAMBRIDGE := "res://scripts/cambridge/director.gd"
const DEPARTURE := "res://scripts/cambridge/departure_director.gd"
const OCTOBER := "res://scripts/cambridge/epilogue_director.gd"
var checks := 0
var failures := 0
var starts: Array[Dictionary] = []
var log_index := 0
var route := ""
var verdict := -1
var submitted := false


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _capture() -> void:
	var chapter := current_scene
	if not is_instance_valid(chapter):
		return
	var script: String = chapter.get_script().resource_path
	for i in range(log_index, ScorePlayer.cue_log.size()):
		var event: Dictionary = ScorePlayer.cue_log[i]
		if event.event != "start":
			continue
		var ending := false
		if script == MAIN:
			ending = not chapter._came_from_departure and (chapter.phase == chapter.Phase.ENDING or chapter._coda_transition != null)
		elif script == OCTOBER:
			ending = chapter.beat == chapter.Beat.ENDING
		var entry := {"cue": event.cue, "scene": script, "ending": ending,
			"submitted": submitted, "route": route, "verdict": verdict}
		starts.append(entry)
		print("[F22 START] ", JSON.stringify(entry))
	log_index = ScorePlayer.cue_log.size()


func _talk(chapter) -> void:
	var guard := 150
	while chapter.ui.dialog_active() and guard > 0:
		guard -= 1
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("choices"):
			var key: String = entry.get("key", "")
			var pick := 1 if key == "revise_report" else 0
			if key == "verdict":
				_capture() # A cue before the player's choice is still pre-verdict.
				pick = verdict
				submitted = true
			chapter.ui._choose(pick)
		else:
			chapter.ui._advance()
		_capture()
	assert(guard > 0, "F22 dialogue did not terminate")


func _box(box) -> void:
	if box.input_blocked:
		return
	if box.mode == "light" and root.get_node("Story").light_guess < 0:
		box.guess_btns[0].pressed.emit()
	elif not box.next_btn.disabled:
		box.next_btn.pressed.emit()
	elif box.mode == "light" and box._played[box.view]:
		box.frame_btns[1 if box.view == "outside" else 0].pressed.emit()
	elif not box.release_btn.disabled:
		box.release_btn.pressed.emit()


func _cambridge(chapter) -> void:
	if chapter.box_sketch.visible:
		_box(chapter.box_sketch)
	elif chapter._busy:
		return
	elif chapter.report_sheet.visible:
		chapter.report_sheet.submit_btn.pressed.emit()
	elif chapter.plan_board.visible:
		var board = chapter.plan_board
		for card in ["comparison", "far_stars", "rules_first"]:
			if not board.selected.has(card):
				board.card_buttons[card].pressed.emit()
				return
		board.finish_btn.pressed.emit()
	else:
		match chapter.beat:
			chapter.Beat.INVESTIGATE: chapter._interact("notebook")
			chapter.Beat.ORRERY: chapter._interact("orrery")
			chapter.Beat.TRIAL_TASK: chapter._interact("cabinet")


func _departure(chapter) -> void:
	if chapter.box_sketch.visible:
		_box(chapter.box_sketch)
	elif chapter._busy:
		return
	elif chapter.checklist.visible:
		var list = chapter.checklist
		if list.ready_to_mark and not list.input_blocked:
			var i: int = list.active_index
			list.row_buttons[i][1 if list.entries[i].get("slip", false) else 0].pressed.emit()
		elif list.continue_btn.visible and not list.continue_btn.disabled:
			list.continue_btn.pressed.emit()
	else:
		match chapter.beat:
			chapter.Beat.CHECKLIST: chapter._interact("lightbox")
			chapter.Beat.KIT: chapter._interact("kit")
			chapter.Beat.FAREWELL: chapter._interact("mentor")


func _principe(chapter) -> void:
	# Advance the real totality clock explicitly; this avoids waiting minutes or
	# depending on random clouds. Only the exposure's sky sample is fixed clear.
	chapter.set_process(false)
	if chapter._verdict_hold_s > 0.0:
		# This driver owns the clock, including the report's silent interval.
		chapter._process(0.0)
		chapter._process(1.5)
		return
	if chapter._busy:
		return
	match chapter.phase:
		chapter.Phase.PREP:
			if not chapter.sim.briefed:
				chapter._interact("eddington")
			else:
				chapter._hold_complete("drive")
				chapter._hold_complete("chronometer")
				chapter._interact("eddington")
		chapter.Phase.TOTALITY:
			if not chapter.tot_done:
				chapter._process_totality(2.1)
				chapter.sim.open_shutter(199.0)
				chapter.sim.accumulate(10.0, 0.0)
				chapter.sim.close_shutter()
				chapter._process_totality(chapter.sim.TOTALITY_S / chapter.sim.TIME_SCALE)
		chapter.Phase.NIGHT:
			if not chapter.sim.measured:
				chapter._interact("oxford_case")
				_talk(chapter)
				chapter._interact("measure")
				_talk(chapter)
				chapter.ui.plate_toggled.emit(0, true)
				chapter.ui.reading_set.emit(0, chapter.sim.reading_for_value(1.75))
				chapter.ui.measure_pressed.emit()
				chapter.ui.report_pressed.emit()
		chapter.Phase.CODA:
			match chapter.coda_step:
				chapter.CodaStep.WORKBOOK: chapter._interact("departure_workbook")
				chapter.CodaStep.LOUPE: chapter._interact("mentor_loupe")


func _october(chapter) -> void:
	if chapter._busy:
		return
	if chapter.chart.visible:
		if chapter.chart.step == 3 and chapter.chart.read_answer < 0:
			chapter.chart.choices[1].pressed.emit()
		else:
			chapter.chart.button.pressed.emit()
	else:
		match chapter.beat:
			chapter.Beat.LETTER: chapter._interact("letter")
			chapter.Beat.ORRERY: chapter._interact("orrery")


func _case(full: bool, choice: int) -> void:
	route = "full" if full else "direct"
	verdict = choice
	submitted = false
	starts.clear()
	ScorePlayer.cue_log.clear()
	log_index = 0
	root.get_node("Story").reset()
	assert(change_scene_to_file("res://scenes/main.tscn") == OK)
	await process_frame
	await process_frame
	if full:
		current_scene.ui.prologue_pressed.emit()
	else:
		current_scene.ui.start_pressed.emit()
	var visited: Array[String] = []
	var deadline := Time.get_ticks_msec() + 120000
	var finished := false
	while Time.get_ticks_msec() < deadline:
		await process_frame
		_capture()
		var chapter := current_scene
		if not is_instance_valid(chapter):
			continue
		var script: String = chapter.get_script().resource_path
		if not visited.has(script):
			visited.append(script)
		if chapter.ui.ending_panel.visible:
			finished = true
			break
		if chapter.ui.dialog_active():
			_talk(chapter)
		else:
			match script:
				CAMBRIDGE: _cambridge(chapter)
				DEPARTURE: _departure(chapter)
				MAIN: _principe(chapter)
				OCTOBER: _october(chapter)
		_capture()
	var label := "%s verdict=%d" % [route, verdict]
	check(finished and submitted and root.get_node("Story").runs.back().verdict == choice, label + ": real route reaches ending after verdict")
	check(visited == [CAMBRIDGE, DEPARTURE, MAIN, OCTOBER] if full else visited == [MAIN], label + ": chapter route")
	var resolutions := starts.filter(func(e): return e.cue == "coda_resolution")
	check(resolutions.size() == 1, label + ": resolution starts exactly once")
	check(resolutions.all(func(e): return e.submitted), label + ": no resolution before verdict")
	check(resolutions.all(func(e): return e.ending and e.scene == (OCTOBER if full else MAIN)), label + ": resolution belongs to route ending")
	check(starts.all(func(e): return not e.submitted or (e.cue == "coda_resolution" and e.ending)), label + ": no verdict win sting")
	# A second ending notification after the one-shot has stopped must not replay it.
	current_scene.score.stop("coda_resolution")
	current_scene.ui.dialogue_done.emit({})
	await create_timer(1.5).timeout
	_capture()
	check(starts.filter(func(e): return e.cue == "coda_resolution").size() == 1, label + ": repeated ending cannot replay resolution")
	current_scene.free()
	current_scene = null
	await process_frame


func _run() -> void:
	Engine.max_fps = 30
	Engine.time_scale = 10.0
	for full in [false, true]:
		for choice in 4:
			await _case(full, choice)
	await create_timer(0.2).timeout
	print("test_audio_invariants: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
