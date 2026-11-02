extends SceneTree
## The 1919 darkroom remembers the 1917 plan board: the comparison plate and
## the far-star calibration say whether the player planned them or Eddington
## added them; without the prologue they say nothing.
const Content := preload("res://scripts/content.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
const MINE := "是你放上去的"
const ADDED := "是 Eddington 補在最下面的"
const CAL_MINE := "1917 年你寫進了計畫"
const CAL_ADDED := "那一條是 Eddington 補上的"
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
	check(Content.comparison_recall(["comparison"], true).contains(MINE), "a planned comparison plate is the player's")
	check(Content.comparison_recall(["far_stars"], true).contains(ADDED), "a missing comparison plate was added by Eddington")
	check(Content.comparison_recall(["comparison"], false) == "", "no recall without the prologue")
	check(Content.calibration_recall(["far_stars"], true).contains(CAL_MINE), "planned far stars are the player's")
	check(Content.calibration_recall([], true).contains(CAL_ADDED), "missing far stars were added by Eddington")
	check(Content.calibration_recall(["far_stars"], false) == "", "no calibration recall without the prologue")

	for case in [[["comparison", "far_stars"], true, MINE, CAL_MINE], [["rules_first"], true, ADDED, CAL_ADDED], [[], false, "", ""]]:
		await _check_viewer(story, case[0], case[1], case[2], case[3])
	for case in [[["conditions"], true, false, "沒有校過"], [["conditions"], true, true, "已對著天文鐘校過"],
			[["comparison"], true, false, ""], [[], false, false, "沒有校過"], [[], false, true, "已對著天文鐘校過"]]:
		await _check_drive(story, case[0], case[1], case[2], case[3])
	story.reset()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check_viewer(story: Node, plan: Array, played: bool, comparison: String, calibration: String) -> void:
	var label := "plan %s played=%s" % [plan, played]
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	# main._ready resets Story outside a prologue run, so set it afterwards.
	story.plan = plan.duplicate()
	story.prologue_done = played
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.sim.plates = []
	game._open_viewer()
	game.ui._select_plate(-2, null, false)
	var text: String = game.ui.plate_info.text
	if comparison == "":
		check(not text.contains("1917"), "%s: the comparison plate has no recall" % label)
	else:
		check(text.contains(comparison), "%s: the comparison plate recalls the plan" % label)
	game.sim.plates = [
		{"number": 1, "usable": true, "quality": "good", "included": true, "value": 1.8, "sigma": 0.2, "stars": 7},
	]
	game.sim.measured = true
	game._refresh_viewer()
	var note: String = game.ui.viewer_note.text
	if calibration == "":
		check(not note.contains("遠處的星"), "%s: the measured note has no calibration recall" % label)
	else:
		check(note.contains(calibration), "%s: the measured note recalls the calibration" % label)
	game.stop_all_audio()
	game.queue_free()
	await process_frame


## The "conditions" card: each eclipse plate's info also records the drive.
func _check_drive(story: Node, plan: Array, played: bool, rate_checked: bool, expect: String) -> void:
	var label := "plan %s played=%s drive_checked=%s" % [plan, played, rate_checked]
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	story.plan = plan.duplicate()
	story.prologue_done = played
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.sim.drive_rate_checked = rate_checked
	game.sim.plates = [
		{"number": 1, "start": 30.0, "duration": 4.0, "sunlit": false, "included": false, "usable": true, "stars": 7, "quality": "good", "sky_read": "clear"},
	]
	game.plate_textures = [null]
	game._open_viewer()
	var text: String = game.ui.plate_info.text
	if expect == "":
		check(not text.contains("走速"), "%s: the plate note has no drive line" % label)
	else:
		check(text.contains("走速") and text.contains(expect), "%s: the plate note records the drive" % label)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
