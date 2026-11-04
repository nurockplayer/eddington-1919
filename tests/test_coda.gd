extends SceneTree
## Headless contract checks for the M3 coda and its branch selection.
## Run: godot --headless --path . --script res://tests/test_coda.gd

const Coda := preload("res://scripts/content_coda.gd")
const Judgment := preload("res://scripts/judgment.gd")
const MAIN_PATH := "res://scripts/main.gd"
const ScorePlayer := preload("res://scripts/audio/score_player.gd")

class GradeFixture extends RefCounted:
	const EINSTEIN := 1.75
	const HALF := 0.87
	var rule_id := ""
	var evidence := "none"
	var clean := true
	var measured := false
	var plates: Array = []

	func evidence_class() -> String:
		return evidence

	func combined() -> Dictionary:
		return {"n": 1 if measured else 0, "value": 1.75, "sigma": 0.1}

	func selection_report() -> Dictionary:
		return {"omitted_good": [], "included_poor": [], "included_unusable": [], "reselected": not clean,
			"reselect_reason": "", "reselect_added": [], "reselect_removed": [], "reselect_justified": false}

class LegacyGradeFixture extends RefCounted:
	const EINSTEIN := 1.75
	const HALF := 0.87
	var evidence := "favors_e"
	var plates: Array = []

	func evidence_class() -> String:
		return evidence

	func combined() -> Dictionary:
		return {"n": 0, "value": 1.75, "sigma": 0.1}

	func selection_report() -> Dictionary:
		return {"omitted_good": [], "included_poor": [], "included_unusable": [], "reselected": false,
			"reselect_reason": "", "reselect_added": [], "reselect_removed": [], "reselect_justified": false}

signal _wait_completed(finished: bool)

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func _await_or_timeout(sig: Signal, seconds: float) -> bool:
	var timer := create_timer(seconds, true, false, true)
	var on_finished := func(): _wait_completed.emit(true)
	var on_timeout := func(): _wait_completed.emit(false)
	sig.connect(on_finished, CONNECT_ONE_SHOT)
	timer.timeout.connect(on_timeout, CONNECT_ONE_SHOT)
	var finished: bool = await _wait_completed
	if sig.is_connected(on_finished):
		sig.disconnect(on_finished)
	if timer.timeout.is_connected(on_timeout):
		timer.timeout.disconnect(on_timeout)
	return finished


func text_of(seq: Array) -> String:
	var out := ""
	for entry in seq:
		out += str(entry.get("t", "")) + "\n"
	return out


func _test_grade_branches() -> void:
	var legacy_grade: Dictionary = Judgment.grade(LegacyGradeFixture.new(), "hopeful", "uncertain")
	check(legacy_grade.has("fit"), "Judgment.grade returns fit when rule_id is absent")
	# Use actual Judgment.grade outcomes with evidence fixtures that produce each fit.
	var cases := [
		{"fit": 0, "evidence": "favors_e", "telegram": "confirmed", "needle": "電報已經發出去了"},
		{"fit": 1, "evidence": "ambiguous", "telegram": "hopeful", "needle": "電報寫得太小心"},
		{"fit": 2, "evidence": "favors_e", "telegram": "hopeful", "needle": "每一步都寫在紙上了"},
	]
	for branch in cases:
		for clean in [false, true]:
			for measured in [false, true]:
				var fixture := GradeFixture.new()
				fixture.evidence = branch.evidence
				fixture.clean = clean
				fixture.measured = measured
				var grade: Dictionary = Judgment.grade(fixture, branch.telegram, "uncertain")
				check(grade.has("fit"), "Judgment.grade returns fit for GradeFixture")
				if not grade.has("fit"):
					continue
				check(grade.fit == branch.fit, "fixture yields requested judgment fit %d" % branch.fit)
				var text := text_of(Coda.ashby_answer(grade.fit, grade.clean, fixture.combined().n > 0))
				if not measured:
					check(text.contains("只有雲留下的一片灰"), "unmeasured coda branch takes precedence for fit=%d clean=%s" % [grade.fit, clean])
				elif grade.fit == 2 and clean:
					check(text.contains(branch.needle), "fit 2 clean branch selected")
				elif grade.fit == 2:
					check(text.contains("選片那一頁還有一行說不清楚：為什麼留這張、丟那張"), "fit 2 dirty branch selected")
				elif grade.fit == 1:
					check(text.contains("電報寫得太小心"), "fit 1 branch selected")
				else:
					check(text.contains("電報已經發出去了"), "fit 0 branch selected")
	check(text_of(Coda.ashby_answer(2, true, true)).contains("每一步都寫在紙上了"), "fit 2 clean wording identifies complete record")
	check(text_of(Coda.ashby_answer(2, false, true)).contains("把它寫清楚——在他問之前"), "fit 2 dirty wording asks for a correction")
	check(text_of(Coda.ashby_answer(1, true, true)).contains("問號不丟人"), "fit 1 wording retains the question mark")
	check(text_of(Coda.ashby_answer(0, true, true)).contains("差一點就成了那個好故事"), "fit 0 wording recalls Ashby's clean-plate challenge")
	var skipped_text := text_of(Coda.ashby_answer(0, true, false, true))
	check(skipped_text.contains("沒有拿去量") and not skipped_text.contains("一片灰"), "unmeasured usable plates are acknowledged instead of blamed on clouds")
	check(text_of(Coda.ashby_answer(0, true, false, false)).contains("一片灰"), "no usable plates retains the cloud wording")
	# Issue #37 loop 5: the old small doubts return; nothing is called proof.
	check(text_of(Coda.small_numbers(true, true)).contains("14 號") and not text_of(Coda.small_numbers(false, true)).contains("14 號"), "plate 14's residual returns only if it was found")
	check(text_of(Coda.small_numbers(false, true)).contains("也不等於證明") and text_of(Coda.small_numbers(false, false)).contains("沒有數字"), "tonight's numbers are small, not proof; no numbers is still a record")
	for args in [[true, true], [false, false]]:
		check(not text_of(Coda.small_numbers(args[0], args[1])).contains("證明了"), "the coda never claims proof")


func _test_kit_tones() -> void:
	var close_text := text_of(Coda.kit_close("close"))
	var warm_text := text_of(Coda.kit_close("warm"))
	check(close_text.contains("有些話，也許可以等到見了面再說"), "close bond keeps the restrained reunion line")
	check(close_text.contains("也許。") and close_text.contains("你吹熄了燈"), "close bond ends with hesitation and lamp out")
	check(warm_text.contains("Kit 一定會先問天空，再問底片") and not warm_text.contains("你已經想好要怎麼回答了"), "warm bond leaves the answer to the player")
	check(warm_text.contains("你吹熄了燈"), "warm bond ends with lamp out")
	var misread_text := text_of(Coda.kit_close("", 0, false, true))
	check(misread_text.contains("和底片上的不一樣") and not misread_text.contains("只寫了底片上有的"), "a misread telegram does not receive truthful praise")
	check(text_of(Coda.kit_close("", 0, true, true)).contains("寫得比底片上的多"), "overclaiming keeps precedence over misreading")
	check(text_of(Coda.kit_close("", 0)).contains("只寫了底片上有的"), "a truthful telegram retains its existing line")


func _new_main(prologue := false):
	var chapter = load(MAIN_PATH).new()
	var story = root.get_node("Story")
	story.from_prologue = prologue
	root.add_child(chapter)
	await process_frame
	chapter.set_process(false)
	chapter.ui.hide_title()
	return chapter


func _test_direct_and_prologue_paths() -> void:
	var story = root.get_node("Story")
	story.from_prologue = false
	story.prologue_done = true
	story.departure_done = true
	var direct = await _new_main()
	check(not direct._came_from_departure, "direct entry caches a false prologue origin")
	check(not story.prologue_done and not story.departure_done and not story.from_prologue, "direct entry clears stale prologue continuity")
	direct.phase = direct.Phase.NIGHT
	direct.world.lamp.light_energy = 1.1
	direct.world.safelight.light_energy = 0.25
	var starts_before := ScorePlayer.cue_log.filter(func(event): return event.get("event", "") == "start" and event.get("cue", "") == "coda_resolution").size()
	direct._grade = {"title": "direct", "fit": 1, "clean": true, "lines": ["direct response"]}
	direct._pending = "reaction"
	direct._on_dialogue_done({})
	check(direct.phase != direct.Phase.ENDING and direct._busy, "direct reaction starts the lamp-out beat before ending")
	# Sample exactly 0.2 s of tween time, regardless of host frame duration.
	direct._coda_transition.pause()
	direct._coda_transition.custom_step(0.2)
	check(direct.world.lamp.light_energy > 0.0 and direct.world.lamp.light_energy < 1.1, "direct reaction fades the darkroom lamp")
	var direct_lamp_at_pause: float = direct.world.lamp.light_energy
	direct._coda_transition.play()
	direct.ui.log_toggled.emit(true)
	check(not direct._coda_transition.is_running(), "Tab log pauses the direct transition")
	await process_frame
	await process_frame
	check(is_equal_approx(direct.world.lamp.light_energy, direct_lamp_at_pause), "Tab log holds the direct lamp-out beat")
	direct.ui.log_toggled.emit(false)
	direct_lamp_at_pause = direct.world.lamp.light_energy
	direct.ui.toggle_pause()
	await process_frame
	await process_frame
	check(is_equal_approx(direct.world.lamp.light_energy, direct_lamp_at_pause), "Esc pause holds the direct lamp-out beat")
	direct.ui.toggle_pause()
	var direct_finished := await _await_or_timeout(direct._coda_transition.finished, 5.0)
	check(direct_finished, "direct lamp-out beat finishes within 5 s")
	check(direct.phase == direct.Phase.ENDING, "direct lamp-out beat reaches ending")
	var starts_after := ScorePlayer.cue_log.filter(func(event): return event.get("event", "") == "start" and event.get("cue", "") == "coda_resolution").size()
	check(starts_after == starts_before + 1, "direct lamp-out and ending start coda_resolution exactly once")
	check(direct.coda_step == direct.CodaStep.OPENING, "direct 1919 path never advances the coda")
	check(direct.ui.ending_panel.visible and not direct.ui.ending_history.visible, "direct ending screen opens with history collapsed")
	direct.queue_free()
	await process_frame

	var prologue = await _new_main(true)
	check(prologue._came_from_departure, "prologue entry caches its origin before consuming the flag")
	check(not story.from_prologue, "prologue entry consumes the one-shot origin flag")
	prologue.world.lamp.light_energy = 1.1
	prologue.world.safelight.light_energy = 0.25
	prologue._grade = {"title": "prologue", "fit": 2, "clean": true, "lines": ["prologue response"]}
	prologue._pending = "reaction"
	prologue._on_dialogue_done({})
	check(prologue.phase == prologue.Phase.CODA and prologue.coda_step == prologue.CodaStep.OPENING, "prologue reaction enters coda before ending")
	check(is_instance_valid(prologue._night_departure_workbook), "coda ensures workbook exists")
	prologue._interact("mentor_loupe")
	check(prologue.coda_step == prologue.CodaStep.OPENING, "loupe cannot skip opening or workbook")
	prologue._on_dialogue_done({})
	check(prologue.coda_step == prologue.CodaStep.WORKBOOK, "opening advances to required workbook")
	prologue._interact("departure_workbook")
	check(prologue._departure_workbook_seen and prologue._pending == "coda_workbook", "unwritten workbook interaction plays required writing beat")
	prologue._on_dialogue_done({})
	check(prologue.coda_step == prologue.CodaStep.LOUPE, "workbook completion unlocks loupe")
	prologue._interact("departure_workbook")
	check(prologue._pending == "", "workbook cannot replay after its coda action")
	# Found in the viewer after a report that still says not_found (revised later): clues win.
	story.clues["residual"] = true
	story.report["residual"] = "not_found"
	prologue._interact("mentor_loupe")
	check(prologue.coda_step == prologue.CodaStep.KIT and prologue._pending == "coda_loupe", "loupe interaction plays Ashby answer and unlocks Kit beat")
	var loupe_text := text_of(prologue.ui._seq)
	check(loupe_text.contains("放大鏡") and loupe_text.contains("關緊的箱子"), "the loupe beat carries the small numbers after Ashby's answer")
	check(loupe_text.contains("14 號"), "the found residual returns even if a stale report says not_found")
	story.clues.erase("residual")
	story.report.erase("residual")
	prologue._on_dialogue_done({})
	check(prologue._pending == "coda_kit", "Ashby response advances to Kit close")
	prologue._on_dialogue_done({"kit_first": 0})
	check(prologue.coda_step == prologue.CodaStep.FADING and prologue._busy, "Kit close starts the lamp-out fade")
	check(prologue._coda_transition != null and prologue._coda_transition.is_running(), "coda fade has an active tween")
	if prologue._coda_transition and prologue._coda_transition.is_valid():
		prologue._coda_transition.pause()
		prologue._coda_transition.custom_step(0.2)
		prologue._coda_transition.play()
		prologue.ui.log_toggled.emit(true)
		var lamp_at_pause: float = prologue.world.lamp.light_energy
		check(not prologue._coda_transition.is_running(), "Tab log pauses the coda transition")
		await process_frame
		await process_frame
		check(is_equal_approx(prologue.world.lamp.light_energy, lamp_at_pause), "Tab log pauses the coda fade")
		prologue.ui.log_toggled.emit(false)
		check(prologue._coda_transition.is_running(), "closing Tab log resumes the coda fade")
		# Reach the screen-fade segment using simulated tween time.
		prologue._coda_transition.pause()
		prologue._coda_transition.custom_step(0.5)
		prologue._coda_transition.custom_step(0.6)
		prologue._coda_transition.custom_step(0.3)
		prologue._coda_transition.play()
		check(prologue.ui.fade.color.a > 0.0 and prologue.ui.fade.color.a < 1.0, "coda screen fade is in progress before Esc pause")
		var lamp_at_tree_pause: float = prologue.world.lamp.light_energy
		var safelight_at_tree_pause: float = prologue.world.safelight.light_energy
		var fade_at_tree_pause: float = prologue.ui.fade.color.a
		prologue.ui.toggle_pause()
		await process_frame
		await process_frame
		check(is_equal_approx(prologue.world.lamp.light_energy, lamp_at_tree_pause), "Esc pause holds the coda lamp transition")
		check(is_equal_approx(prologue.world.safelight.light_energy, safelight_at_tree_pause), "Esc pause holds the coda safelight transition")
		check(is_equal_approx(prologue.ui.fade.color.a, fade_at_tree_pause), "Esc pause holds the coda screen fade")
		check(prologue.phase == prologue.Phase.CODA and prologue.coda_step == prologue.CodaStep.FADING and prologue._busy, "Esc pause keeps coda before ending")
		prologue.ui.toggle_pause()
		var prologue_finished := await _await_or_timeout(prologue._coda_transition.finished, 5.0)
		check(prologue_finished, "prologue coda fade finishes within 5 s")
	check(prologue.phase == prologue.Phase.ENDING and prologue.ui.ending_panel.visible, "prologue coda fade reaches ending")
	check(is_equal_approx(prologue.world.lamp.light_energy, 0.0) and is_equal_approx(prologue.world.safelight.light_energy, 0.0), "resumed coda fade extinguishes both lamps")
	check(is_equal_approx(prologue.ui.fade.color.a, 0.0), "ending clears the completed coda screen fade")
	prologue.queue_free()
	await process_frame

	var reread = await _new_main()
	reread.phase = reread.Phase.CODA
	reread.coda_step = reread.CodaStep.WORKBOOK
	reread._departure_workbook_seen = true
	reread._add_night_workbook()
	reread._interact("departure_workbook")
	check(reread.ui.text_label.text.contains("又讀了一遍工作簿最後一頁"), "previously written workbook plays reread beat")
	reread.queue_free()
	await process_frame

	# astra M3 P2: a workbook written during the night must not block the loupe in the coda.
	var auto = await _new_main()
	auto.phase = auto.Phase.CODA
	auto._departure_workbook_seen = true
	auto._add_night_workbook()
	auto._pending = "coda_opening"
	auto._on_dialogue_done({})
	check(auto._pending == "coda_workbook" and auto.ui.text_label.text.contains("又讀了一遍工作簿最後一頁"), "already-written workbook rereads automatically after the coda opening")
	auto.queue_free()
	await process_frame


func _test_sky_promise_payoff() -> void:
	var story = root.get_node("Story")
	var lines := ["（出發前我要 Kit 告訴我，劍橋這段時間變了什麼。她大概已經記了一整頁。）", "（我跟 Kit 說過，全食那五分鐘我會在換底片。她會想知道，那五分鐘裡底片上留下了什麼。）"]
	for choice in 2:
		story.reset()
		var departure = load("res://scripts/cambridge/departure_director.gd").new()
		root.add_child(departure)
		while not departure.ui.dialog_active():
			await process_frame
		departure._say(preload("res://scripts/cambridge/content_departure.gd").sky_promise("warm"), "promise")
		while departure.ui.dialog_active():
			var entry: Dictionary = departure.ui._seq[departure.ui._seq_i]
			if entry.get("key", "") == "promise":
				departure.ui._choose(choice)
			else:
				departure.ui._advance()
		check(story.sky_promise == choice, "departure dialogue stores promise %d" % choice)
		departure.queue_free()
		await process_frame
		var chapter = await _new_main(true)
		chapter._grade = Judgment.grade(chapter.sim, "confirmed", "uncertain")
		chapter._pending = "reaction"
		chapter._on_dialogue_done({})
		while chapter.ui.dialog_active():
			chapter.ui._advance()
		chapter._interact("departure_workbook")
		while chapter.ui.dialog_active():
			chapter.ui._advance()
		chapter._interact("mentor_loupe")
		while chapter.ui._seq[chapter.ui._seq_i].get("key", "") != "kit_first":
			chapter.ui._advance()
		var seq: Array = chapter.ui._seq
		var payoff := seq.find_custom(func(entry): return entry.get("t", "") == lines[choice] and entry.get("s", "") == Coda.YOU)
		check(payoff >= 0 and payoff == chapter.ui._seq_i - 1 and not text_of(seq).contains(lines[1 - choice]), "matching player recollection immediately precedes the choice for promise %d" % choice)
		chapter.queue_free()
		await process_frame
	var direct = await _new_main(false)
	check(story.sky_promise == -1, "direct entry clears the promise")
	var direct_text := text_of(Coda.kit_close(story.bond_tone, story.kit_choice, false, false, true, story.sky_promise))
	check(not direct_text.contains(lines[0]) and not direct_text.contains(lines[1]), "direct entry has neither payoff")
	direct.queue_free()
	await process_frame
	story.sky_promise = 1
	story.reset()
	check(story.sky_promise == -1, "Story reset clears the promise")


func _test_kit_first_choices() -> void:
	var story = root.get_node("Story")
	var replies := ["雲在最後才薄下去，我一直看著。", "數字很小，範圍很寬，我還不能說得更確定。", "我今天也犯了一個錯，回去再慢慢告訴你。"]
	for choice in 3:
		# Drive the actual coda dialogue, including its then reply and done signal.
		var chapter = await _new_main(true)
		chapter.ui.history.clear()  # History is static across chapter instances.
		chapter._telegram = 0  # An overclaim: the mistake answer is available.
		chapter._grade = Judgment.grade(chapter.sim, "confirmed", "uncertain")
		var grade_before: Dictionary = chapter._grade.duplicate(true)
		chapter._pending = "reaction"
		chapter._on_dialogue_done({})
		while chapter.ui.dialog_active():
			chapter.ui._advance()
		chapter._interact("departure_workbook")
		while chapter.ui.dialog_active():
			chapter.ui._advance()
		chapter._interact("mentor_loupe")
		while chapter.ui._seq[chapter.ui._seq_i].get("key", "") != "kit_first":
			chapter.ui._advance()
		check(chapter._pending == "coda_kit" and chapter.ui.text_label.text == "（見到 Kit，第一句話要說什麼？）", "coda reaches the Kit choice")
		check(chapter.ui._seq[chapter.ui._seq_i].choices == ["先說天空：雲在最後才薄下去。", "先說不確定：數字很小，範圍很寬。", "先說錯誤：我今天也犯了一個錯。"], "three authored answers appear")
		check(story.kit_first == -1 and chapter._coda_transition == null, "choice waits before storing or fading")
		chapter.ui._choose(choice)
		check(chapter.ui.speaker_label.text == Coda.YOU and chapter.ui.text_label.text == replies[choice], "choice %d shows its player reply" % choice)
		chapter.ui._advance()
		check(chapter.ui.text_label.text == "（你吹熄了燈。）", "reply is followed by the lamp-out line")
		chapter.ui._advance()
		check(story.kit_first == choice, "dialogue completion stores Kit choice %d" % choice)
		var line: String = "給 Kit：" + replies[choice]
		check(chapter._night_departure_workbook.kit_line == line and chapter._night_departure_workbook.get_node("WorkbookKitLine").text == line, "night workbook page shows the exact reply")
		check(text_of(Coda.workbook_again(chapter._night_departure_workbook.kit_line)).count(line) == 1, "workbook reread includes the reply once")
		var transition: Tween = chapter._coda_transition
		chapter._on_dialogue_done({})
		check(chapter._coda_transition == transition, "a repeated done signal cannot restart lamp-out")
		transition.pause()
		transition.custom_step(0.7)
		transition.custom_step(0.6)
		transition.custom_step(1.3)
		check(chapter.phase == chapter.Phase.ENDING, "Kit choice reaches ending through lamp-out")
		check(chapter.ui.ending_text.text.count(line) == 1 and chapter.ui.ending_text.text.contains("[color=#8f8676]本子上："), "ending tableau includes the dim workbook line once")
		check(chapter.ui.history.filter(func(entry): return entry.contains("（你吹熄了燈。）")).size() == 1, "lamp-out dialogue happens once")
		check(chapter._grade == grade_before, "Kit choice leaves grading unchanged")
		chapter.queue_free()
		await process_frame
	# Only a clean, correctly read, non-overclaimed run gets the star chart.
	for args in [[false, false, true], [true, false, true], [false, true, true], [false, false, false]]:
		var seq: Array = Coda.kit_close("warm", 2, args[0], args[1], args[2])
		var decision: Dictionary = seq[-2]
		var no_mistake: bool = not args[0] and not args[1] and args[2]
		check(decision.choices[2] == ("先說那張星圖。" if no_mistake else "先說錯誤：我今天也犯了一個錯。"), "third option follows all three mistake conditions")
	# Exercise the clean third answer through the real UI and ending as well.
	var clean = await _new_main(true)
	check(story.kit_first == -1, "new run clears the previous Kit answer")
	clean._telegram = 3
	clean._grade = Judgment.grade(clean.sim, "none", "nostars")
	clean._begin_coda()
	clean._pending = "coda_loupe"
	clean._on_dialogue_done({})
	while clean.ui._seq[clean.ui._seq_i].get("key", "") != "kit_first":
		clean.ui._advance()
	check(clean.ui._seq[clean.ui._seq_i].choices[2] == "先說那張星圖。", "clean real run offers the star chart")
	clean.ui._choose(2)
	check(clean.ui.text_label.text == "我還記得小時候那張星圖。", "clean third answer has its own reply")
	clean.ui._advance()
	clean.ui._advance()
	var clean_line := "給 Kit：我還記得小時候那張星圖。"
	check(story.kit_first == 2 and clean._night_departure_workbook.kit_line == clean_line, "clean answer is stored in Story and workbook")
	clean._coda_transition.pause()
	clean._coda_transition.custom_step(0.7)
	clean._coda_transition.custom_step(0.6)
	clean._coda_transition.custom_step(1.3)
	check(clean.ui.ending_text.text.contains(clean_line), "clean third answer reaches the tableau")
	clean.queue_free()
	await process_frame
	story.reset()
	check(story.kit_first == -1, "Story reset clears Kit first words")


func _test_rules_before_viewer() -> void:
	var chapter = await _new_main()
	chapter.phase = chapter.Phase.NIGHT
	chapter._interact("measure")
	check(chapter.ui.dialog_active() and not chapter.ui.viewer.visible, "night measurement asks for a rule before opening the viewer")
	chapter._pending = "rules"
	chapter._on_dialogue_done({"rule": 0})
	check(chapter.sim.rule_id == "strict" and chapter.ui.viewer.visible, "finishing the rule dialogue records strict and opens the viewer")
	chapter.queue_free()
	await process_frame


func _test_unmeasured_usable_coda() -> void:
	var chapter = await _new_main(true)
	root.get_node("Story").kit_choice = 0
	chapter.sim.open_shutter(199.0)
	chapter.sim.accumulate(10.0, 0.0)
	var plate: Dictionary = chapter.sim.close_shutter()
	check(plate.usable and chapter.sim.combined().n == 0, "real exposure produces a usable plate left unmeasured")
	chapter._telegram = 3  # CLOUD. NO RESULTS.
	chapter._grade = Judgment.grade(chapter.sim, "none", "nostars")
	check(chapter._grade.fit == 0, "no-results telegram is wrong when a usable plate was ignored")
	chapter.phase = chapter.Phase.CODA
	chapter.coda_step = chapter.CodaStep.LOUPE
	chapter._interact("mentor_loupe")
	var loupe_text := text_of(chapter.ui._seq)
	check(loupe_text.contains("沒有拿去量") and not loupe_text.contains("一片灰"), "main passes usable plates into Ashby's answer")
	chapter._on_dialogue_done({})
	var kit_text := text_of(chapter.ui._seq)
	check(kit_text.contains("和底片上的不一樣") and not kit_text.contains("只寫了底片上有的"), "main passes the wrong non-confirmed telegram into Kit's close")
	chapter.queue_free()
	await process_frame


func _test_replay_keeps_prologue_origin() -> void:
	# Codex review (PR #12): a 1919 replay after the prologue must keep the coda and continuity.
	var story = root.get_node("Story")
	var main_script: Script = load(MAIN_PATH)
	var first = await _new_main(true)
	story.bond_tone = "close"
	story.sky_promise = 1
	story.kit_first = 2
	story.departure_done = true
	check(first._came_from_departure, "prologue run caches its origin")
	main_script.replay_from_prologue = first._came_from_departure  # what _restart() stores before reloading
	first.queue_free()
	await process_frame
	var replay = await _new_main(false)
	check(replay._came_from_departure, "1919 replay keeps the prologue origin")
	check(story.kit_first == -1, "1919 replay clears only the previous run Kit answer")
	check(story.bond_tone == "close" and story.sky_promise == 1 and story.departure_done, "1919 replay keeps Story continuity (bond tone, departure)")
	check(not main_script.replay_from_prologue, "replay origin is consumed once")
	check(replay.has_node("AshbyLoupeHotspot"), "1919 replay still places Ashby's loupe")
	replay._grade = {"title": "replay", "fit": 2, "clean": true, "lines": ["replay response"]}
	replay._pending = "reaction"
	replay._on_dialogue_done({})
	check(replay.phase == replay.Phase.CODA, "1919 replay reaches the coda again")
	replay.queue_free()
	await process_frame
	var direct = await _new_main(false)
	check(not direct._came_from_departure and story.bond_tone == "", "a later direct launch without a replay flag still resets Story")
	direct.queue_free()
	await process_frame


func _run() -> void:
	_test_grade_branches()
	_test_kit_tones()
	await _test_sky_promise_payoff()
	await _test_kit_first_choices()
	await _test_rules_before_viewer()
	await _test_direct_and_prologue_paths()
	await _test_unmeasured_usable_coda()
	await _test_replay_keeps_prologue_origin()
	# Headless teardown: AudioServer releases the freed chapter's ambient playback
	# asynchronously; drain it so exit does not report leaked AudioStreamWAV objects.
	await create_timer(0.1).timeout
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
