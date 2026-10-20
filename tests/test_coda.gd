extends SceneTree
## Headless contract checks for the M3 coda and its branch selection.
## Run: godot --headless --path . --script res://tests/test_coda.gd

const Coda := preload("res://scripts/content_coda.gd")
const Judgment := preload("res://scripts/judgment.gd")
const MAIN_PATH := "res://scripts/main.gd"

class GradeFixture extends RefCounted:
	var evidence := "none"
	var clean := true
	var measured := false
	var plates: Array = []

	func evidence_class() -> String:
		return evidence

	func combined() -> Dictionary:
		return {"n": 1 if measured else 0, "value": 1.75, "sigma": 0.1}

	func selection_report() -> Dictionary:
		return {"omitted_good": [], "included_poor": [], "included_unusable": [], "reselected": not clean}

var failures := 0
var checks := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func text_of(seq: Array) -> String:
	var out := ""
	for entry in seq:
		out += str(entry.get("t", "")) + "\n"
	return out


func _test_grade_branches() -> void:
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
				check(grade.fit == branch.fit, "fixture yields requested judgment fit %d" % branch.fit)
				var text := text_of(Coda.ashby_answer(grade.fit, grade.clean, fixture.combined().n > 0))
				if not measured:
					check(text.contains("只有雲留下的一片灰"), "unmeasured coda branch takes precedence for fit=%d clean=%s" % [grade.fit, clean])
				elif grade.fit == 2 and clean:
					check(text.contains(branch.needle), "fit 2 clean branch selected")
				elif grade.fit == 2:
					check(text.contains("選片那一頁，有一行你寫得不夠乾淨"), "fit 2 dirty branch selected")
				elif grade.fit == 1:
					check(text.contains("電報寫得太小心"), "fit 1 branch selected")
				else:
					check(text.contains("電報已經發出去了"), "fit 0 branch selected")
	check(text_of(Coda.ashby_answer(2, true, true)).contains("每一步都寫在紙上了"), "fit 2 clean wording identifies complete record")
	check(text_of(Coda.ashby_answer(2, false, true)).contains("把它補上"), "fit 2 dirty wording asks for a correction")
	check(text_of(Coda.ashby_answer(1, true, true)).contains("問號不丟人"), "fit 1 wording retains the question mark")
	check(text_of(Coda.ashby_answer(0, true, true)).contains("差一點就成了那個好故事"), "fit 0 wording recalls Ashby's clean-plate challenge")


func _test_kit_tones() -> void:
	var close_text := text_of(Coda.kit_close("close"))
	var warm_text := text_of(Coda.kit_close("warm"))
	check(close_text.contains("有些話，也許可以等到見了面再說"), "close bond keeps the restrained reunion line")
	check(close_text.contains("也許。") and close_text.contains("你吹熄了燈"), "close bond ends with hesitation and lamp out")
	check(warm_text.contains("Kit 一定會先問天空，再問底片"), "warm bond anticipates Kit's question")
	check(warm_text.contains("你吹熄了燈"), "warm bond ends with lamp out")


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
	direct._grade = {"title": "direct", "fit": 1, "clean": true, "lines": ["direct response"]}
	direct._pending = "reaction"
	direct._on_dialogue_done({})
	check(direct.phase == direct.Phase.ENDING, "direct 1919 reaction proceeds straight to ending")
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
	prologue._interact("mentor_loupe")
	check(prologue.coda_step == prologue.CodaStep.KIT and prologue._pending == "coda_loupe", "loupe interaction plays Ashby answer and unlocks Kit beat")
	prologue._on_dialogue_done({})
	check(prologue._pending == "coda_kit", "Ashby response advances to Kit close")
	prologue._on_dialogue_done({})
	check(prologue.coda_step == prologue.CodaStep.FADING and prologue._busy, "Kit close starts the lamp-out fade")
	if prologue._coda_transition and prologue._coda_transition.is_valid():
		prologue.ui.log_toggled.emit(true)
		var lamp_at_pause: float = prologue.world.lamp.light_energy
		await create_timer(3.0, true, false, true).timeout
		check(is_equal_approx(prologue.world.lamp.light_energy, lamp_at_pause), "Tab log pauses the coda fade")
		prologue.ui.log_toggled.emit(false)
		check(prologue._coda_transition.is_running(), "closing Tab log resumes the coda fade")
		var lamp_at_tree_pause: float = prologue.world.lamp.light_energy
		var safelight_at_tree_pause: float = prologue.world.safelight.light_energy
		var fade_at_tree_pause: float = prologue.ui.fade.color.a
		prologue.ui.toggle_pause()
		await create_timer(3.0, true, false, true).timeout
		check(is_equal_approx(prologue.world.lamp.light_energy, lamp_at_tree_pause), "Esc pause holds the coda lamp transition")
		check(is_equal_approx(prologue.world.safelight.light_energy, safelight_at_tree_pause), "Esc pause holds the coda safelight transition")
		check(is_equal_approx(prologue.ui.fade.color.a, fade_at_tree_pause), "Esc pause holds the coda screen fade")
		check(prologue.phase == prologue.Phase.CODA and prologue.coda_step == prologue.CodaStep.FADING and prologue._busy, "three seconds of Esc pause keep coda before ending")
		prologue.ui.toggle_pause()
	var deadline := Time.get_ticks_msec() + 5000
	while prologue.phase != prologue.Phase.ENDING and Time.get_ticks_msec() < deadline:
		await process_frame
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


func _run() -> void:
	_test_grade_branches()
	_test_kit_tones()
	await _test_direct_and_prologue_paths()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
