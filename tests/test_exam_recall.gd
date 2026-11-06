extends SceneTree
## Eddington's 1917 exam question — "without the reversed 14, what would you
## have handed in?" — is kept in Story and recalled when the 1919 rule is
## written. No prologue, no recall.
const DIRECTOR := "res://scripts/cambridge/director.gd"
const MAIN_PATH := "res://scripts/main.gd"
const UNKNOWN := "寫「原因未明」"
const GUESS := "照最像的那樣對齊，交上去"
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
	await _test_director_keeps_exam(story)
	await _test_rule_recall(story, true, 0, [UNKNOWN], [GUESS])
	await _test_rule_recall(story, true, 1, [GUESS, "寫明是猜"], [UNKNOWN])
	await _test_rule_recall(story, true, 2, [], [UNKNOWN, GUESS])
	await _test_rule_recall(story, false, 1, [], [UNKNOWN, GUESS])
	story.reset()
	check(story.exam.is_empty(), "Story.reset clears the exam answers")
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_director_keeps_exam(story: Node) -> void:
	var chapter = load(DIRECTOR).new()
	root.add_child(chapter)
	var deadline := Time.get_ticks_msec() + 12000
	while chapter._pending != "opening" and Time.get_ticks_msec() < deadline:
		await process_frame
	check(chapter._pending == "opening", "Cambridge reaches the opening dialogue within 12 s")
	chapter._pending = "exam"
	chapter._dialogue_done({"q1": 1, "q2": 0, "box": 2})
	check(story.exam.get("q1", -1) == 1 and story.exam.get("box", -1) == 2, "the exam answers are kept in Story")
	# Conversion arc move E: the box is played before the exam's second half.
	check(chapter.box_sketch.visible and not chapter.ui.dialog_active(), "the exam opens the box sketch instead of speaking straight on")
	await _play_box(chapter)
	check(chapter._pending == "exam_box" and chapter.ui.dialog_active(), "the played box brings Eddington back")
	var guard := 40
	while chapter.ui.dialog_active() and guard > 0:
		guard -= 1
		if not chapter.ui._choice_buttons.is_empty():
			chapter.ui._choose(1)
		else:
			chapter.ui._advance()
		await process_frame
	check(story.exam.get("box_light", -1) == 1, "the box's light answer joins the exam in Story")
	check(chapter._pending == "plan_intro", "the exam still leads to the plan board")
	chapter.free()
	await process_frame


## Three real 鬆手 presses with a 換一格 after each, waiting for each fall's own end.
func _play_box(chapter) -> void:
	var sketch = chapter.box_sketch
	for stage in 3:
		sketch.release_btn.pressed.emit()
		var deadline := Time.get_ticks_msec() + 5000
		while sketch.next_btn.disabled and Time.get_ticks_msec() < deadline:
			await process_frame
		check(not sketch.next_btn.disabled, "box stage %d fall finishes" % stage)
		sketch.next_btn.pressed.emit()
		await process_frame
	check(not sketch.visible, "the box sketch closes after its third cell")


func _test_rule_recall(story: Node, played: bool, q1: int, has: Array, lacks: Array) -> void:
	var game = load(MAIN_PATH).new()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.ui.hide_title()
	# main._ready resets Story outside a prologue run, so set it afterwards.
	story.prologue_done = played
	story.exam = {"q1": q1}
	# A prologue run that planned the comparison plates reaches the rule directly;
	# without the card the Oxford errand comes first (test_plan_recall covers it).
	story.plan = ["comparison"] if played else []
	game.phase = game.Phase.NIGHT
	game._interact("measure")
	var text := ""
	for entry in game.ui._seq:
		text += str(entry.get("t", "")) + "\n"
	var label := "played=%s q1=%d" % [played, q1]
	check(game._pending == "rules" and text.contains("哪些底片不納入"), "%s: measuring asks for the rule" % label)
	for s in has:
		check(text.contains(s), "%s: the rule prompt recalls 「%s」" % [label, s])
	for s in lacks:
		check(not text.contains(s), "%s: the rule prompt does not say 「%s」" % [label, s])
	game.stop_all_audio()
	game.queue_free()
	await process_frame
