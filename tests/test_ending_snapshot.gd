extends SceneTree
## The ending screen is a pure function of the stored run snapshot (conversion arc D1).
## Capture the real _show_ending() texts, free the scene, then rebuild them from the
## recorded snapshot and Story view alone.
## Run: godot --headless --path . --script res://tests/test_ending_snapshot.gd

const Sim := preload("res://scripts/eclipse_sim.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Ending := preload("res://scripts/ending.gd")

const TEXTS := ["title", "body", "history", "review", "telegram"]
# Every field the ending reads from the stored run. build() must not need the live sim.
const FIELDS := ["combined", "grade", "first_result", "reselected_after_seeing",
	"drive_rate_checked", "drive_wound", "plate_total", "plates_available", "plate_counts",
	"bounds", "telegram_id", "reason_id", "reason_text", "bet", "bet_pick", "rule_id",
	"kit_line", "departure_kit"]

var failures := 0
var checks := 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL: ", msg)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var story = root.get_node("Story")
	story.reset()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	var runs: Array = []
	runs.append(_record(game, story, _honest()))
	runs.append(_record(game, story, _careful()))
	runs.append(_record(game, story, _rushed()))
	for r in runs:
		check(r.texts.title != "" and r.texts.review.contains("Eddington 的回應"), "%s: real ending labels carry the ending" % r.name)

	# The scene and its simulation are gone; only the snapshot and the Story view remain.
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	for r in runs:
		_check_purity(r, "after the scene is freed")

	# Story.reset() wipes runs, bet and the prologue flags; the stored view still builds.
	story.reset()
	for r in runs:
		_check_purity(r, "after Story.reset()")

	print("ENDING SNAPSHOT: %d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _check_purity(record: Dictionary, context: String) -> void:
	for field in FIELDS:
		check(record.snapshot.has(field), "purity %s: %s snapshot carries %s" % [record.name, context, field])
	var built: Dictionary = Ending.build(record.snapshot.duplicate(true), record.view.duplicate(true))
	for key in TEXTS:
		check(built[key] == record.texts[key], "purity %s: %s text matches %s" % [record.name, context, key])


func _record(game: Node, story: Node, spec: Dictionary) -> Dictionary:
	_setup(game, story, spec)
	game._show_ending()
	var texts := {
		"title": game.ui.ending_title.text,
		"body": game.ui.ending_text.text,
		"history": game.ui.ending_history.text,
		"review": game.ui.ending_review.text,
		"telegram": game.ui.ending_telegram.text,
	}
	return {
		"name": spec.name,
		"texts": texts,
		"snapshot": story.runs.back().duplicate(true),
		"view": Ending.story_view(story).duplicate(true),
	}


func _setup(game: Node, story: Node, spec: Dictionary) -> void:
	var sim := Sim.new(int(spec.seed))
	sim.plates = spec.plates.duplicate(true)
	sim.rule_id = spec.rule
	sim.measured = spec.get("measured", false)
	sim.bet_pick = spec.get("bet_pick", -1)
	sim.first_result = spec.get("first_result", null)
	sim.reselected_after_seeing = spec.get("reselected", false)
	sim.drive_wound = spec.get("drive_wound", false)
	sim.drive_rate_checked = spec.get("drive_rate_checked", false)
	game.sim = sim
	game._run_record_index = -1
	game._telegram = int(spec.telegram)
	game._reason = int(spec.reason)
	game._reasons = []
	game._grade = Judgment.grade(sim, Judgment.TELEGRAMS[int(spec.telegram)].id, Judgment.REASONS[int(spec.reason)].id)
	story.bet = spec.bet.duplicate(true)
	story.kit_first = int(spec.get("kit_first", -1))
	game._came_from_departure = bool(spec.get("departure", false))
	if game._came_from_departure:
		game._night_departure_workbook.write_kit_line("給 Kit：雲在最後才薄下去，我一直看著。")


func _plate(number: int, quality: String, included: bool, stars: int, value: float, sigma: float, duration := 8.0) -> Dictionary:
	return {"index": number - 1, "number": number, "start": 10.0 * number, "duration": duration,
		"sunlit": false, "included": included, "usable": quality != "unusable", "stars": stars,
		"quality": quality, "trail": 0.1, "fog": 0.05, "value": value, "sigma": sigma}


## A measured, clean run: three good plates, all included, drive checked.
func _honest() -> Dictionary:
	return {
		"name": "honest", "seed": 1919, "rule": "strict", "telegram": 1, "reason": 0,
		"plates": [
			_plate(1, "good", true, 7, 1.75, 0.20),
			_plate(2, "good", true, 6, 1.80, 0.24),
			_plate(3, "good", true, 5, 1.70, 0.30),
		],
		"measured": true, "bet_pick": 2, "bet": {"pick": 2, "sure": 1, "ashby": 0, "year": 1919},
		"drive_wound": true, "drive_rate_checked": true,
	}


## A careful reselection: the first measurement was kept, with Ashby's ledger entry.
func _careful() -> Dictionary:
	return {
		"name": "careful", "seed": 515, "rule": "quality", "telegram": 2, "reason": 1,
		"plates": [
			_plate(1, "poor", true, 5, 1.60, 0.45),
			_plate(2, "good", true, 7, 1.78, 0.22),
			_plate(3, "unusable", false, 2, 0.0, 1.0),
		],
		"measured": true, "bet_pick": 1, "bet": {"pick": 1, "sure": 0, "ashby": 1, "year": 1919},
		"drive_wound": true, "drive_rate_checked": false,
		"first_result": {"n": 2, "value": 1.66, "sigma": 0.30},
		"reselected": true, "departure": true, "kit_first": 2,
	}


## A rushed run through cloud: nothing measured, no rate check, Kit's line never written.
func _rushed() -> Dictionary:
	return {
		"name": "rushed", "seed": 7, "rule": "", "telegram": 3, "reason": 3,
		"plates": [
			_plate(1, "unusable", true, 1, 0.0, 1.0),
			_plate(2, "poor", false, 3, 0.80, 0.90),
		],
		"measured": false, "bet_pick": -1, "bet": {},
		"drive_wound": false, "drive_rate_checked": false,
	}
