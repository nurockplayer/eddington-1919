extends SceneTree
## Headless checks for the M5 totality legibility layer.
## Run: godot --headless --path . --script res://tests/test_totality.gd

const Sim := preload("res://scripts/eclipse_sim.gd")
const Cues := preload("res://scripts/totality_cues.gd")
const Content := preload("res://scripts/content.gd")
const UI := preload("res://scripts/ui.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Chart := preload("res://scripts/chart.gd")

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
	await _test_shutter_read()
	await _test_sfx_buffers()
	await _test_viewer_note()
	_test_interval_truth()
	_test_judgment_neither()
	_test_judgment_prompt()
	await _test_judgment_reasons()
	await _test_birds_quiet()
	await _test_callouts()
	await _test_night_viewer()
	# AudioServer releases stopped WAV playbacks asynchronously, after node teardown.
	await create_timer(0.1).timeout
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
		game.stop_all_audio()
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
	check(game._sfx_log == ["open", "close", "change"], "shutter logs open, close, then plate change")
	var p: Dictionary = game.sim.plates[0]
	check(p.has("sky_read"), "closed plate stores p.sky_read")
	check(p.sky_read == Cues.sky_band(p.clear, p.duration), "sky_read comes from the clear fraction")
	var want := Content.totality_read(p.sky_read)
	check(want != "" and game.ui.toast.text.contains(want), "shutter toast appends Cottingham's read")
	check(game.plate_changed and game.change_left > 0.0, "closing a plate with holders left starts a remembered plate change")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _test_sfx_buffers() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	for name in ["open", "change", "third", "insects", "surf", "birds"]:
		var sound: AudioStreamPlayer = game.get("audio_" + name)
		check(sound.stream is AudioStreamWAV, "%s is a synthesized WAV" % name)
		if not sound.stream is AudioStreamWAV:
			continue
		var wav: AudioStreamWAV = sound.stream
		if name in ["insects", "surf", "birds"]:
			check(wav.loop_mode != AudioStreamWAV.LOOP_DISABLED, "%s WAV loops" % name)
		var peak := 0.0
		for sample in game._sfx_samples[name]:
			peak = maxf(peak, absf(sample))
		var data := wav.data
		for i in data.size() / 2:
			peak = maxf(peak, absf(data.decode_s16(i * 2) / 32768.0))
		check(peak <= 0.9, "%s source and decoded WAV peak <= 0.9" % name)
	check(game.audio_surf.playing, "surf starts playing in PREP")
	check(game.audio_birds.playing, "birds start playing in PREP")
	game._start_night_bed()
	check(game.audio_insects.playing, "night bed starts playing")
	check("insects" in game._sfx_log, "night bed logs insects")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _test_interval_truth() -> void:
	var sim := Sim.new(1919)
	check(Judgment.interval_truth(sim) == -1, "no measured plates means no interval answer")
	check(not Judgment.interval_holds_neither(sim), "no measurements is not a neither-contained interval")
	# Exact classification wins; adjust rounded bounds only when they would change it.
	for case in [[1.3, 0.3, 0, "0.70", "1.90"], [1.75, 0.1, 1, "1.55", "1.95"], [0.87, 0.1, 2, "0.67", "1.07"],
		[3.0, 0.1, 3, "2.80", "3.20"], [2.25, 0.25, 1, "1.75", "2.75"], [1.25, 0.25, 0, "0.75", "1.75"],
		[1.5496, 0.1, 3, "1.35", "1.74"], [1.9504, 0.1, 3, "1.76", "2.15"], [0.6696, 0.1, 3, "0.47", "0.86"], [1.0704, 0.1, 3, "0.88", "1.27"],
		[1.5504, 0.1, 1, "1.35", "1.75"], [1.9496, 0.1, 1, "1.75", "2.15"], [0.6704, 0.1, 2, "0.47", "0.87"], [1.0696, 0.1, 2, "0.87", "1.27"]]:
		sim.plates = [{"usable": true, "included": true, "value": case[0], "sigma": case[1]}]
		var truth := Judgment.interval_truth(sim)
		check(truth == case[2], "interval %.4f ± %.2f has answer %d" % [case[0], case[1], case[2]])
		check(sim.evidence_class() == ["ambiguous", "favors_e", "favors_half", "ambiguous"][truth], "interval truth agrees with evidence_class")
		check(Judgment.interval_holds_neither(sim) == (truth == 3), "neither helper agrees with interval truth")
		var bounds := Judgment.interval_bounds(sim)
		var lo := "%.2f" % bounds.lo
		var hi := "%.2f" % bounds.hi
		check(lo == case[3] and hi == case[4], "displayed bounds preserve exact containment: %s to %s" % [lo, hi])
		check((lo.to_float() <= sim.EINSTEIN and sim.EINSTEIN <= hi.to_float()) == (case[2] in [0, 1]), "displayed interval agrees about 1.75")
		check((lo.to_float() <= sim.HALF and sim.HALF <= hi.to_float()) == (case[2] in [0, 2]), "displayed interval agrees about 0.87")


func _test_judgment_neither() -> void:
	var sim := Sim.new(1919)
	sim.plates = [{"number": 1, "usable": true, "quality": "good", "included": true, "trail": 0.1, "value": 2.12, "sigma": 0.17}]
	var neither := Judgment.grade(sim, "undecided", "uncertain")
	check(neither.evidence == "ambiguous" and Judgment.interval_holds_neither(sim), "2.12 ± 0.17 is ambiguous with neither prediction contained")
	check(neither.lines.any(func(line): return line.contains("都對不上")) and not neither.lines.any(func(line): return line.contains("同時容得下")), "neither-contained undecided response does not claim both fit")
	var hopeful_neither := Judgment.grade(sim, "hopeful", "uncertain")
	check(hopeful_neither.lines.has("「有希望」可以接受，但它是個寬鬆的詞。我們的數字離兩種預測都還有一段距離——片子少，也可能是儀器。"), "neither-contained hopeful response names the distance from both predictions")
	sim.plates[0].value = 1.3
	sim.plates[0].sigma = 0.3
	var both := Judgment.grade(sim, "undecided", "uncertain")
	check(both.evidence == "ambiguous" and Judgment.interval_truth(sim) == 0, "both-contained interval is also ambiguous")
	check(both.lines.has("對。誤差範圍同時容得下兩種答案。我們照實說。"), "both-contained undecided response keeps its original line")
	var hopeful_both := Judgment.grade(sim, "hopeful", "uncertain")
	check(hopeful_both.lines.has("「有希望」可以接受，但它是個寬鬆的詞。我們的數字其實還在兩種預測之間搖擺。"), "both-contained hopeful response keeps its original line")
	check(both.score == neither.score and hopeful_both.score == hopeful_neither.score, "distinguishing neither from both leaves scores unchanged")


func _test_judgment_prompt() -> void:
	var tele := ["telegram"]
	var reasons := ["reason"]
	var plain := Content.judgment_prompt(tele, reasons)
	check(plain.map(func(line): return line.key) == ["telegram", "reason"], "no interval skips the question")
	var interval := "1.75″ ± 0.10″，兩倍誤差是 1.55″ 到 1.95″"
	var prompt := Content.judgment_prompt(tele, reasons, interval)
	check(prompt.map(func(line): return line.key) == ["interval", "telegram", "reason"], "interval question precedes telegram and reason")
	check(prompt[0].s == Content.E and prompt[0].t == "先看你的數字：%s。兩倍誤差的範圍裡，容得下哪一個預測？" % interval, "Eddington asks about the formatted interval")
	check(prompt[0].choices == ["兩個都容得下（0.87″ 和 1.75″）", "只容得下 1.75″", "只容得下 0.87″", "兩個都不在裡面"], "interval choices use truth index order")
	check(prompt.slice(1) == plain, "telegram and reason prompts stay unchanged")


func _test_judgment_reasons() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.phase = game.Phase.TOTALITY
	game.sim.plates = [
		{"number": 1, "usable": true, "quality": "good", "included": true, "trail": 0.1, "value": 1.8, "sigma": 0.2},
		{"number": 2, "usable": true, "quality": "good", "included": true, "trail": 0.3, "value": 2.0, "sigma": 0.2},
	]
	game._start_judgment()
	check(game._reasons.size() == 5, "judgment offers five reasons")
	check(game._reasons[4].text.contains("星像平均拖長 0.20"), "instrument reason quotes the mean included trail")
	var c: Dictionary = game.sim.combined()
	check(game._reasons[0].text.contains("%.2f″ ± %.2f″" % [c.value, c.sigma]), "judgment stores the combined value in the reason")
	check(game.ui._seq[0].key == "interval" and game.ui._seq[0].t.contains("%.2f″ ± %.2f″，兩倍誤差是 %.2f″ 到 %.2f″" % [c.value, c.sigma, c.value - 2*c.sigma, c.value + 2*c.sigma]), "real judgment opens with the combined 2σ interval")
	game._after_judgment({"telegram": 1, "reason": 0})
	check(game._grade.reason_ok == Judgment.grade(game.sim, "hopeful", "measured").reason_ok, "judgment grades the stored measured reason")
	var original_grade: Dictionary = game._grade.duplicate(true)
	var original_reaction: Array = game.ui._seq.duplicate(true)
	game._after_judgment({"interval": 0, "telegram": 1, "reason": 0})
	check(game.ui._seq[0] == {"s": Content.E, "t": "再看一次：範圍只容得下 1.75″。"}, "wrong interval answer gets factual correction first")
	check(game._grade.score == original_grade.score and game._grade == original_grade, "wrong interval answer leaves score and grading unchanged")
	check(game.ui._seq.slice(1) == original_reaction, "correction precedes the unchanged grade lines and coda")
	game._after_judgment({"interval": 1, "telegram": 1, "reason": 0})
	check(game.ui._seq[0] == {"s": Content.E, "t": "對，範圍就是這樣讀的。"}, "correct interval answer is acknowledged first")
	check(game._grade == original_grade, "correct interval answer leaves grading unchanged")
	game.sim.plates = [{"number": 1, "usable": true, "quality": "good", "included": true, "trail": 0.1, "value": 1.5496, "sigma": 0.1}]
	game._start_judgment()
	check(game.ui._seq[0].t.contains("兩倍誤差是 1.35″ 到 1.74″") and Judgment.interval_truth(game.sim) == 3 and game.sim.evidence_class() == "ambiguous",
		"exact upper edge 1.7496 excludes 1.75 in the prompt, answer, and evidence class")
	game.sim.measured = true
	game._refresh_viewer()
	check(game.ui.viewer_note.text.contains("1.35–1.74″"), "viewer note matches the judgment interval at the upper edge")
	game.sim.plates = []
	game._start_judgment()
	check(game.ui._seq.map(func(line): return line.key) == ["telegram", "reason"], "real judgment skips the interval when nothing was measured")
	# The fifth reason through the real judgment path (no bot route reaches it).
	game.sim.drive_rate_checked = false
	game.sim.plates = [
		{"number": 1, "usable": true, "quality": "poor", "included": true, "trail": 0.6, "value": 0.87, "sigma": 0.2},
		{"number": 2, "usable": true, "quality": "poor", "included": true, "trail": 0.6, "value": 0.87, "sigma": 0.2},
	]
	game._start_judgment()
	game._after_judgment({"telegram": 2, "reason": 4})
	check(game._grade.reason_ok and game._grade.lines.any(func(l): return l.contains("Cottingham 會記得")),
		"choosing the instrument reason in the real dialogue is graded and answered")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _test_birds_quiet() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._quiet_birds()
	game._quiet_birds()
	check(game._sfx_log.count("birds_quiet") == 1, "birds quiet logs only once")
	await create_timer(6.3).timeout
	check(not game.audio_birds.playing, "birds stop after the totality fade")
	check(game.audio_surf.playing, "surf continues after birds fall quiet")
	game.stop_all_audio()
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
	# A thin patch over the Sun at the half-way mark delays the glance until
	# the cloud closes again; it never claims thick cloud during the gap.
	_reset_game(game, 1919, 149.0)
	game.sim.gaps = [{"t": 147.0, "d": 12.0, "depth": 0.1}]
	game.sim._make_clouds()
	log = []
	var glance := "Eddington 抬頭看了一眼：「雲還是很厚……繼續。」"
	var thin_seen := false
	while game.t_game < 175.0 and _count(log, glance) == 0:
		thin_seen = thin_seen or game.sim.cloud_over_sun(game.t_game) < game.GLANCE_THICK
		_step(game, log)
	check(thin_seen, "the test gap really thins the cloud after 150 s")
	check(_count(log, glance) == 1 and game.sim.cloud_over_sun(game.t_game) >= game.GLANCE_THICK,
		"the glance waits for thick cloud again (t=%.1f)" % game.t_game)
	_reset_game(game, 1919, 0.0)
	log = []
	for i in int(285.0 / GAME_STEP):
		_step(game, log)
	check(_count(log, "太陽西緣開始發亮——第三接觸快到了！") == 1, "third-contact warning uses the callout line")

	game.stop_all_audio()
	game.queue_free()
	await process_frame


# --------------------------------------------------------- 5. night viewer line

func _test_viewer_note() -> void:
	check(Chart.two_sigma_span(2.10, 0.20).is_equal_approx(Vector2(1.70, 2.50)), "chart span shows two sigma around the measured value")
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
	for plate in 2:
		game.change_left = 0.0
		game._toggle_shutter()
		for i in 12:
			game._process_totality(STEP)
		game._toggle_shutter()
	# Select one measurable plate so the combined-result note is exercised.
	game.sim.plates[0].merge({"included": true, "usable": true, "value": 2.10, "sigma": 0.20}, true)
	game._refresh_viewer()
	check(not game.ui.viewer_note.text.contains("星像清楚"), "viewer note hides quality counts before measuring")
	check(not game.ui.viewer_note.text.contains("兩倍誤差"), "viewer note hides the two-sigma criterion before measuring")
	game.sim.measured = true
	game._refresh_viewer()
	check(game.ui.viewer_note.text.contains("星像清楚"), "viewer note shows quality counts after measuring")
	check(game.ui.viewer_note.text.contains("兩倍誤差"), "viewer note explains the two-sigma criterion after measuring")
	game.stop_all_audio()
	game.queue_free()


func _test_night_viewer() -> void:
	var ui = UI.new()
	root.add_child(ui)
	await process_frame
	var plates := [
		{"number": 1, "start": 10.0, "duration": 8.0, "sunlit": false, "included": false, "usable": true, "sky_read": "clear", "stars": 7, "quality": "good"},
		{"number": 2, "start": 20.0, "duration": 0.4, "sunlit": false, "included": false, "usable": false, "sky_read": "brief"},
		{"number": 3, "start": 24.0, "duration": 2.0, "sunlit": true, "included": false, "usable": false},
		{"number": 4, "start": 30.0, "duration": 3.0, "sunlit": false, "included": false, "usable": false, "stars": 3, "quality": "unusable"},
		{"number": 5, "start": 40.0, "duration": 6.0, "sunlit": false, "included": false, "usable": true, "sky_read": "mixed", "stars": 6, "quality": "poor"},
	]
	ui.open_viewer(plates, null, [null, null, null, null, null], false)
	check(ui.viewer_sfx_log.is_empty(), "night viewer automatic selection is silent")
	for name in ["plate", "mark", "measure"]:
		var stream = ui._viewer_sfx[name].stream
		check(stream is AudioStreamWAV, "%s viewer sound is a synthesized WAV" % name)
		if not stream is AudioStreamWAV:
			continue
		check(stream.mix_rate == 22050, "%s viewer sound is 22050 Hz" % name)
		var peak := 0.0
		var data: PackedByteArray = stream.data
		for i in data.size() / 2:
			peak = maxf(peak, absf(data.decode_s16(i * 2) / 32768.0))
		check(peak <= 0.8, "%s viewer sound peak <= 0.8" % name)
		if name == "measure":
			check(stream.get_length() >= 0.8 and stream.get_length() <= 1.0, "viewer measure sound lasts 0.8-1.0 seconds")
	ui._select_plate(0, null)
	ui.include_box.button_pressed = true
	check(ui.viewer_sfx_log.back() == "mark", "including a plate sounds a pencil mark")
	ui.measure_btn.pressed.emit()
	check(ui.viewer_sfx_log.back() == "measure", "measuring sounds the micrometer")
	check(ui.plate_info.text.contains(Content.totality_read_night("clear")), "night viewer shows the clear read")
	check(ui.plate_info.text.contains("可辨識的星點：7 顆"), "night viewer shows seven visible stars")
	check(not ui.plate_info.text.contains("星像清楚"), "night viewer hides good quality before measuring")
	ui._select_plate(1, null)
	check(ui.viewer_sfx_log.back() == "plate", "selecting a real plate sounds glass")
	check(ui.plate_info.text.contains(Content.totality_read_night("brief")), "night viewer shows the brief read")
	ui._select_plate(2, null)
	check(not ui.plate_info.text.contains("拍攝時："), "sunlit plate has no read")
	ui._select_plate(3, null)
	check(not ui.plate_info.text.contains("拍攝時："), "plate without a band has no read")
	check(ui.plate_info.text.contains("[color=#e88]可辨識的星點：3 顆[/color]"), "night viewer warns about three visible stars")
	check(not ui.plate_info.text.contains("星像清楚"), "night viewer does not label an unusable plate clear")
	ui._select_plate(4, null)
	check(not ui.plate_info.text.contains("拖長或被雲霧蓋住"), "night viewer hides poor quality before measuring")
	ui._select_plate(-2, null)
	check(ui.viewer_sfx_log.back() == "plate", "selecting the comparison plate sounds glass")
	ui.set_viewer_locked(true)
	ui.reselect_btn.pressed.emit()
	check(ui.viewer_sfx_log.back() == "mark", "reselecting sounds a pencil mark")
	ui._select_plate(0, null)
	check(ui.plate_info.text.contains("星像清楚"), "night viewer shows good quality after measuring")
	ui._select_plate(4, null)
	check(ui.plate_info.text.contains("可量，但星像拖長或被雲霧蓋住。") and not ui.plate_info.text.contains("星像清楚"), "night viewer explains a poor plate after measuring")
	# A callout that has faded out releases its space in the panel.
	ui.set_callout("測試提示", 0.5)
	check(ui.callout.visible and ui.callout.text == "測試提示", "callout shows while active")
	ui._process(0.6)
	check(not ui.callout.visible and ui.callout.text == "", "expired callout hides and clears its text")
	ui._process(0.1)
	check(not ui.callout.visible, "expired callout stays hidden")

	ui.queue_free()
	await process_frame
