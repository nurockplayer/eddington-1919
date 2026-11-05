extends SceneTree
## Conversion arc move B: the orrery check sits on the main path between the report
## review and Ashby's Dyson scene. Marks and the suspect are kept in Story; every
## suspect gets Ashby's answer; a pre-checked player skips the errand.
## Run: godot --headless --path . --script res://tests/test_orrery_check.gd
const DIRECTOR := "res://scripts/cambridge/director.gd"
const C17 := preload("res://scripts/cambridge/content_1917.gd")
const PICKS := {"orrery_neptune": 0, "orrery_halley": 0, "orrery_mercury": 1, "mercury_suspect": 3}
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
	await _test_review_gate_and_check(story)
	await _test_prechecked_goes_to_dyson(story)
	_test_suspect_lines()
	story.reset()
	check(story.orrery.is_empty() and story.mercury_suspect == -1, "Story.reset clears the orrery check")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _new_chapter() -> Node:
	var chapter = load(DIRECTOR).new()
	root.add_child(chapter)
	var deadline := Time.get_ticks_msec() + 12000
	while chapter._pending != "opening" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter._pending == "opening", "Cambridge reaches the opening dialogue within 12 s")
	_finish(chapter)
	check(chapter.beat == chapter.Beat.INVESTIGATE, "the opening hands the room to the player")
	return chapter


## Finishes whatever dialogue is open, taking the first option everywhere.
func _finish(chapter) -> void:
	var guard := 100
	while chapter.ui.dialog_active() and guard > 0:
		guard -= 1
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("choices"):
			chapter.ui._choose(0)
		else:
			chapter.ui._advance()
	check(guard > 0, "test dialogue terminates")


func _drive_check(chapter, picks: Dictionary) -> Array[String]:
	var keys: Array[String] = []
	var guard := 100
	# Stop when the check ends: on the main path it hands straight to Dyson.
	while chapter.ui.dialog_active() and chapter._pending == "orrery_check" and guard > 0:
		guard -= 1
		var entry: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		if entry.has("choices"):
			var key := str(entry.get("key", ""))
			keys.append(key)
			chapter.ui._choose(int(picks.get(key, 0)))
		else:
			chapter.ui._advance()
	check(guard > 0, "the orrery check finishes")
	return keys


func _text(chapter) -> String:
	var out := ""
	for line in chapter.ui._seq:
		out += str(line.get("t", "")) + "\n"
	return out


func _seq_text(seq: Array) -> String:
	var out := ""
	for line in seq:
		out += str(line.get("t", "")) + "\n"
	return out


## After the report review: the objective names the orrery, Dyson waits, and the
## real check stores the three marks and the suspect before Dyson plays.
func _test_review_gate_and_check(story: Node) -> void:
	story.reset()
	var chapter = await _new_chapter()
	chapter._pending = "mentor_review"
	chapter._dialogue_done({"revise_report": 1})
	check(chapter._pending == "orrery_errand", "the report review sends the player to the orrery first")
	check(not chapter.ui._seq.any(func(line): return line.get("key", "") in ["bet", "bet_sure"]),
		"Dyson's ledger does not start before the orrery check")
	_finish(chapter)
	check(chapter.beat == chapter.Beat.ORRERY, "finishing the errand opens the orrery beat")
	check(chapter.ui.objectives.text.contains("太陽系儀"), "the objective names 太陽系儀")
	check(chapter._free() and chapter.player.can_move, "the orrery beat releases movement")
	check(story.orrery.is_empty() and chapter._pending != "dyson", "the check is still owed")
	chapter._interact("orrery")
	check(chapter._pending == "orrery_check" and chapter.ui.dialog_active(), "the orrery opens the check")
	var keys := _drive_check(chapter, PICKS)
	check(keys == ["orrery_neptune", "orrery_halley", "orrery_mercury", "mercury_suspect"],
		"the check asks three marks and the suspect in order")
	check(story.orrery == {"neptune": 0, "halley": 0, "mercury": 1}, "the three marks are stored in Story.orrery")
	check(story.mercury_suspect == 3, "the suspect (Hall) is stored in Story.mercury_suspect")
	check(chapter._pending == "dyson", "the check hands straight to Dyson")
	var dyson := _text(chapter)
	check(dyson.contains("水星例外"), "Ashby opens on Mercury's exception")
	check(dyson.contains("2.00000016"), "Ashby answers the Hall suspect")
	check(dyson.contains("1911") and dyson.contains("只有一半"), "the 1911 humility line follows the half value")
	chapter.free()
	await process_frame


## A player who checked during the investigation goes straight to Dyson; a second
## visit shows the summary, not the check again.
func _test_prechecked_goes_to_dyson(story: Node) -> void:
	story.reset()
	var chapter = await _new_chapter()
	chapter._interact("orrery")
	check(chapter._pending == "orrery_check", "the first visit is the check")
	var picks := {"orrery_neptune": 0, "orrery_halley": 0, "orrery_mercury": 1, "mercury_suspect": 1}
	_drive_check(chapter, picks)
	check(chapter._pending == "" and chapter.beat == chapter.Beat.INVESTIGATE, "an early check returns to the room")
	check(story.orrery.size() == 3 and story.mercury_suspect == 1, "the early check is kept")
	chapter._interact("orrery")
	check(chapter._pending == "" and chapter.ui.dialog_active(), "a second visit shows the summary")
	var summary := _text(chapter)
	check(summary.contains("你留在年鑑上的記號"), "the summary says what the player marked")
	check(summary.contains("海王星：對得上") and summary.contains("水星的 43 角秒：對不上"),
		"the summary repeats the marks")
	check(summary.contains("Vulcan"), "the summary repeats the suspect")
	check(not chapter.ui._seq.any(func(line): return str(line.get("key", "")).begins_with("orrery_") or line.get("key", "") == "mercury_suspect"),
		"the summary asks nothing")
	_finish(chapter)
	chapter._pending = "mentor_review"
	chapter._dialogue_done({"revise_report": 1})
	check(chapter._pending == "dyson", "a player who checked earlier goes straight to Dyson")
	check(chapter.beat != chapter.Beat.ORRERY, "the orrery beat is skipped")
	check(not _text(chapter).contains("你先去看看"), "no orrery errand when the check is done")
	chapter.free()
	await process_frame


## Every suspect is treated as reasonable, and the 1911 line is unconditional.
func _test_suspect_lines() -> void:
	var markers := ["那個數字還在", "Le Verrier 也這麼想", "Seeliger", "2.00000016", "拆掉整棟房子"]
	for i in markers.size():
		var text := _seq_text(C17.mentor_dyson({}, {"mercury_suspect": i}))
		check(text.contains(markers[i]), "suspect %d gets Ashby's answer" % i)
		check(text.contains("水星例外") and text.contains("海王星、哈雷"), "suspect %d keeps the shared Mercury lines" % i)
		check(text.contains("1911") and text.contains("只有一半"), "suspect %d hears the 1911 humility line" % i)
