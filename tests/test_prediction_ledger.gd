extends SceneTree
## Conversion arc move A — the prediction ledger. The player writes a guess
## (0 / 0.87 / 1.75 / 說不準) and a confidence in 1917; Ashby writes 0.87.
## In 1919 the ledger returns before Measure (keep or change), is set against
## the player's own 2σ range after the interval answer, and is recalled in the
## ending and the coda. No prologue, no recall.
const DIRECTOR := "res://scripts/cambridge/director.gd"
const MAIN_PATH := "res://scripts/main.gd"
const C17 := preload("res://scripts/cambridge/content_1917.gd")
const Content := preload("res://scripts/content.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Coda := preload("res://scripts/content_coda.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	var story: Node = root.get_node("Story")
	await _test_1917_bet(story)
	await _test_1919_keep(story)
	await _test_1919_change(story)
	var fresh = await _test_1919_fresh(story)
	await _test_measure_reentry(fresh)
	fresh.stop_all_audio()
	fresh.queue_free()
	await process_frame
	await _test_replay_page(story)
	await _test_confrontation_flow(story)
	_test_confrontation()
	await _test_ending_and_coda(story)
	story.reset()
	check(story.bet.is_empty() and story.bet_1917.is_empty(), "Story.reset clears the prediction ledger and the 1917 page")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _text(node) -> String:
	var out := ""
	for entry in node.ui._seq:
		out += str(entry.get("t", "")) + "\n"
	return out


func _new_game(story: Node, played: bool, bet: Dictionary, from_prologue := false) -> Node:
	# Origin flags are read in _ready before Story is reset, so set them first.
	story.from_prologue = from_prologue
	var game = load(MAIN_PATH).new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.ui.hide_title()
	# main._ready resets Story outside a prologue run, so set it afterwards.
	story.prologue_done = played
	story.bet = bet.duplicate(true)
	story.bet_1917 = bet.duplicate(true) if played and not bet.is_empty() else {}
	game.phase = game.Phase.NIGHT
	return game


## 1917: Ashby's note is followed by the player's own entry and confidence.
func _test_1917_bet(story: Node) -> void:
	story.reset()
	var chapter = load(DIRECTOR).new()
	root.add_child(chapter)
	var deadline := Time.get_ticks_msec() + 12000
	while chapter._pending != "opening" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter._pending == "opening", "Cambridge reaches the opening dialogue within 12 s")
	chapter._say(C17.mentor_dyson({}, chapter.state()), "dyson")
	var guard := 200
	while chapter.ui.dialog_active() and guard > 0:
		guard -= 1
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("choices"):
			var key: String = entry.get("key", "")
			chapter.ui._choose(2 if key == "bet" else (1 if key == "bet_sure" else 0))
		else:
			chapter.ui._advance()
		await process_frame
	check(guard > 0 and not chapter.ui.dialog_active(), "the 1917 mentor dialogue completes")
	check(story.bet.get("pick", -1) == 2, "the 1917 pick (1.75) is kept in Story.bet")
	check(story.bet.get("sure", -1) == 1, "the 1917 confidence (有點把握) is kept in Story.bet")
	check(story.bet.get("ashby", 0) == 1 and story.bet.get("year", 0) == 1917,
		"Ashby's own 1917 entry is marked for 1919 and the coda")
	check(story.bet_1917.get("pick", -1) == 2, "the 1917 page is kept separately for replays")
	chapter.free()
	await process_frame


func _test_1919_keep(story: Node) -> void:
	var game = await _new_game(story, true, {"pick": 2, "sure": 1, "ashby": 1, "year": 1917})
	story.plan = ["comparison"]
	game._interact("measure")
	check(game._pending == "rules", "measure still asks for the rule first")
	game.ui._choose(0)
	check(game._pending == "bet" and game.ui.dialog_active(), "the rule is followed by the prediction, not the plates")
	var text := _text(game)
	check(text.contains("你寫的是 1.75") and text.contains("有點把握"),
		"the 1919 prompt recalls the 1917 pick and confidence")
	game.ui._advance()  # the recall line precedes the keep/change choice
	var entry: Dictionary = game.ui._seq[game.ui._seq_i]
	check(entry.get("key", "") == "bet_keep" and entry.get("choices", []).size() == 5,
		"keeping or changing are the five offered choices")
	check(not game.ui.viewer.visible, "the viewer waits for the prediction")
	game.ui._choose(0)
	check(game.ui.viewer.visible, "choosing not to change opens the viewer")
	check(story.bet.get("pick", -1) == 2 and story.bet.get("year", 0) == 1917,
		"the 1917 entry is kept as written")
	check(game.sim.bet_pick == 2, "the kept pick is recorded on the run")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _test_1919_change(story: Node) -> void:
	var game = await _new_game(story, true, {"pick": 2, "sure": 1, "ashby": 1, "year": 1917})
	story.plan = ["comparison"]
	game._interact("measure")
	game.ui._choose(0)
	game.ui._advance()  # the recall line precedes the keep/change choice
	game.ui._choose(2)  # 改：0.87
	check(story.bet.get("pick", -1) == 1 and story.bet.get("year", 0) == 1919,
		"changing the entry writes a 1919 pick")
	check(story.bet.get("ashby", 0) == 1 and story.bet.get("sure", -1) == 1,
		"the change keeps Ashby's entry and the 1917 confidence")
	check(story.bet_1917.get("pick", -1) == 2, "the change leaves the 1917 page untouched")
	check(game.sim.bet_pick == 1, "the changed pick is recorded on the run")
	check(game.ui.viewer.visible, "the viewer opens after the changed entry")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _test_1919_fresh(story: Node) -> Node:
	var game = await _new_game(story, false, {})
	game._interact("measure")
	game.ui._choose(0)
	check(game._pending == "bet", "without a prologue the rule still leads to a fresh prediction")
	check(_text(game).contains("先在記錄本上寫下"), "the fresh prompt asks for a guess before measuring")
	check(not game.ui.viewer.visible, "the viewer stays closed until the guess is made")
	game.ui._choose(2)  # 1.75
	game.ui._choose(1)  # 有點把握
	check(story.bet.get("pick", -1) == 2 and story.bet.get("sure", -1) == 1, "the fresh 1919 guess is stored")
	check(story.bet.get("year", 0) == 1919 and story.bet.get("ashby", 0) == 0,
		"a fresh 1919 guess has no 1917 entry")
	check(game.sim.bet_pick == 2 and game.ui.viewer.visible,
		"the fresh guess opens the viewer with the pick on the run")
	return game


func _test_measure_reentry(game: Node) -> void:
	game._interact("measure")
	check(game._pending == "" and not game.ui.dialog_active() and game.ui.viewer.visible,
		"re-entering Measure reopens the viewer without asking again")


## A replay keeps the 1917 page: the previous run's 1919 revision must not be
## presented as the original entry.
func _test_replay_page(story: Node) -> void:
	story.reset()
	story.prologue_done = true
	story.bet_1917 = {"pick": 2, "sure": 1, "ashby": 1, "year": 1917}
	story.bet = {"pick": 1, "sure": 1, "ashby": 1, "year": 1919}  # last run changed it
	story.plan = ["comparison"]
	story.from_prologue = true
	var game = load(MAIN_PATH).new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.ui.hide_title()
	check(story.bet.get("pick", -1) == 2 and story.bet.get("year", 0) == 1917,
		"a replay starts from the 1917 page, not the last run's revision")
	game.phase = game.Phase.NIGHT
	game._interact("measure")
	game.ui._choose(0)
	check(_text(game).contains("你寫的是 1.75"), "the replay recall names the original 1917 pick")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


## The interval answer is followed by the bet against the player's own plates.
func _test_confrontation_flow(story: Node) -> void:
	var game = await _new_game(story, false, {"pick": 1, "sure": 0, "ashby": 0, "year": 1919})
	game.sim.plates = [{"number": 1, "usable": true, "quality": "good", "included": true,
		"trail": 0.1, "value": 1.75, "sigma": 0.1,
		"read": true, "reading": game.sim.reading_for_value(1.75)}]
	game.sim.rule_id = "strict"
	game.sim.measured = true
	game.sim.bet_pick = 1
	game._start_judgment()
	game.ui._choose(Judgment.interval_truth(game.sim))
	var text := _text(game)
	check(text.contains("你押的是 0.87") and text.contains("容不下它"),
		"the interval answer confronts the bet before the telegram choices")
	check(text.contains("容得下 1.75"), "the confrontation names the prediction the range does hold")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _test_confrontation() -> void:
	var sim := Sim.new(1919)
	sim.plates = [{"number": 1, "usable": true, "quality": "good", "included": true,
		"trail": 0.1, "value": 1.75, "sigma": 0.1,
		"read": true, "reading": sim.reading_for_value(1.75)}]
	var bounds := Judgment.interval_bounds(sim)
	check(Judgment.interval_truth(sim) == 1, "the fixture interval holds 1.75 only")
	var half := Content.bet_vs_plates(1, bounds)
	check(half.contains("容不下") and half.contains("0.87"), "a 0.87 bet is confronted as not contained")
	var whole := Content.bet_vs_plates(2, bounds)
	check(whole.contains("容得下它"), "a 1.75 bet hears that the range holds it")
	var unsure := Content.bet_vs_plates(3, bounds)
	check(unsure.contains("說不準") and unsure.contains("容得下 1.75"),
		"an unsure bet still gets the containment clause")
	check(not half.contains("你對了") and not half.contains("你錯了") and not half.contains("證明"),
		"the confrontation avoids winner language")
	var neither := Sim.new(1919)
	neither.plates = [{"number": 1, "usable": true, "quality": "good", "included": true,
		"trail": 0.1, "value": 2.30, "sigma": 0.17,
		"read": true, "reading": neither.reading_for_value(2.30)}]
	check(Content.bet_vs_plates(0, Judgment.interval_bounds(neither)).contains("三個都容不下——先懷疑儀器"),
		"a neither-contained range says to doubt the instrument first")


func _test_ending_and_coda(story: Node) -> void:
	# Ending: the ledger returns beside the evidence.
	var game = await _new_game(story, false, {"pick": 2, "sure": 1, "ashby": 0, "year": 1919})
	game.sim.bet_pick = 2
	game._grade = {"title": "測試", "fit": 1, "clean": true, "lines": [], "score": 1}
	game._show_ending()
	var review: String = game.ui.ending_review.text
	check(review.contains("量之前你寫的：1.75（有點把握）"), "the ending recalls the player's own entry")
	check(not review.contains("Ashby 先生寫的"), "the ending names Ashby's entry only when it exists")
	check(story.runs.back().get("bet", {}).get("pick", -1) == 2 and story.runs.back().get("bet_pick", -1) == 2,
		"the run snapshot keeps the prediction for replays")
	story.bet["ashby"] = 1
	game._show_ending()
	check(game.ui.ending_review.text.contains("Ashby 先生寫的：0.87"), "the ending recalls Ashby's 0.87 once the 1917 entry exists")
	game.stop_all_audio()
	game.queue_free()
	await process_frame

	# Coda: one inner line before the loupe, only with Ashby's 1917 entry.
	story.reset()
	story.departure_done = true
	story.report = {"cause": "mirror"}
	var coda = await _new_game(story, true, {"pick": 2, "sure": 1, "ashby": 1, "year": 1917}, true)
	coda._grade = {"title": "序章", "fit": 2, "clean": true, "lines": []}
	coda._pending = "reaction"
	coda._on_dialogue_done({})
	check(coda.phase == coda.Phase.CODA, "the prologue reaction enters the coda")
	coda._on_dialogue_done({})
	coda._interact("departure_workbook")
	check(coda._pending == "coda_workbook", "the workbook beat plays before the loupe")
	coda._on_dialogue_done({})
	coda._interact("mentor_loupe")
	check(_text(coda).contains("他在 1917 年那頁寫的是 0.87"), "the coda recalls Ashby's own entry before the loupe")
	story.bet["ashby"] = 0
	coda.coda_step = coda.CodaStep.LOUPE
	coda._interact("mentor_loupe")
	check(not _text(coda).contains("他在 1917 年那頁寫的是 0.87"),
		"the coda line needs Ashby's 1917 entry")
	check(Coda.ashby_answer(2, true, true, true, false).size() == Coda.ashby_answer(2, true, true, true, true).size() - 1,
		"the coda line is one extra entry, nothing else changes")
	coda.stop_all_audio()
	coda.queue_free()
	await process_frame
