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
var viewer_signature: Array = []


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


func _viewer_case(chapter) -> void:
	var ui = chapter.ui
	var label := "%s verdict=%d" % [route, verdict]
	check(ui.viewer.visible and not ui.blink_btn.disabled, label + ": playable plate viewer")
	var start: int = ui.viewer_sfx_log.size()
	ui.thumbs.get_child(1).pressed.emit()
	ui.blink_btn.button_pressed = true
	var blink_delta := 1.0 if GameSettings.reduced_motion else 0.5
	ui._process(blink_delta)
	check(ui._blink_oxford, label + ": blink swaps to Oxford")
	ui._process(4.0 * blink_delta)
	ui.blink_btn.button_pressed = false
	ui.include_box.button_pressed = true
	ui.mic_btn.button_pressed = true
	var reading: float = chapter.sim.reading_for_value(1.75)
	ui.set_micrometer_reading(reading)
	await create_timer(0.06, true, false, true).timeout
	ui._nudge_micrometer(1.0, false)
	ui.mic_record_btn.pressed.emit()
	check(chapter.sim.plates[0].read and chapter.sim.plates[0].reading > reading,
		label + ": micrometer moved and recorded a reading")
	ui.measure_btn.pressed.emit()
	ui.report_btn.pressed.emit()
	check(ui._viewer_reporting and ui.dialog_active(), label + ": open report for silent reading")
	var before_reading: int = ui.viewer_sfx_log.size()
	await create_timer(2.0).timeout
	check(ui.viewer_sfx_log.size() == before_reading, label + ": no sound while reading the report")

	var events: Array = ui.viewer_sfx_log.slice(start)
	check(events == ["plate", "blink", "mark", "tick", "tick", "mark", "measure"],
		label + ": one manual blink cue and identical ticks toward and away from the reading; got " + str(events))
	var signature := []
	var measurements: Array[Dictionary] = []
	for event in events:
		var player: AudioStreamPlayer = ui._viewer_sfx[event]
		var wav := player.stream as AudioStreamWAV
		var gain := db_to_linear(player.volume_db)
		var onset := -1
		var peak := 0.0
		var pcm := wav.data
		for i in range(0, pcm.size(), 2):
			var sample := absf(pcm.decode_s16(i) / 32768.0) * gain
			if onset < 0 and sample >= 0.001:
				onset = i / 2
			peak = maxf(peak, sample)
		var sample_id := pcm.hex_encode().sha256_text().left(12)
		signature.append([event, sample_id])
		measurements.append({
			"event": event, "sample": sample_id,
			"onset_ms": snappedf(1000.0 * onset / wav.mix_rate, 0.001),
			"peak_dbfs": snappedf(linear_to_db(peak), 0.01),
		})
	print("[F27 VIEWER] ", label, " ", JSON.stringify(measurements))
	if viewer_signature.is_empty():
		viewer_signature = signature
	check(signature == viewer_signature, label + ": matching viewer events and samples")
	var tools := {}
	for entry in signature:
		if entry[0] in ["plate", "blink", "tick"]:
			tools[entry[1]] = true
	check(tools.size() == 3, label + ": each tool has its own sample")
	var clip_path := OS.get_environment("EDD_VIEWER_CLIP")
	if not clip_path.is_empty() and route == "direct" and verdict == 0 and tools.size() == 3:
		_export_viewer_clip(ui, clip_path)


func _export_viewer_clip(ui, path: String) -> void:
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = ui._viewer_sfx.plate.stream.mix_rate
	var pcm := PackedByteArray()
	pcm.resize(clip.mix_rate / 2 * 2)
	# Audition the three actions once, at their player gains, with space between them.
	for event in ["plate", "blink", "tick"]:
		var player: AudioStreamPlayer = ui._viewer_sfx[event]
		var sample: PackedByteArray = player.stream.data
		var gain := db_to_linear(player.volume_db)
		for i in range(0, sample.size(), 2):
			sample.encode_s16(i, roundi(sample.decode_s16(i) * gain))
		pcm.append_array(sample)
		pcm.resize(pcm.size() + clip.mix_rate / 2 * 2)
	clip.data = pcm
	check(clip.save_to_wav(path) == OK, "write viewer audition clip")


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
				if route == "direct":
					await _viewer_case(chapter)
				else:
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
				MAIN: await _principe(chapter)
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


func _check_october_street_loop() -> void:
	var story := root.get_node("Story")
	story.runs.append({"verdict_class": "underclaim"})
	var chapter: Node = load(OCTOBER).new()
	root.add_child(chapter)
	var street: AudioStreamWAV = chapter.street.stream
	var pcm := street.data
	var seam := street.loop_end * 2
	check(pcm.size() == seam + 2 and pcm.decode_s16(seam - 2) == pcm.decode_s16(0)
		and pcm.decode_s16(seam) == pcm.decode_s16(0),
		"October street loop wraps without a PCM step and has a playable boundary frame")
	chapter.free()
	story.runs.pop_back()


func _run() -> void:
	_check_october_street_loop()
	Engine.max_fps = 30
	Engine.time_scale = 10.0
	for full in [false, true]:
		for choice in 4:
			await _case(full, choice)
	await create_timer(0.2).timeout
	print("test_audio_invariants: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
