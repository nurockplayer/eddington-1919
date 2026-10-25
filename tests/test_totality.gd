extends SceneTree
## Headless checks for the M5 totality legibility layer.
## Run: godot --headless --path . --script res://tests/test_totality.gd

const Sim := preload("res://scripts/eclipse_sim.gd")
const Cues := preload("res://scripts/totality_cues.gd")
const Content := preload("res://scripts/content.gd")
const UI := preload("res://scripts/ui.gd")

const STEP := 0.1                      # real seconds per scripted frame
const GAME_STEP := STEP * Sim.TIME_SCALE   # 0.25 game-seconds per frame

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
	_test_bands()
	_test_strip_model()
	await _test_sim_invariance()
	_test_shutter_read()
	await _test_callouts()
	await _test_night_viewer()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


# ---------------------------------------------------------------- 1. sky_band

func _test_bands() -> void:
	check(Cues.sky_band(6.5, 10.0) == "clear", "f = 0.65 is clear")
	check(Cues.sky_band(6.49, 10.0) == "mixed", "f just under 0.65 is mixed")
	check(Cues.sky_band(3.0, 10.0) == "mixed", "f = 0.30 is mixed")
	check(Cues.sky_band(2.99, 10.0) == "cloud", "f just under 0.30 is cloud")
	check(Cues.sky_band(0.0, 10.0) == "cloud", "fully clouded exposure is cloud")
	check(Cues.sky_band(0.99, 0.5) == "brief", "brief overrides a clear fraction")
	check(Cues.sky_band(0.0, 0.0) == "brief", "zero-length exposure is brief, no division")
	check(Cues.sky_band(1.0, 1.0) == "clear", "1.0 s at full clarity is clear")


# ------------------------------------------------------------ 2. strip_model

func _test_strip_model() -> void:
	var m: Dictionary = Cues.strip_model(20.0, 302.0, [{"start": 10.0, "duration": 5.0}], 18.0, 4)
	check(m.segments.size() == 1 and m.segments[0] == [10.0, 15.0], "closed exposure becomes a segment")
	check(m.open_segment == [18.0, 20.0], "open exposure grows to the playhead")
	check(m.open_start == 18.0, "open start kept for the amber segment")
	check(m.plates_total == 4, "plate pips follow available plates")
	check(m.plates_used == 2, "closed plate plus the open one are pips filled")
	check(m.t == 20.0 and m.total == 302.0, "playhead and span pass through")

	var clamped: Dictionary = Cues.strip_model(400.0, 302.0, [{"start": 300.0, "duration": 10.0}], 320.0, 4)
	check(clamped.t == 302.0, "playhead clamps at 302")
	check(clamped.segments[0] == [300.0, 302.0], "segment clamps at 302")
	check(clamped.open_start == 302.0 and clamped.open_segment.is_empty(), "empty open segment clamps to 302")

	var idle: Dictionary = Cues.strip_model(-5.0, 302.0, [], -1.0, 4)
	check(idle.t == 0.0, "playhead clamps at 0")
	check(idle.segments.is_empty() and idle.open_segment.is_empty(), "no exposures, no segments")
	check(idle.plates_used == 0 and idle.open_start == -1.0, "not exposing leaves pips empty")


# --------------------------------------------------------- 3. sim invariance

func _events() -> Dictionary:
	return {40: "open", 120: "close", 140: "open", 152: "close", 200: "open", 280: "close", 400: "open", 440: "close"}


func _frames() -> int:
	return int(ceil(300.0 / GAME_STEP))   # stay short of third contact


func _run_main(game: Node, events: Dictionary) -> Array:
	var log: Array = []
	for i in _frames():
		var act: String = events.get(i, "")
		if act == "open" or act == "close":
			game._toggle_shutter()
		var before_t: float = game.ui._callout_t
		var before_text: String = game.ui.callout.text
		game._process_totality(STEP)
		if game.ui._callout_t > 0.0 and (game.ui._callout_t > before_t + 0.0001 or game.ui.callout.text != before_text):
			log.append({"text": game.ui.callout.text, "t": game.t_game})
		game.ui._process(STEP)
	return [game.sim.plates, log]


func _run_direct(ref, events: Dictionary) -> Array:
	var t := 0.0
	for i in _frames():
		var act: String = events.get(i, "")
		if act == "open":
			ref.open_shutter(t)
		elif act == "close":
			ref.close_shutter(false)
		t += GAME_STEP
		var dens: float = ref.cloud_over_sun(t)
		if ref.is_exposing():
			ref.accumulate(GAME_STEP, dens)
	return ref.plates


func _test_sim_invariance() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	for seed_ in [1919, 515]:
		var game: Node = scene.instantiate()
		root.add_child(game)
		game.set_process(false)
		game.sim = Sim.new(seed_)
		game.phase = game.Phase.TOTALITY
		game.t_game = 0.0
		game.plates_left = game.sim.plates_available()
		game.change_left = 0.0
		game._busy = false
		game.tot_done = false
		game._score_exposing = false
		var main_plates: Array = _run_main(game, _events())[0]
		var ref = Sim.new(seed_)
		var direct_plates: Array = _run_direct(ref, _events())
		check(main_plates.size() == 4, "seed %d: four exposures ran through _process_totality (%d)" % [seed_, main_plates.size()])
		check(direct_plates.size() == main_plates.size(), "seed %d: same plate count both paths" % seed_)
		for i in mini(main_plates.size(), direct_plates.size()):
			var a: Dictionary = main_plates[i]
			var b: Dictionary = direct_plates[i]
			var mismatch := ""
			for key in b.keys():
				if key == "sky_read":
					continue
				if a.get(key) != b.get(key):
					mismatch = "%s %s=%s vs %s" % [mismatch, key, str(a.get(key)), str(b.get(key))]
			check(mismatch == "", "seed %d plate %d matches on every sim key%s" % [seed_, i + 1, mismatch])
			check(a.get("sky_read", "") in ["clear", "mixed", "cloud", "brief"], "seed %d plate %d carries a hindsight band" % [seed_, i + 1])
		game.audio_amb.stop()
		game.audio_click.stop()
		game.audio_tick.stop()
		game.queue_free()
		await process_frame


# ------------------------------------------- A integration: read on the toast

func _test_shutter_read() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.phase = game.Phase.TOTALITY
	game.t_game = 0.0
	game.plates_left = game.sim.plates_available()
	game.change_left = 0.0
	game._busy = false
	game.tot_done = false
	game._score_exposing = false
	game._toggle_shutter()
	for i in 12:
		game._process_totality(STEP)
	game._toggle_shutter()
	var p: Dictionary = game.sim.plates[0]
	check(p.has("sky_read"), "closed plate stores p.sky_read")
	check(p.sky_read == Cues.sky_band(p.clear, p.duration), "sky_read comes from the clear fraction")
	var want := Content.totality_read(p.sky_read)
	check(want != "" and game.ui.toast.text.contains(want), "shutter toast appends Cottingham's read")
	game.audio_amb.stop()
	game.audio_click.stop()
	game.audio_tick.stop()
	game.queue_free()
	await process_frame


# ------------------------------------------------------- 4. callout triggers

func _make_game() -> Node:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	_reset_game(game, 1919, 0.0)
	return game


func _reset_game(game: Node, seed_: int, t: float) -> void:
	game.sim = Sim.new(seed_)
	game.phase = game.Phase.TOTALITY
	game.t_game = t
	game.plates_left = game.sim.plates_available()
	game.change_left = 0.0
	game._busy = false
	game.tot_done = false
	game._score_exposing = false
	game._ever_exposed = false
	game._long_called = false
	game._callout_last_plate = false
	game._callout_plates_left = false
	game._callout_nudged = false
	game._was_changing = false
	game._glanced = false
	game._warned_end = false
	game.ui.callout.text = ""
	game.ui.callout.modulate.a = 0.0
	game.ui._callout_t = 0.0
	game.ui.toast.text = ""


func _step(game: Node, log: Array) -> void:
	var before_t: float = game.ui._callout_t
	var before_text: String = game.ui.callout.text
	game._process_totality(STEP)
	if game.ui._callout_t > 0.0 and (game.ui._callout_t > before_t + 0.0001 or game.ui.callout.text != before_text):
		log.append({"text": game.ui.callout.text, "t": game.t_game})
	game.ui._process(STEP)


func _count(log: Array, text: String) -> int:
	return log.filter(func(e): return e.text == text).size()


func _first(log: Array, text: String) -> Dictionary:
	for e in log:
		if e.text == text:
			return e
	return {}


func _test_callouts() -> void:
	var game := _make_game()

	# First nudge: fires once after 45 s with no exposure.
	var log: Array = []
	for i in int(60.0 / GAME_STEP):
		_step(game, log)
	var nudge := Content.totality_first_nudge()
	check(game.ui.tot_label.text.contains("\n"), "header puts the status on a second line")
	check(_count(log, nudge) == 1, "first nudge fires exactly once by 60 s")
	check(_first(log, nudge).get("t", 0.0) >= 45.0 and _first(log, nudge).get("t", 999.0) < 46.0, "first nudge fires at the 45 s mark")

	# Nudge suppressed when the player exposed in the first 45 s.
	_reset_game(game, 1919, 0.0)
	log = []
	game._toggle_shutter()
	for i in 20:
		_step(game, log)
	game._toggle_shutter()
	for i in int(46.0 / GAME_STEP):
		_step(game, log)
	check(_count(log, nudge) == 0, "first nudge silent after an early exposure")

	# Long exposure: once per plate, same line again on the next plate.
	_reset_game(game, 1919, 0.0)
	log = []
	game._toggle_shutter()
	for i in int(22.0 / GAME_STEP):
		_step(game, log)
	game._toggle_shutter()
	for i in int(5.0 / GAME_STEP):
		_step(game, log)
	game._toggle_shutter()   # second plate, after the 4 s change
	for i in int(22.0 / GAME_STEP):
		_step(game, log)
	game._toggle_shutter()
	var long_line := Content.totality_long(false)
	check(_count(log, long_line) == 2, "long-exposure callout fires once for each 20 s plate")
	check(_first(log, long_line).get("t", 0.0) >= 20.0, "long-exposure callout waits for 20 s")

	# Long exposure names the unchecked drive.
	_reset_game(game, 1919, 0.0)
	game.sim.drive_rate_checked = true
	log = []
	game._toggle_shutter()
	for i in int(22.0 / GAME_STEP):
		_step(game, log)
	check(_count(log, Content.totality_long(true)) == 1, "checked drive gets its own long-exposure line")
	check(_count(log, Content.totality_long(false)) == 0, "unchecked line does not fire on a checked drive")
	game._toggle_shutter()

	# Last plate: after the plate change finishes with exactly one left.
	_reset_game(game, 1919, 0.0)
	game.plates_left = 2
	log = []
	game._toggle_shutter()
	for i in 16:
		_step(game, log)
	game._toggle_shutter()   # plates_left -> 1, change starts
	for i in int(8.0 / GAME_STEP):
		_step(game, log)
	check(game.plates_left == 1, "test setup leaves exactly one plate")
	check(_count(log, Content.totality_last_plate()) == 1, "last-plate callout fires once")
	check(_first(log, Content.totality_last_plate()).get("t", 0.0) >= 6.0, "last-plate callout waits for the change to finish")

	# Not when two plates remain after the change.
	_reset_game(game, 1919, 0.0)
	game.plates_left = 3
	log = []
	game._toggle_shutter()
	for i in 16:
		_step(game, log)
	game._toggle_shutter()
	for i in int(8.0 / GAME_STEP):
		_step(game, log)
	check(_count(log, Content.totality_last_plate()) == 0, "last-plate callout silent with two plates left")

	# Plates-left: late, idle, two or more plates unused.
	_reset_game(game, 1919, 0.0)
	game.t_game = 199.0
	game.plates_left = 3
	game._callout_nudged = true   # isolate this trigger
	log = []
	for i in 4:
		_step(game, log)
	var left_line := Content.totality_plates_left(3)
	check(_count(log, left_line) == 1, "plates-left callout fires once after 200 s idle")
	check(_first(log, left_line).get("t", 0.0) >= 200.0, "plates-left callout waits for 200 s")

	# No plates-left callout while exposing.
	_reset_game(game, 1919, 0.0)
	game.t_game = 199.0
	game.plates_left = 3
	game._callout_nudged = true
	game.sim.open_shutter(199.0)
	log = []
	for i in 4:
		_step(game, log)
	check(_count(log, Content.totality_plates_left(3)) == 0, "plates-left callout silent while the shutter is open")
	game.sim.close_shutter(false)

	# No plates-left callout when a plate was taken in the last 60 s.
	_reset_game(game, 1919, 0.0)
	game.t_game = 199.0
	game.plates_left = 3
	game._callout_nudged = true
	game.sim.plates = [{"number": 1, "start": 165.0, "duration": 5.0}]
	log = []
	for i in 4:
		_step(game, log)
	check(_count(log, Content.totality_plates_left(3)) == 0, "plates-left callout silent after a recent plate")

	# No plates-left callout with fewer than two plates.
	_reset_game(game, 1919, 0.0)
	game.t_game = 199.0
	game.plates_left = 1
	game._callout_nudged = true
	log = []
	for i in 4:
		_step(game, log)
	check(_count(log, Content.totality_plates_left(1)) == 0, "plates-left callout needs two or more plates")

	# The half-way glance and the third-contact warning moved to the callout line.
	_reset_game(game, 1919, 0.0)
	log = []
	for i in int(151.0 / GAME_STEP):
		_step(game, log)
	check(_count(log, "Eddington 抬頭看了一眼：「雲還是很厚……繼續。」") == 1, "half-way glance uses the callout line")
	check(not game.ui.toast.text.contains("抬頭看了一眼"), "glance no longer overwrites the shutter toast")
	_reset_game(game, 1919, 0.0)
	log = []
	for i in int(285.0 / GAME_STEP):
		_step(game, log)
	check(_count(log, "太陽西緣開始發亮——第三接觸快到了！") == 1, "third-contact warning uses the callout line")

	game.audio_amb.stop()
	game.audio_click.stop()
	game.audio_tick.stop()
	game.queue_free()
	await process_frame


# --------------------------------------------------------- 5. night viewer line

func _test_night_viewer() -> void:
	var ui = UI.new()
	root.add_child(ui)
	await process_frame
	var plates := [
		{"number": 1, "start": 10.0, "duration": 8.0, "sunlit": false, "included": false, "usable": true, "sky_read": "clear"},
		{"number": 2, "start": 20.0, "duration": 0.4, "sunlit": false, "included": false, "usable": false, "sky_read": "brief"},
		{"number": 3, "start": 24.0, "duration": 2.0, "sunlit": true, "included": false, "usable": false},
		{"number": 4, "start": 30.0, "duration": 3.0, "sunlit": false, "included": false, "usable": true},
	]
	ui.open_viewer(plates, null, [null, null, null, null], false)
	ui._select_plate(0, null)
	check(ui.plate_info.text.contains(Content.totality_read_night("clear")), "night viewer shows the clear read")
	ui._select_plate(1, null)
	check(ui.plate_info.text.contains(Content.totality_read_night("brief")), "night viewer shows the brief read")
	ui._select_plate(2, null)
	check(not ui.plate_info.text.contains("拍攝時："), "sunlit plate has no read")
	ui._select_plate(3, null)
	check(not ui.plate_info.text.contains("拍攝時："), "plate without a band has no read")
	# A callout that has faded out releases its space in the panel.
	ui.set_callout("測試提示", 0.5)
	check(ui.callout.visible and ui.callout.text == "測試提示", "callout shows while active")
	ui._process(0.6)
	check(not ui.callout.visible and ui.callout.text == "", "expired callout hides and clears its text")
	ui._process(0.1)
	check(not ui.callout.visible, "expired callout stays hidden")

	ui.queue_free()
	await process_frame
