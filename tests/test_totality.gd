extends SceneTree
## Headless checks for the M5 totality legibility layer.
## Run: godot --headless --path . --script res://tests/test_totality.gd

const Sim := preload("res://scripts/eclipse_sim.gd")
const Cues := preload("res://scripts/totality_cues.gd")
const Content := preload("res://scripts/content.gd")
const UI := preload("res://scripts/ui.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Chart := preload("res://scripts/chart.gd")
const Prompts := preload("res://scripts/prompts.gd")
const Settings := preload("res://scripts/settings.gd")

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
	await _test_rehearsal()
	await _test_ready_status()
	await _test_empty_rack_wait()
	await _test_shutter_read()
	await _test_sfx_buffers()
	await _test_viewer_note()
	_test_interval_truth()
	_test_judgment_neither()
	_test_judgment_prompt()
	await _test_judgment_reasons()
	await _test_strict_poor_only()
	await _test_report_rule_layout()
	await _test_birds_quiet()
	await _test_callouts()
	await _test_night_viewer()
	await _test_reselect_reason()
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

func _rehearsal_press(event) -> void:
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _visible_sun_obstruction(game: Node) -> String:
	var from: Vector3 = game.player.camera.global_position
	for instance in game.find_children("*", "MeshInstance3D", true, false):
		if not instance.is_visible_in_tree() or instance.mesh == null:
			continue
		var inverse: Transform3D = instance.global_transform.affine_inverse()
		var origin: Vector3 = inverse * from
		var direction: Vector3 = inverse.basis * game.sim.sun_dir
		if instance.mesh.get_aabb().intersects_ray(origin, direction) == null:
			continue
		var faces: PackedVector3Array = instance.mesh.get_faces()
		for j in range(0, faces.size(), 3):
			if Geometry3D.ray_intersects_triangle(origin, direction, faces[j], faces[j + 1], faces[j + 2]) != null:
				return str(instance.get_path())
	return ""


func _test_rehearsal() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game._start_game()
	game._interact("eddington")
	while game.ui.dialog_active():
		if game.ui._choice_buttons.is_empty():
			game.ui._advance()
		else:
			game.ui._choose(0)
	check(game.sim.briefed, "real briefing unlocks Eddington's PREP dialogue")
	var plates_before: Array = game.sim.plates.duplicate(true)
	var gaps_before: Array = game.sim.gaps.duplicate(true)
	var seed_before: int = game.sim.run_seed
	var available_before: int = game.sim.plates_available()
	var prep_before: float = game.prep_left
	var clocks_before: Array = [game.t_game, game.change_left, game._tick_acc, game.tot_done]
	var cases := ["early", "inside", "late", "never", "never stop"]
	var expected := ["你在雲變薄前就開了：那張會起霧。", "你在薄的那段裡開、在變厚前停：那張會是清楚的。", "你停得晚，雲回來了：星像會被霧蓋掉一半。", "窗口過去了，你沒有開：那一段就沒有底片。", "你一直沒喊停，雲回來了：星像會被霧蓋掉一半。真的全食裡，要自己喊。"]
	var shutter := InputEventAction.new()
	shutter.action = "shutter"
	game.player.global_position = Vector3(0, 0.05, 0)
	game.player.yaw = 0.4
	game.player.pitch = -0.2
	await physics_frame
	check(_visible_sun_obstruction(game) != "", "visible shelter blocks the Sun before rehearsal")
	for i in cases.size():
		game._interact("eddington")
		game.ui._advance()
		check(game.ui._choice_buttons.size() == 4, "PREP offers rehearsal and keeps dismiss last")
		game.ui._choose(2)
		check(game.rehearsing and not game.player.can_move and game.player.can_look, "rehearsal freezes movement and retains look")
		check(game.ui.toast.text == "Eddington：沒有底片，只練眼睛和口令。看太陽那一塊雲——變薄就按［%s］喊『開始』，變厚之前喊『停』。" % Prompts.key("shutter"), "rehearsal teaches the shutter button")
		var thick: float = game.sky_mat.get_shader_parameter("practice_cloud")
		if i == 0:
			await _rehearsal_press(shutter)
		game._process_prep(4.0)
		if i == 0:
			var obstruction := _visible_sun_obstruction(game)
			check(obstruction == "", "Sun is unobstructed during practice: " + obstruction)
			check(not game.world.roof.visible, "practice opens the shelter roof")
			check(game.player.pitch > 0.0, "practice turns the camera toward the Sun")
		var thin: float = game.sky_mat.get_shader_parameter("practice_cloud")
		check(thin < thick, "practice sky shader shows thinner cloud over the Sun")
		if i == 1 or i == 2 or i == 4:
			await _rehearsal_press(shutter)
		if i == 2 or i == 3:
			game._process_prep(6.0)
		if i == 4:
			game._process_prep(8.4)
			check(game._rehearsal_step == 1, "open shutter waits three seconds after the window closes")
			var sounds_before: int = game._sfx_log.size()
			game._process_prep(0.1)
			check(game._sfx_log.slice(sounds_before) == ["close", "change"], "timeout closes the shutter and changes plates")
		if i != 3 and i != 4:
			await _rehearsal_press(shutter)
		check(game.ui.toast.text.contains(expected[i]), "%s timing gives its feedback" % cases[i])
		check(game._rehearsal_step == 2 and game.prep_left == prep_before, "change wait freezes preparation")
		if i == 4:
			await _rehearsal_press(shutter)
			check(game.ui.toast.text == "Eddington 還在換片……", "press during automatic change reports the wait")
		await create_timer(Sim.PLATE_CHANGE_S + 0.1).timeout
		check(not game.rehearsing and game.player.can_move, "four-second change restores input")
		check(game.world.roof.visible and is_equal_approx(game.player.yaw, 0.4) and is_equal_approx(game.player.pitch, -0.2), "rehearsal restores roof and camera")
		check(is_equal_approx(game.player.global_position.z, 0.0), "rehearsal returns the player to the original position")
		check(game.sky_mat.get_shader_parameter("practice_cloud") == -1.0, "rehearsal restores the sky shader")
		check(game.sim.plates == plates_before and game.sim.gaps == gaps_before and game.sim.run_seed == seed_before and game.sim.plates_available() == available_before, "rehearsal preserves simulation and inventory")
		check(not game.sim.is_exposing() and not game._ever_exposed and not game.plate_changed, "dry run leaves exposure history untouched")
		check([game.t_game, game.change_left, game._tick_acc, game.tot_done] == clocks_before, "dry run leaves totality clocks untouched")
	game._process_prep(0.5)
	check(game.prep_left == prep_before - 0.5, "PREP countdown resumes after rehearsal")
	game._interact("eddington")
	game.ui._advance()
	game.ui._choose(3)
	check(not game.rehearsing and game.phase == game.Phase.PREP, "dismiss remains a no-op")
	game._interact("eddington")
	game.ui._advance()
	game.ui._choose(1)
	check(game.ui.text_label.text.contains("雲薄的時候"), "choice 1 still explains exposure")
	while game.ui.dialog_active():
		game.ui._advance()
	game._interact("eddington")
	game.ui._advance()
	game.ui._choose(0)
	await create_timer(2.2).timeout
	check(game.phase == game.Phase.TOTALITY and not game._busy, "choice 0 still begins real totality")
	check(game.ui.prompt_label.text == "［%s］開始／停" % Prompts.key("shutter"), "totality retains a compact shutter reminder")
	game.ui._process(7.1)
	game._process_totality(0.1)
	check(game.ui.prompt_label.text == "［%s］開始／停" % Prompts.key("shutter"), "shutter reminder survives the seven-second toast")
	game._end_totality()
	game._process_totality(0.1)
	check(game.tot_done and game.ui.prompt_label.text == "", "third contact clears the reminder without restoring it")
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	Prompts.joypad = false


func _test_ready_status() -> void:
	var states := [
		[true, true, 0, "可用底片 6 張。時鐘驅動：上了發條並校過走速。", 6],
		[true, false, 0, "可用底片 6 張。時鐘驅動：上了發條但沒校走速。", 6],
		[false, false, 0, "可用底片 6 張。時鐘驅動：還沒上發條。", 6],
		[true, true, 2, "可用底片 8 張（你手上的 2 張會交給 Cottingham）。時鐘驅動：上了發條並校過走速。", 8],
	]
	for state in states:
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game._start_game()
		game.sim.briefed = true
		game.sim.plates_delivered = 2
		game.sim.drive_wound = state[0]
		game.sim.drive_rate_checked = state[1]
		game.sim.plates_carried = state[2]
		game._interact("eddington")
		check(game.ui.text_label.text == state[3], "real PREP dialogue reports plates, handoff and drive: " + state[3])
		check(game.ui._choice_buttons.is_empty(), "status appears before the PREP question")
		game.ui._advance()
		check(game.ui._seq[1].choices[0] == "開始——就位等待全食。", "choice 0 explicitly starts totality")
		game.ui._choose(0)
		await create_timer(2.2).timeout
		check(game.phase == game.Phase.TOTALITY and not game._busy, "every drive state can start totality without gating")
		check(game.plates_left == state[4] and game.sim.plates_available() == state[4], "totality has exactly the advertised plate count")
		check(game.sim.plates_carried == 0 and game.sim.plates_delivered == state[4] - Sim.BASE_PLATES, "starting totality hands over the carried plates")
		game.stop_all_audio()
		game.queue_free()
		await process_frame


func _test_empty_rack_wait() -> void:
	for action in ["shutter", "interact"]:
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game._start_game()
		await game._begin_totality()
		while game.plates_left > 0:
			game._toggle_shutter()
			game._process_totality(1.0 / Sim.TIME_SCALE)
			check(game.ui.prompt_label.text == "［%s］開始／停" % Prompts.key("shutter"), "an exposing plate keeps the normal stop prompt")
			var before_stop: float = game.t_game
			game._toggle_shutter()
			check(game.t_game == before_stop and not game.sim.is_exposing(), "stop closes the exposure without skipping time, including the last plate")
			game._process_totality(Sim.PLATE_CHANGE_S / Sim.TIME_SCALE)
		check(game.t_game < 30.0, "rack was exhausted early through actual exposures and plate changes")
		check(game.ui.prompt_label.text == "底片用完了。［%s］等待第三接觸" % Prompts.key("shutter"), "empty rack offers waiting for third contact")
		var evidence: Array = game.sim.plates.duplicate(true)
		var press := InputEventAction.new()
		press.action = action
		await _rehearsal_press(press)
		check(game.t_game == Sim.TOTALITY_S - 3.0, action + " jumps to three game-seconds before contact")
		game._process_totality(1.0 / Sim.TIME_SCALE)
		await _rehearsal_press(press)
		check(game.t_game == Sim.TOTALITY_S - 2.0, "repeated wait cannot move time backwards")
		game._process_totality(1.0 / Sim.TIME_SCALE)
		check(not game.tot_done, "third contact does not arrive before three game-seconds")
		game._process_totality(1.0 / Sim.TIME_SCALE)
		check(game.tot_done and game._sfx_log.count("third") == 1, "third contact arrives after three game-seconds exactly once")
		check(game.ui.toast.text.begins_with("第三接觸。陽光像鑽石一樣"), "waiting preserves the diamond-ring announcement")
		await create_timer(0.2).timeout
		check(game.sky_mat.get_shader_parameter("third_contact") != Vector2.ZERO, "the actual diamond-ring tween still runs")
		var night_entries: Array = []
		game.ui.dialogue_entry.connect(func(_speaker):
			if game.phase == game.Phase.NIGHT:
				night_entries.append(game.ui.text_label.text))
		# Run beyond contact repeatedly while its authored transition completes.
		for i in 100:
			game._process_totality(STEP)
			await create_timer(STEP).timeout
		check(game.phase == game.Phase.NIGHT and not game._busy, "empty rack reaches the real NIGHT scene")
		check(night_entries.size() == 1 and game._sfx_log.count("third") == 1, "NIGHT introduction and third contact each run once")
		check(game.sim.plates == evidence, "waiting and NIGHT preserve every exposure field")
		game.stop_all_audio()
		game.queue_free()
		await process_frame


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
	check(plain.map(func(line): return line.key) == ["telegram", "reason"], "judgment contains only telegram and reason")
	var interval := "1.75″ ± 0.10″，兩倍誤差是 1.55″ 到 1.95″"
	var prompt := Content.interval_prompt(interval)
	check(prompt.map(func(line): return line.key) == ["interval"], "interval question is its own dialogue")
	check(prompt[0].s == Content.E and prompt[0].t == "先看你的數字：%s。圖上的粗線是你的數字加減一個誤差，兩端延伸的細線是兩倍誤差。細線範圍裡，容得下哪一個預測？" % interval, "Eddington asks about the formatted interval")
	check(prompt[0].choices == ["兩個都容得下（0.87″ 和 1.75″）", "只容得下 1.75″", "只容得下 0.87″", "兩個都不在裡面"], "interval choices use truth index order")


func _test_judgment_reasons() -> void:
	root.size = Vector2i(1600, 900)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.phase = game.Phase.TOTALITY
	game.sim.plates = [
		{"number": 1, "start": 10.0, "duration": 6.0, "sunlit": false, "usable": true, "quality": "good", "included": true, "trail": 0.1, "value": 1.8, "sigma": 0.2},
		{"number": 2, "start": 20.0, "duration": 6.0, "sunlit": false, "usable": true, "quality": "good", "included": true, "trail": 0.3, "value": 2.0, "sigma": 0.2},
	]
	game.sim.rule_id = "strict"
	game.plate_textures = [null, null]
	game.ui.hide_title()
	game._open_viewer()
	game._on_measure()
	await process_frame
	await process_frame
	await _click_control(game.ui.report_btn)
	check(game.ui.viewer.visible and game.ui._viewer_locked, "report button keeps the measured evidence visible and locked")
	for action in game.ui.report_btn.get_parent().get_children() + [game.ui.include_box]:
		check(not action.is_visible_in_tree() and action.disabled, "report hides and disables %s" % action.text)
	check(game.ui.dialog_panel.get_index() > game.ui.viewer.get_index(), "dialogue draws and receives clicks above the viewer")
	check(not game.ui.dialog_panel.get_global_rect().intersects(game.ui.chart.get_global_rect()), "interval choices leave the chart visible")
	check(root.gui_get_focus_owner() == game.ui._choice_buttons[0], "report puts focus on the interval choices")
	var selected: int = game.ui._viewer_sel
	await _click_control(game.ui.thumbs.get_child(2))
	game.ui.include_box.toggled.emit(false)
	game._on_plate_toggled(0, false)
	check(game.ui._viewer_sel == selected and game.sim.plates.all(func(p): return p.included), "report prevents browsing and changing the selected evidence")
	check(root.gui_get_focus_owner() == game.ui._choice_buttons[0], "clicking evidence cannot steal dialogue focus")
	check(game._reasons.size() == 5, "judgment offers five reasons")
	check(game._reasons[4].text.contains("星像平均拖長 0.20"), "instrument reason quotes the mean included trail")
	var c: Dictionary = game.sim.combined()
	var bounds: Dictionary = Judgment.interval_bounds(game.sim)
	check(game.ui.chart.revealed and game.ui.chart.combined == c, "report chart retains the measured combined value")
	var chart_span := Chart.two_sigma_span(c.value, c.sigma)
	check(("%.2f" % chart_span.x).to_float() == bounds.lo and ("%.2f" % chart_span.y).to_float() == bounds.hi, "report chart interval agrees with judgment bounds")
	check(game.ui.viewer_note.text.contains("%.2f–%.2f″" % [bounds.lo, bounds.hi]), "report note agrees with the prompt interval")
	check(game.ui.viewer_rule.text == "你寫下的規則：" + Content.rules_prompt(false)[-1].choices[0], "report repeats the rule in the player's own words")
	check(game._reasons[0].text.contains("%.2f″ ± %.2f″" % [c.value, c.sigma]), "judgment stores the combined value in the reason")
	check(game.ui._seq[0].key == "interval" and game.ui._seq[0].t.contains("%.2f″ ± %.2f″，兩倍誤差是 %.2f″ 到 %.2f″" % [c.value, c.sigma, c.value - 2*c.sigma, c.value + 2*c.sigma]), "real judgment opens with the combined 2σ interval")
	check(game.ui._seq.size() == 1 and game.ui._choice_buttons.size() == 4, "only interval choices exist before the answer")
	var evidence_before: Dictionary = game.sim.combined().duplicate(true)
	game.ui._choose(0) # Wrong: this interval contains only 1.75″.
	check(game._interval_answer == 0, "real interval dialogue stores the answer")
	var correction_shown: bool = game.ui.text_label.text.contains("再看一次")
	check(correction_shown and game.ui._choice_buttons.is_empty(), "wrong interval feedback is shown before telegram choices exist")
	check(game.ui.viewer.visible and game.ui._viewer_locked, "evidence stays visible during wrong-answer feedback")
	# Stop this flow on a regression so later choices do not target the wrong entry.
	if not correction_shown or not game.ui._choice_buttons.is_empty():
		game.stop_all_audio()
		game.queue_free()
		await process_frame
		return
	check(game._pending == "judgment" and game.ui._seq_i == 0 and not game.ui._seq[0].has("choices"), "feedback leads the telegram sequence")
	check(game.ui.text_label.text == "再看一次：範圍只容得下 1.75″。\n看圖上的細線：兩條預測線，哪一條落在細線裡面？", "wrong answer corrects containment and points at the chart")
	check(game._grade.is_empty() and game.sim.combined() == evidence_before, "interval feedback leaves evidence and grading untouched")
	game.ui._advance()
	check(game.ui._seq[game.ui._seq_i].key == "telegram" and game.ui._choice_buttons.size() == Judgment.TELEGRAMS.size(), "telegram choices appear after feedback is advanced")
	check(game.ui.viewer.visible and root.gui_get_focus_owner() == game.ui._choice_buttons[0], "telegram choices keep evidence visible and hold focus")
	game.ui._choose(1)
	check(game.ui._seq[game.ui._seq_i].key == "reason", "telegram still leads to the reason")
	check(game.ui.viewer.visible and root.gui_get_focus_owner() == game.ui._choice_buttons[0], "reason choices keep evidence visible and hold focus")
	game.ui._choose(0)
	check(game._pending == "reaction" and not game.ui.viewer.visible, "viewer closes as the reaction starts")
	check(game._grade == Judgment.grade(game.sim, "hopeful", "measured"), "real dialogue grades the stored measured reason")
	var wrong_grade: Dictionary = game._grade.duplicate(true)
	var wrong_reaction: Array = game.ui._seq.duplicate(true)
	game._start_judgment()
	game.ui._choose(Judgment.interval_truth(game.sim))
	check(game.ui.text_label.text == "對，範圍就是這樣讀的。" and game.ui._choice_buttons.is_empty(), "correct interval answer is acknowledged before telegram choices")
	game.ui._advance()
	game.ui._choose(1)
	game.ui._choose(0)
	check(game._grade == wrong_grade and game._grade.score == wrong_grade.score, "right and wrong interval answers yield identical grading and score")
	check(game.ui._seq == wrong_reaction, "interval feedback is absent from the unchanged grading reaction")
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
	game.ui._choose(Judgment.interval_truth(game.sim))
	game.ui._advance()
	game.ui._choose(2)
	game.ui._choose(4)
	check(game._grade.reason_ok and game._grade.lines.any(func(l): return l.contains("Cottingham 會記得")),
		"choosing the instrument reason in the real dialogue is graded and answered")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _test_strict_poor_only() -> void:
	var honest_line := "只有拖長或起霧的底片可用。你照規則量了它們，也該把這份不確定寫進電報。"
	for scenario in [[false, 0], [true, 0], [false, 1], [false, 2]]:
		var with_good: bool = scenario[0]
		var rule_index: int = scenario[1]
		var game := _make_game()
		_reset_game(game, 77, 0.0)
		game.sim.drive_rate_checked = true
		# A long exposure records enough stars but trails; the optional short
		# exposure in the late gap supplies a clear plate in the same seeded sky.
		# A quarter-second exposure also leaves a real unusable plate to exclude.
		var events := {0: "open", 1: "close", 40: "open", 720: "close"} # 10–180 game-seconds
		if with_good:
			var start := int(ceil((game.sim.gaps[2].t + 2.0) / GAME_STEP))
			events[start] = "open"
			events[start + 32] = "close" # eight game-seconds
		_run_main(game, events)
		check(game.sim.plates.size() == (3 if with_good else 2), "real shutter produces the expected plates")
		check(not game.sim.plates[0].usable, "quarter-second exposure is unusable")
		check(game.sim.plates[1].usable and game.sim.plates[1].quality == "poor", "long exposure is poor but usable")
		check(game.sim.count_quality("good") == (1 if with_good else 0), "short exposure controls whether any good plate exists")
		game.phase = game.Phase.NIGHT
		game.ui.hide_title()
		for plate in game.sim.plates:
			game.plate_textures.append(null)
		game._interact("measure")
		for step in 12:
			if not game.ui.dialog_active():
				break
			var entry: Dictionary = game.ui._seq[game.ui._seq_i]
			if entry.has("choices"):
				var key: String = entry.get("key", "")
				check(key in ["rule", "bet", "bet_sure"], "measurement opens the real rule and prediction prompts")
				game.ui._choose(rule_index if key == "rule" else 0)
			else:
				game.ui._advance()
			await process_frame
		check(game.sim.rule_id == ["strict", "after", "none"][rule_index] and game.ui.viewer.visible,
			"rule prompt records the choice and opens the viewer")
		for i in game.sim.plates.size():
			game.ui.plate_toggled.emit(i, game.sim.plates[i].usable)
		game.ui.measure_btn.pressed.emit()
		check(game.sim.measured and game.sim.included_usable().size() == (2 if with_good else 1), "real viewer measures all usable plates")
		var grade := Judgment.grade(game.sim, "undecided", "uncertain")
		var expected_clean := rule_index == 0 and not with_good
		check(grade.clean == expected_clean, "only strict poor-only selection keeps the clean point")
		check(grade.score == grade.fit + int(grade.reason_ok) + int(expected_clean), "score counts exactly the expected clean point")
		check(grade.lines.has(honest_line) == expected_clean, "only strict poor-only selection receives the honest uncertainty line")
		check(grade.lines.any(func(line): return line.contains("也被你選進來了——再拿起來看看，它的星像合不合那一行")) == with_good,
			"strict mixed selection still flags its poor plate as a rule violation")
		if expected_clean:
			check(grade.lines.any(func(line): return line.begins_with("你照著量之前寫下的規則選片")), "poor-only strict selection acknowledges following the written rule")
			game.ui.reselect_btn.pressed.emit()
			game.ui.plate_toggled.emit(0, true)
			game.ui.measure_btn.pressed.emit()
			game.ui._choose(0) # Quality cannot justify adding an unusable plate.
			var unusable := Judgment.grade(game.sim, "undecided", "uncertain")
			check(not unusable.clean and not unusable.lines.has(honest_line)
				and unusable.lines.any(func(line): return line.contains("也被你選進來了——再拿起來看看，它的星像合不合那一行")),
				"including an unusable plate still loses clean and receives no compliance acknowledgment")
			game.ui.reselect_btn.pressed.emit()
			game.ui.plate_toggled.emit(0, false)
			game.ui.measure_btn.pressed.emit()
			game.ui._choose(1) # Explicitly result-driven, now only poor plates included.
			var reselected := Judgment.grade(game.sim, "undecided", "uncertain")
			check(game.sim.selection_report().included_unusable.is_empty() and not reselected.clean
				and not reselected.lines.has(honest_line), "unjustified poor-only reselection still loses clean and receives no compliance acknowledgment")
		game.stop_all_audio()
		game.queue_free()
		await process_frame


func _click_control(control: Control) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = control.get_global_rect().get_center()
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _test_report_rule_layout() -> void:
	var old_size := root.size
	var old_scale := Settings.text_scale
	root.size = Vector2i(1600, 900)
	for scale in [1.0, 1.2]:
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		Settings.text_scale = scale
		Settings.refresh_fonts(self)
		game.ui.theme_res.default_font_size = Settings.fs(21)
		game.sim = Sim.new(1919)
		game.phase = game.Phase.NIGHT
		game.sim.rule_id = "strict"
		game.sim.measured = true
		for i in 12:
			game.sim.plates.append({"number": i + 1, "start": float(i * 10), "duration": 6.0, "sunlit": false,
				"usable": true, "quality": "good", "included": true, "trail": 0.1, "value": 1.75, "sigma": 0.2})
			game.plate_textures.append(null)
		game.ui.hide_title()
		game._open_viewer()
		for frame in 4:
			await process_frame
		var note_before: String = game.ui.viewer_note.text
		await _click_control(game.ui.report_btn)
		for stage in ["interval", "feedback", "telegram", "reason"]:
			for frame in 4:
				await process_frame
			var chart_rect: Rect2 = game.ui.chart.get_global_rect()
			var dialog_rect: Rect2 = game.ui.dialog_panel.get_global_rect()
			print("report layout scale=%s stage=%s chart=%s dialogue=%s" % [scale, stage, chart_rect, dialog_rect])
			check(root.get_visible_rect().encloses(chart_rect) and not dialog_rect.intersects(chart_rect),
				"scale %s %s leaves the whole chart visible" % [scale, stage])
			check(root.get_visible_rect().encloses(dialog_rect), "scale %s %s dialogue fits viewport" % [scale, stage])
			var rule_rect: Rect2 = game.ui.viewer_rule.get_global_rect()
			check(root.get_visible_rect().encloses(rule_rect) and not dialog_rect.intersects(rule_rect),
				"scale %s %s rule fits viewport and stays above dialogue" % [scale, stage])
			match stage:
				"interval":
					check(game.ui._seq[game.ui._seq_i].key == "interval", "real report starts at interval")
					await _click_control(game.ui._choice_buttons[Judgment.interval_truth(game.sim)])
				"feedback":
					game.ui._advance()
				"telegram":
					check(game.ui._seq[game.ui._seq_i].key == "telegram", "real report reaches telegram")
					await _click_control(game.ui._choice_buttons[1])
				"reason":
					check(game.ui._seq[game.ui._seq_i].key == "reason" and game.ui._choice_buttons.size() == 5,
						"real report reaches five reason choices")
		check(game.ui.thumbs.get_child_count() == 13, "report rule layout has twelve plates and a comparison thumbnail")
		check(game.ui.viewer_rule.is_visible_in_tree() and game.ui.viewer_rule.text == "你寫下的規則：" + Content.rules_prompt(false)[-1].choices[0], "report shows the complete authored rule")
		check(game.ui.viewer_note.text == note_before and not note_before.contains("你寫下的規則"), "report rule leaves the measurement note unchanged")
		game.ui.close_viewer()
		game._open_viewer()
		var growth := clampf((float(game.get_viewport().get_window().size.y) - 720.0) / 360.0, 0.0, 1.0)
		check(is_equal_approx(game.ui.chart.custom_minimum_size.y, 420.0 + 160.0 * growth), "reopening the viewer restores the measurement chart height")
		game.stop_all_audio()
		game.queue_free()
		await process_frame
	Settings.text_scale = old_scale
	Settings.refresh_fonts(self)
	root.size = old_size


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
	var chart := Chart.new()
	chart.size = Vector2(560, 420)
	root.add_child(chart)
	chart.set_data([
		{"label": "弱", "value": 1.0, "sigma": 0.1, "weak": true},
		{"label": "良", "value": 1.2, "sigma": 0.1, "weak": false},
	], {}, true)
	for frame in 2:
		await process_frame
	check(chart.drawn().markers == ["hollow", "filled"],
		"weak plate marker is drawn as a hollow ring while a good plate is a filled dot")
	chart.free()
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
	for i in 3:
		game.sim.rule_id = ["strict", "after", "none"][i]
		game._refresh_viewer()
		check(game.ui.viewer_rule.text == "你寫下的規則：" + Content.rules_prompt(false)[-1].choices[i], "viewer recalls rule %s verbatim" % game.sim.rule_id)
	game.stop_all_audio()
	game.queue_free()


func _test_night_viewer() -> void:
	load("res://scripts/main.gd")._ensure_inputs()
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


func _test_reselect_reason() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.phase = game.Phase.NIGHT
	game.sim = Sim.new(1919)
	game.sim.plates = [
		{"index": 0, "fog": 0.05, "number": 1, "start": 10.0, "duration": 8.0, "sunlit": false, "included": true, "usable": true, "stars": 7, "quality": "good", "trail": 0.1, "value": 1.75, "sigma": 0.2},
		{"number": 2, "start": 20.0, "duration": 20.0, "sunlit": false, "included": true, "usable": true, "stars": 5, "quality": "poor", "trail": 0.5, "value": 0.9, "sigma": 0.4},
	]
	game.plate_textures = [null, null]
	game._open_viewer()
	game.ui.measure_btn.pressed.emit()
	var first: Dictionary = game.sim.combined().duplicate()
	check(game.sim.first_result == first, "first measurement stores the combined result")
	game.ui.reselect_btn.pressed.emit()
	game.ui._select_plate(1, null)
	game.ui.include_box.button_pressed = false
	game.ui.measure_btn.pressed.emit()
	check(game.ui.dialog_active() and game._pending == "reselect_reason", "changed selection asks for a reason before locking")
	check(not game.sim.measured and not game.ui.viewer.visible, "measurement waits with the viewer hidden for the reason")
	check(game.ui._seq[0].t == "你改了選片。寫下來：為什麼？" and game.ui._seq[0].choices == ["星像品質：它拖長、起霧或星不夠", "第一次的數字不合我的預期", "說不上來"], "reason dialogue has the three authored choices")
	check(root.gui_get_focus_owner() == game.ui._choice_buttons[0], "reason dialogue focuses the first choice")
	game.ui._choice_buttons[0].pressed.emit()
	check(game.sim.measured and game.sim.reselect_reason == "quality" and game.sim.reselected_after_seeing, "answer records the reason and finishes measurement")
	check(game.sim.reselect_removed == [2] and game.sim.reselect_added.is_empty() and game.sim.selection_report().reselect_justified, "real selection change records the removed poor plate")
	check(game.sim.first_result == first and game.sim.first_result != game.sim.combined(), "reselection preserves the actual first value and uncertainty")
	var first_line := "第一次量：%.2f″ ± %.2f″" % [first.value, first.sigma]
	check(game.ui.viewer_note.text.contains(first_line), "viewer note retains 第一次量 with the original values")
	check(game.ui.viewer.visible and game.ui.measure_btn.disabled and root.gui_get_focus_owner() == game.ui.reselect_btn, "measurement returns to the locked viewer with reselect focus")
	game.ui.reselect_btn.pressed.emit()
	game.ui.measure_btn.pressed.emit()
	check(not game.ui.dialog_active() and game.sim.first_result == first, "unchanged reselection does not ask again or replace the first result")
	game._telegram = 1
	game._reason = 0
	game._reasons = Judgment.reasons_for(game.sim)
	game._grade = Judgment.grade(game.sim, "hopeful", "measured")
	game._show_ending()
	check(game.ui.ending_text.text.contains(first_line), "ending retains the first result")
	check(game.ui.ending_telegram.text.contains(Judgment.TELEGRAMS[1].text)
		and game.ui.ending_telegram.text.contains("理由：" + game._reasons[0].text), "real ending displays the player's telegram and chosen reason")
	check(game.ui.ending_telegram.text.contains("電報　普林西比 → 倫敦　Dyson 收")
		and game.ui.ending_text.text.contains("本子上：%.2f″ ± %.2f″（示意模擬）（%s）" % [game.sim.combined().value, game.sim.combined().sigma, first_line]), "telegram form keeps current and first measurements on one workbook line")
	check(not game.ui.ending_text.text.contains("Eddington 的回應")
		and not game.ui.ending_text.text.contains("你留下的證據"), "ending tableau leaves assessment and evidence behind the review toggle")
	check(game.ui.ending_review.text.contains("Eddington 的回應")
		and game._grade.lines.all(func(line): return game.ui.ending_review.text.contains("· " + line)), "review retains every Eddington response")
	check(game.ui.ending_review.text.contains("你留下的證據")
		and game.ui.ending_review.text.contains("· 拍了 2 張底片")
		and game.ui.ending_review.text.contains("· 你量了 1 張，合併 1.75″ ± 0.20″（示意模擬）。")
		and game.ui.ending_review.text.contains(first_line)
		and game.ui.ending_review.text.contains("· 時鐘驅動："), "review retains the evidence inventory")
	check(game.ui.ending_review.text.contains("拍了 2 張底片（底片匣一共") and not game.ui.ending_review.text.contains("可用底片"),
		"evidence count names the cassette total, not usable plates")
	check(game.ui.ending_history.text.contains("三分之二"), "history explains what the probable error meant")
	check(not game.ui.ending_review.visible and game.ui.ending_review_toggle.text == "回顧證據與評語", "review starts hidden")
	game.ui.ending_review_toggle.pressed.emit()
	check(game.ui.ending_review.visible and game.ui.ending_review_toggle.text == "收起回顧", "review toggle reveals the assessment and evidence")
	game.ui.ending_review_toggle.pressed.emit()
	check(not game.ui.ending_review.visible and game.ui.ending_review_toggle.text == "回顧證據與評語", "review toggle closes again")
	game.ui.ending_review_toggle.pressed.emit()
	game._show_ending()
	check(not game.ui.ending_review.visible, "reopening the ending resets an open review")
	# A later quality correction cannot erase an earlier result-driven change.
	game.ui.ending_panel.hide()
	game.phase = game.Phase.NIGHT
	game.sim = Sim.new(1919)
	game.sim.plates = [
		{"number": 1, "start": 10.0, "duration": 8.0, "sunlit": false, "included": true, "usable": true, "stars": 7, "quality": "good", "trail": 0.1, "value": 1.75, "sigma": 0.2},
		{"number": 2, "start": 20.0, "duration": 20.0, "sunlit": false, "included": true, "usable": true, "stars": 5, "quality": "poor", "trail": 0.5, "value": 0.9, "sigma": 0.4},
		{"number": 3, "start": 45.0, "duration": 8.0, "sunlit": false, "included": false, "usable": true, "stars": 7, "quality": "good", "trail": 0.1, "value": 1.8, "sigma": 0.2},
	]
	game.plate_textures = [null, null, null]
	game._open_viewer()
	game.ui.measure_btn.pressed.emit()
	var original: Dictionary = game.sim.first_result.duplicate()
	game.ui.reselect_btn.pressed.emit()
	game.ui._select_plate(2, null)
	game.ui.include_box.button_pressed = true
	game.ui.measure_btn.pressed.emit()
	game.ui._choice_buttons[1].pressed.emit()
	check(game.sim.reselect_reason == "result" and not game.sim.selection_report().reselect_justified, "result answer records an unjustified change")
	game.ui.reselect_btn.pressed.emit()
	game.ui._select_plate(1, null)
	game.ui.include_box.button_pressed = false
	game.ui.measure_btn.pressed.emit()
	game.ui._choice_buttons[0].pressed.emit()
	check(not Judgment.grade(game.sim, "hopeful", "measured").clean, "later quality correction cannot clear an earlier result-driven change")
	check(Judgment.grade(game.sim, "hopeful", "measured").lines.has("你寫下的是：第一次的數字不合預期。誠實——但這正是不能改的理由。第一次的結果還在本子上。"), "earlier result admission wins over a later quality reason in judgment text")
	check(game.sim.reselect_history == [{"reason": "result", "added": [3], "removed": []}, {"reason": "quality", "added": [], "removed": [2]}], "both reselection reasons and plate changes survive")
	check(game.sim.first_result == original, "multiple reselections still retain the first result")
	game.sim = Sim.new(1919)
	# The ending is built from the recorded run (conversion arc D1): record this sim fresh.
	root.get_node("Story").runs.clear()
	game._run_record_index = -1
	game._show_ending()
	check(game.ui.ending_text.text.contains("本子上：沒有量出任何數值。"), "unmeasured ending keeps the empty workbook on the tableau")
	game.sim.first_result = {"n": 0}
	game.sim.reselected_after_seeing = true
	root.get_node("Story").runs.clear()
	game._run_record_index = -1
	game._show_ending()
	check(game.ui.ending_text.text.contains("本子上：沒有量出任何數值。（第一次量：沒有量出任何數值。）"), "unmeasured first result stays on the same workbook line")
	game.stop_all_audio()
	game.queue_free()
	await process_frame
