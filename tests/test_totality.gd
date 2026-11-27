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


## Conversion arc C: a fixture plate counts only once it has a micrometer
## reading. Put the crosshair at the plate's true displacement; the setting error
## (SET_SIGMA) then widens the plate's combined uncertainty for real.
func _read_plate(sim, p: Dictionary) -> void:
	p.read = true
	p.reading = sim.reading_for_value(float(p.get("value", 0.0)))


func _read_included(sim) -> void:
	for p in sim.plates:
		if p.get("included", false) and p.get("usable", false):
			_read_plate(sim, p)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if "--rehearsal" in OS.get_cmdline_user_args():
		await _test_rehearsal()
		await _test_rehearsal_carry()
		await _test_empty_rack_wait()
	else:
		await _run_all()
	# AudioServer releases stopped WAV playbacks asynchronously, after node teardown.
	await create_timer(0.1).timeout
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)


func _run_all() -> void:
	_test_bands()
	_test_strip_model()
	await _test_sim_invariance()
	await _test_totality_pacing()
	await _test_rehearsal()
	await _test_rehearsal_carry()
	await _test_aim_aspects()
	await _test_ready_status()
	await _test_empty_rack_wait()
	await _test_shutter_read()
	await _test_sfx_buffers()
	await _test_viewer_note()
	_test_interval_truth()
	_test_verdict_truth()
	_test_verdict_class()
	_test_judgment_neither()
	_test_judgment_prompt()
	await _test_judgment_reasons()
	await _test_chart_ledger()
	await _test_strict_poor_only()
	await _test_report_rule_layout()
	await _test_birds_quiet()
	await _test_callouts()
	await _test_night_viewer()
	await _test_reselect_reason()


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

func _test_totality_pacing() -> void:
	var normal
	for slower in [false, true]:
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game.sim = Sim.new(77)
		game.sim.drive_wound = true
		game.sim.drive_rate_checked = true
		game.sim.drive_error = 0.0
		game._start_game()
		Settings.slower_totality = slower
		var rate := 1.25 if slower else 2.5
		await game._begin_totality()
		check(game.ui.totality_pace_button.disabled, "pacing locks at second contact")
		var shutter := InputEventAction.new()
		shutter.action = "shutter"
		await _rehearsal_press(shutter)
		check(game.sim.is_exposing(), "the player opens the shutter in either mode")
		for logged in [false, true]:
			if logged:
				game.ui.toggle_log()
			else:
				game.ui.toggle_pause()
			game._process_totality(1.0)
			check(game.t_game == 0.0 and game.sim._open.duration == 0.0,
				"pause and dialogue log each freeze the totality clock and exposure")
			if logged:
				game.ui.toggle_log()
			else:
				game.ui.toggle_pause()
		game._process_totality(1.0)
		check(game.t_game == rate and game.sim._open.duration == rate,
			"one unpaused real second advances the clock and exposure by %s" % rate)
		check(game.sky_mat.get_shader_parameter("cloud_time") == rate
			and game.ui.tot_strip.model.t == rate, "rendered cloud and HUD use the totality clock")
		var look := InputEventMouseMotion.new()
		look.relative = Vector2(20, 0)
		var yaw: float = game.player.yaw
		game.player._unhandled_input(look)
		check(is_equal_approx(game.player.yaw, yaw - 20.0 * game.player.MOUSE_SENS * Settings.look_speed),
			"identical mouse motion turns the same amount at both rates")
		game._process_totality((5.0 - rate) / rate)
		await _rehearsal_press(shutter)
		check(not game.sim.is_exposing() and game.change_left == Sim.PLATE_CHANGE_S,
			"the player stops the exposure and starts a plate change")
		game._process_totality(1.0)
		check(game.change_left == Sim.PLATE_CHANGE_S - rate, "plate change uses the totality clock")
		var start := ceilf((game.sim.gaps[2].t + 2.0) / GAME_STEP) * GAME_STEP
		game._process_totality((start - game.t_game) / rate)
		await _rehearsal_press(shutter)
		for frame in roundi(8.0 / (STEP * rate)):
			game._process_totality(STEP)
		await _rehearsal_press(shutter)
		game._process_totality((283.0 - game.t_game) / rate)
		check(not game._warned_end, "warning has not fired with 19 game seconds remaining")
		game._process_totality(2.0 / rate)
		check(game._warned_end, "warning has fired with 17 game seconds remaining")
		await _rehearsal_press(shutter)
		game._process_totality(20.0 / rate)
		check(game.tot_done and game.t_game == Sim.TOTALITY_S and game.sim.plates.back().sunlit
			and is_equal_approx(game.sim.plates.back().duration, 17.0),
			"third contact clamps overshoot to 302, including exposure time")
		for plate in game.sim.plates:
			plate.included = plate.quality == "good"
		_read_included(game.sim)
		check(game.sim.included_usable().map(func(p): return p.number) == [2],
			"matching quality-based selection includes the usable late-gap plate")
		if slower:
			check(game.sim.plates.size() == normal.plates.size(), "both modes develop the same plate count")
			for i in normal.plates.size():
				var expected: Dictionary = normal.plates[i]
				var actual: Dictionary = game.sim.plates[i]
				for key in expected:
					check(absf(actual[key] - expected[key]) <= 1e-6 if expected[key] is float
						else actual[key] == expected[key], "plate %d %s matches across pacing modes" % [i + 1, key])
			check(game.sim.selection_report() == normal.selection_report()
				and Judgment.grade(game.sim, "hopeful", "measured") == Judgment.grade(normal, "hopeful", "measured"),
				"selection and grade match across pacing modes")
		else:
			normal = game.sim
		game.stop_all_audio()
		game.queue_free()
		await process_frame
	Settings.slower_totality = false


func _rehearsal_press(event) -> void:
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _test_rehearsal_carry() -> void:
	var space := InputEventKey.new()
	space.physical_keycode = KEY_SPACE
	var shoulder := InputEventJoypadButton.new()
	shoulder.button_index = JOY_BUTTON_RIGHT_SHOULDER
	for shutter in [space, shoulder]:
		var game: Node = load("res://scenes/main.tscn").instantiate()
		root.add_child(game)
		game.set_process(false)
		game.sim = Sim.new(77)
		game._start_game()
		game._interact("eddington")
		while game.ui.dialog_active():
			if game.ui._choice_buttons.is_empty():
				game.ui._advance()
			else:
				game.ui._choose(0)
		var inventory: int = game.sim.plates_available()
		var evidence: Dictionary = game.sim.selection_report()
		game._interact("eddington")
		game.ui._advance()
		game.ui._choose(2)
		game._process_prep(4.0)
		await _rehearsal_press(shutter)
		var hint: String = game.ui.tot_hint.text
		check(Prompts.joypad == (shutter is InputEventJoypadButton), "shutter hint follows the input device")
		game._process_prep(1.0)
		var practice_status: String = game.ui.tot_label.text
		check(game._rehearsal_step == 1 and game.ui.tot_panel.visible and game.ui.tot_hint.visible,
			"rehearsal opening shows the shutter HUD immediately")
		await _rehearsal_press(shutter)
		var practice_change: String = game.ui.tot_label.text
		check(game._rehearsal_step == 2 and not game.ui.tot_hint.visible,
			"rehearsal close withdraws the shutter action during the change")
		check(game.ui.toast.text.contains("我看見雲邊經過太陽"),
			"rehearsal close reports the band sampled during the completed exposure")
		await create_timer(Sim.PLATE_CHANGE_S / Sim.TIME_SCALE + 0.1).timeout
		check(not game.rehearsing and not game.ui.tot_panel.visible,
			"practice HUD is dismissed when control returns to PREP")
		check(game.sim.plates.is_empty() and game.sim.plates_available() == inventory
			and game.sim.selection_report() == evidence and game.plate_textures.is_empty(),
			"rehearsal creates no live plate or measured evidence")
		game._interact("eddington")
		game.ui._advance()
		game.ui._choose(0)
		await create_timer(2.2).timeout
		check(game.ui.tot_hint.visible and game.ui.tot_hint.text == hint, "live entry offers the rehearsed control")
		await _rehearsal_press(shutter)
		game._process_totality(1.0)
		check(game.sim.is_exposing() and not practice_status.is_empty()
			and game.ui.tot_label.text.ends_with(practice_status), "live exposure shows the rehearsed status at the same elapsed time")
		await _rehearsal_press(shutter)
		check(game.sim.plates.size() == 1 and game.plates_left == inventory - 1,
			"the first live close develops exactly one plate")
		check(not game.ui.tot_hint.visible and not practice_change.is_empty()
			and game.ui.tot_label.text.ends_with(practice_change), "live close immediately shows the rehearsed change state")
		var plate: Dictionary = game.sim.plates[0]
		check(plate.sky_read == Cues.sky_band(plate.clear, plate.duration)
			and game.ui.toast.text.contains(Content.totality_read(plate.sky_read)), "live close reports the actual live exposure band")
		game._process_totality(Sim.PLATE_CHANGE_S / Sim.TIME_SCALE)
		check(game.ui.tot_hint.visible and game.ui.tot_hint.text == hint, "live change completion restores the shutter action")
		game.stop_all_audio()
		game.queue_free()
		await process_frame
	Prompts.joypad = false


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
	var old_size := root.size
	var old_scale_size := root.content_scale_size
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
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
	var cases := ["early", "brief", "late", "never", "never stop", "long unprepared", "long prepared"]
	var expected := ["你在雲變薄前就開了，厚雲也算進曝光。", "你在雲薄時開始、變厚前停。", "你停得晚，雲回來後還在曝光。", "窗口過去了，你沒有開：這次練習沒有曝光。", "你一直沒喊停，練習替你收了遮光板；真的全食要自己喊停。", "你在雲薄時開始、變厚前停。", "你在雲薄時開始、變厚前停。"]
	var qualities := ["unusable", "unusable", "poor", "", "poor", "poor", "good"]
	var shutter := InputEventAction.new()
	shutter.action = "shutter"
	game.player.global_position = Vector3(0, 0.05, 0)
	game.player.yaw = 0.4
	game.player.pitch = -0.2
	await physics_frame
	check(_visible_sun_obstruction(game) != "", "visible shelter blocks the Sun before rehearsal")
	for i in cases.size():
		game.sim.drive_wound = i == 6
		game.sim.drive_rate_checked = i == 6
		game.sim.drive_error = 0.0 if i == 6 else 1.0
		game._interact("eddington")
		game.ui._advance()
		check(game.ui._choice_buttons.size() == 4, "PREP offers rehearsal and keeps dismiss last")
		game.ui._choose(2)
		check(game.rehearsing and not game.player.can_move and game.player.can_look, "rehearsal freezes movement and retains look")
		check(not game.world.eddington.visible and not game.world.cottingham.visible, "rehearsal hides both characters")
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
		if i in [1, 2, 4, 5, 6]:
			await _rehearsal_press(shutter)
		if i == 1:
			var raw_before: Dictionary = game._rehearsal_exposure.duplicate(true)
			paused = true
			game._process_prep(1.0)
			await _rehearsal_press(shutter)
			check(game._rehearsal_time == 4.0 and game._rehearsal_exposure == raw_before and game._rehearsal_step == 1, "pause freezes practice time, exposure and shutter input")
			paused = false
			game._process_prep(0.1)
			check(is_equal_approx(game._rehearsal_exposure.duration, 0.25) and is_equal_approx(game._rehearsal_exposure.clear, 0.22) and is_equal_approx(game._rehearsal_exposure.cloudy, 0.03), "brief practice accumulates displayed cloud at the live time compression")
		if i == 5 or i == 6:
			game._process_prep(4.0)
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
		if i != 3:
			var developed: Dictionary = game.sim.develop(game._rehearsal_exposure, 0)
			check(developed.quality == qualities[i], "%s has the expected development quality" % cases[i])
			check(game.ui.toast.text.contains(Content.rehearsal_feedback("inside", developed.quality).trim_prefix("你在雲薄時開始、變厚前停。")), "%s quality feedback follows accumulated practice development" % cases[i])
			check(not game.ui.toast.text.contains(str(developed.value)) and not game.ui.viewer.visible, "practice exposes no generated deflection or plate viewer")
		if i == 1:
			check(game.ui.toast.text.contains("不足以留下可量測的星點") and not game.ui.toast.text.contains("較清楚"), "4.0–4.1 s practice never promises a usable or clear plate")

		check(game.ui.toast.text.contains("這一小會兒"), "rehearsal describes the brief real-time change without a game-clock number")
		check(game._rehearsal_step == 2 and game.prep_left == prep_before, "change wait freezes preparation")
		if i == 4:
			await _rehearsal_press(shutter)
			check(game.ui.toast.text == "Eddington 還在換片……", "press during automatic change reports the wait")
		if i == 1:
			paused = true
			await create_timer(1.8, true).timeout
			check(game.rehearsing, "pause freezes the practice plate-change wait")
			paused = false
		var change_seconds := Sim.PLATE_CHANGE_S / Sim.TIME_SCALE
		await create_timer(change_seconds * 0.5).timeout
		check(game.rehearsing, "rehearsal keeps input locked midway through the real change rhythm")
		await create_timer(change_seconds * 0.5 + 0.15).timeout
		check(not game.rehearsing and game.player.can_move, "rehearsal change restores input at the real totality rhythm")
		# Let the old four-second timer finish on revert runs so later cases stay independent.
		if game.rehearsing:
			await create_timer(Sim.PLATE_CHANGE_S).timeout
		check(game.world.eddington.visible and game.world.cottingham.visible, "rehearsal restores both characters")
		check(game.world.roof.visible and is_equal_approx(game.player.yaw, 0.4) and is_equal_approx(game.player.pitch, -0.2), "rehearsal restores roof and camera")
		check(is_equal_approx(game.player.global_position.z, 0.0), "rehearsal returns the player to the original position")
		check(game.sky_mat.get_shader_parameter("practice_cloud") == -1.0, "rehearsal restores the sky shader")
		check(game.sim.plates == plates_before and game.sim.gaps == gaps_before and game.sim.run_seed == seed_before and game.sim.plates_available() == available_before, "rehearsal preserves simulation and inventory")
		check(game.sim.drive_wound == (i == 6) and game.sim.drive_rate_checked == (i == 6), "practice preserves drive preparation")
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
	check(not game.world.eddington.visible and not game.world.cottingham.visible, "totality hides both characters")
	await physics_frame
	await process_frame
	var sun_screen: Vector2 = game.player.camera.unproject_position(game.player.camera.global_position + game.sim.sun_dir * 100.0)
	var sun_target := Vector2(594, 106) if game._style != null else Vector2(853, 240)
	check(sun_screen.distance_to(sun_target) < 40.0, "totality dialogue frames the Sun at the authored position: %s" % sun_screen)
	check(game.ui.prompt_label.text == "［%s］開始／停" % Prompts.key("shutter"), "totality retains a compact shutter reminder")
	game.ui._process(7.1)
	game._process_totality(0.1)
	check(game.ui.prompt_label.text == "［%s］開始／停" % Prompts.key("shutter"), "shutter reminder survives the seven-second toast")
	game._end_totality()
	game._process_totality(0.1)
	check(game.tot_done and game.ui.prompt_label.text == "", "third contact clears the reminder without restoring it")
	game._begin_night()
	await create_timer(1.4).timeout
	check(game.phase == game.Phase.NIGHT and game.world.eddington.visible and game.world.cottingham.visible, "night restores both characters")
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	Prompts.joypad = false
	root.size = old_size
	root.content_scale_size = old_scale_size


func _test_aim_aspects() -> void:
	var old_size := root.size
	var old_scale_size := root.content_scale_size
	for size in [Vector2i(1280, 720), Vector2i(1280, 800), Vector2i(3840, 1080), Vector2i(7680, 1080)]:
		root.size = size
		root.content_scale_size = size
		for rehearsal in [true, false]:
			var game: Node = load("res://scenes/main.tscn").instantiate()
			root.add_child(game)
			game.set_process(false)
			game._start_game()
			if rehearsal:
				game._begin_rehearsal()
			else:
				await game._begin_totality()
			await physics_frame
			await process_frame
			var label := "%s %s" % [size, "rehearsal" if rehearsal else "totality"]
			check(is_finite(game.player.yaw) and is_finite(game.player.pitch), label + " has finite aim")
			var camera: Camera3D = game.player.camera
			var sun: Vector3 = camera.global_position + game.sim.sun_dir * 100.0
			var screen := camera.unproject_position(sun)
			check(not camera.is_position_behind(sun) and Rect2(Vector2.ZERO, Vector2(size)).has_point(screen), label + " keeps Sun on screen")
			if rehearsal or game._style == null:
				var half_height := tan(deg_to_rad(camera.fov) / 2.0)
				var y := half_height / 3.0
				var sun_y: float = game.sim.sun_dir.y
				# At this vertical third, solar altitude bounds the horizontal slope.
				var max_x := sqrt((1.0 + y * y) * (1.0 - sun_y * sun_y)) / sun_y
				var target := Vector2(minf(size.x * 2.0 / 3.0, size.x / 2.0 + size.y * max_x / (2.0 * half_height)), size.y / 3.0)
				check(screen.distance_to(target) < 1.0, label + " reaches the closest upper-right third: %s" % screen)
			else:
				var sun_dir: Vector3 = game.sim.sun_dir
				var tangent := sun_dir.cross(Vector3.UP).normalized()
				# The farthest engraved streamer reaches four solar radii.
				var radius: float = 4.0 * game.sim.SUN_R
				var envelope_visible := true
				for i in 16:
					var edge := sun_dir * sqrt(1.0 - radius * radius) + tangent.rotated(sun_dir, i * TAU / 16.0) * radius
					envelope_visible = envelope_visible and camera.is_position_in_frustum(camera.global_position + edge * 100.0)
				check(envelope_visible, label + " keeps the corona envelope on screen")
			game.stop_all_audio()
			game.queue_free()
			await process_frame
	root.size = old_size
	root.content_scale_size = old_scale_size


func _test_ready_status() -> void:
	var states := [
		[true, true, 0, "可用底片 6 張。時鐘驅動：上了發條並校過走速。", 6],
		[true, false, 0, "可用底片 6 張。時鐘驅動：上了發條但走速尚未驗證。", 6],
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
		game.sim.drive_error = 0.0 if state[1] else 1.0
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
			if game._pending == "after_totality" and game.ui.dialog_active():
				game.ui._advance()
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
		var wav: AudioStreamWAV
		if name in ["insects", "surf", "birds"] and game._bed_sampled(name):
			check(sound.stream is AudioStreamOggVorbis, "%s uses the sampled OGG" % name)
			if sound.stream is AudioStreamOggVorbis:
				check(sound.stream.loop, "%s OGG loops" % name)
				var shipped_peak := ogg_peak(sound.stream, name)
				check(shipped_peak <= 0.9, "%s shipped OGG peak <= 0.9 (%.3f)" % [name, shipped_peak])
			wav = game._wav(game._sfx_samples[name], 22050, true)
		else:
			check(sound.stream is AudioStreamWAV, "%s is a synthesized WAV" % name)
			if not sound.stream is AudioStreamWAV:
				continue
			wav = sound.stream
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

func ogg_peak(stream: AudioStream, label: String) -> float:
	# Decode a non-looping copy past the advertised end: a looping bed would
	# otherwise refill from the start and hide a recording that ends early.
	var source: AudioStream = stream.duplicate()
	if "loop" in source:
		source.loop = false
	var pb := source.instantiate_playback()
	pb.start(0.0)
	var rate := AudioServer.get_mix_rate()
	var remaining := int(ceil((stream.get_length() + 0.5) * rate))
	var decoded := 0
	var peak := 0.0
	while remaining > 0:
		var block: PackedVector2Array = pb.mix_audio(1.0, mini(4096, remaining))
		for frame in block:
			peak = maxf(peak, maxf(absf(frame.x), absf(frame.y)))
		decoded += block.size()
		remaining -= block.size()
		if block.size() < mini(4096, remaining + block.size()):
			break
	check(decoded / float(rate) >= stream.get_length() - 0.05, "%s decoded %.2f of %.2f s" % [label, decoded / float(rate), stream.get_length()])
	check(decoded / float(rate) <= stream.get_length() + 0.05, "%s decode stops at the end, not looping (%.2f of %.2f s)" % [label, decoded / float(rate), stream.get_length()])
	return peak


func _test_interval_truth() -> void:
	var sim := Sim.new(1919)
	check(Judgment.interval_truth(sim) == -1, "no measured plates means no verdict")
	check(not Judgment.interval_holds_neither(sim), "no measurements is not a neither-contained interval")
	# Exact classification wins; adjust rounded bounds only when they would change it.
	# Fixture σ is the plate error; with conversion arc C the displayed interval
	# adds the reading's setting error (SET_SIGMA) in quadrature.
	for case in [[1.3, 0.3, 0, "0.68", "1.92"], [1.75, 0.1, 1, "1.49", "2.01"], [0.87, 0.1, 2, "0.61", "1.13"],
		[3.0, 0.1, 3, "2.74", "3.26"], [2.25, 0.25, 1, "1.73", "2.77"], [1.25, 0.25, 0, "0.73", "1.77"],
		[1.5496, 0.1, 1, "1.29", "1.81"], [1.9504, 0.1, 1, "1.69", "2.21"], [0.6696, 0.1, 2, "0.41", "0.93"], [1.0704, 0.1, 2, "0.81", "1.33"],
		[1.5504, 0.1, 1, "1.29", "1.81"], [1.9496, 0.1, 1, "1.69", "2.21"], [0.6704, 0.1, 2, "0.41", "0.93"], [1.0696, 0.1, 2, "0.81", "1.33"]]:
		sim.plates = [{"usable": true, "included": true, "value": case[0], "sigma": case[1]}]
		_read_plate(sim, sim.plates[0])
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


class VerdictFixture extends RefCounted:
	const HALF := 0.87
	const EINSTEIN := 1.75
	var result: Dictionary
	func combined() -> Dictionary:
		return result


func _test_verdict_truth() -> void:
	var sim := VerdictFixture.new()
	for case in [[0.0, 0.1, 0], [0.87, 0.1, 1], [1.75, 0.1, 2],
		[1.3, 0.3, 3], [0.4, 0.25, 3], [3.0, 0.1, 3]]:
		sim.result = {"n": 1, "value": case[0], "sigma": case[1]}
		check(Judgment.verdict_truth(sim) == case[2], "verdict for %.2f ± %.2f is %d" % case)
		var bounds := Judgment.interval_bounds(sim)
		for prediction in [0.0, sim.HALF, sim.EINSTEIN]:
			check((bounds.lo <= prediction and prediction <= bounds.hi) == (absf(case[0] - prediction) / case[1] <= 2.0),
				"displayed verdict bounds agree with containment at %s" % prediction)
	for i in 3:
		var prediction: float = [0.0, sim.HALF, sim.EINSTEIN][i]
		for direction in [-1, 1]:
			var value: float = prediction + direction * 0.25
			# Derive σ from the exact floating-point distance: the endpoint is 2σ.
			sim.result = {"n": 1, "value": value, "sigma": absf(value - prediction) / 2.0}
			check(Judgment.verdict_truth(sim) == i, "prediction %s at endpoint %d is contained" % [prediction, direction])
	for case in [[0.20, true, -0.10], [0.301, false, 0.01]]:
		sim.result = {"n": 1, "value": case[0], "sigma": 0.15}
		var bounds := Judgment.interval_bounds(sim)
		check((absf(case[0]) / 0.15 <= 2.0) == case[1], "zero containment at %.3f ± 0.15" % case[0])
		check(is_equal_approx(bounds.lo, case[2]) and ((bounds.lo <= 0.0) == case[1]), "rounded lower bound preserves zero containment")
	sim.result = {"n": 0, "value": 0.0, "sigma": 0.0}
	check(Judgment.verdict_truth(sim) == 3, "no measurements is inconclusive")


func _test_verdict_class() -> void:
	var table := [
		["consistent", "overclaim", "overclaim", "overclaim"],
		["overclaim", "consistent", "overclaim", "overclaim"],
		["overclaim", "overclaim", "consistent", "overclaim"],
		["underclaim", "underclaim", "underclaim", "consistent"],
	]
	for verdict in 4:
		for truth in 4:
			check(Judgment.verdict_class(verdict, truth) == table[verdict][truth], "verdict class %d/%d" % [verdict, truth])


func _test_judgment_neither() -> void:
	var sim := Sim.new(1919)
	# 2.30 ± 0.19 (measured) keeps both predictions outside two sigma after the
	# setting error widens the interval.
	sim.plates = [{"number": 1, "usable": true, "quality": "good", "included": true, "trail": 0.1, "value": 2.30, "sigma": 0.17}]
	_read_plate(sim, sim.plates[0])
	var neither := Judgment.grade(sim, "undecided", "uncertain")
	check(neither.evidence == "ambiguous" and Judgment.interval_holds_neither(sim), "2.30 ± 0.19 is ambiguous with neither prediction contained")
	check(neither.lines.any(func(line): return line.contains("都對不上")) and not neither.lines.any(func(line): return line.contains("同時容得下")), "neither-contained undecided response does not claim both fit")
	var hopeful_neither := Judgment.grade(sim, "hopeful", "uncertain")
	check(hopeful_neither.lines.has("「有希望」可以接受，但它是個寬鬆的詞。我們的數字離兩種預測都還有一段距離——片子少，也可能是儀器。"), "neither-contained hopeful response names the distance from both predictions")
	sim.plates[0].value = 1.3
	sim.plates[0].sigma = 0.3
	_read_plate(sim, sim.plates[0])
	var both := Judgment.grade(sim, "undecided", "uncertain")
	check(both.evidence == "ambiguous" and Judgment.interval_truth(sim) == 0, "both-contained interval is also ambiguous")
	check(both.lines.has("對。誤差範圍同時容得下兩種答案。我們照實說。"), "both-contained undecided response keeps its original line")
	var hopeful_both := Judgment.grade(sim, "hopeful", "uncertain")
	check(hopeful_both.lines.has("「有希望」可以接受，但它是個寬鬆的詞。我們的數字其實還在兩種預測之間搖擺。"), "both-contained hopeful response keeps its original line")
	check(both.score == neither.score and hopeful_both.score == hopeful_neither.score, "distinguishing neither from both leaves scores unchanged")
	# Keep the same selection and reason, changing only the measured interval.
	sim.plates[0].value = 0.0
	sim.plates[0].sigma = sqrt(0.13 * 0.13 - Sim.SET_SIGMA * Sim.SET_SIGMA)
	_read_plate(sim, sim.plates[0])
	var combined: Dictionary = sim.combined()
	check(is_equal_approx(combined.value, 0.0) and is_equal_approx(combined.sigma, 0.13), "zero-only fixture is 0.00 ± 0.13")
	check(Judgment.verdict_truth(sim) == 0, "zero-only fixture supports zero")
	var zero_undecided := Judgment.grade(sim, "undecided", "uncertain")
	var zero_hopeful := Judgment.grade(sim, "hopeful", "uncertain")
	check(zero_undecided.evidence == "ambiguous" and zero_hopeful.evidence == "ambiguous", "zero-only interval retains ambiguous evidence")
	check(zero_undecided.score == neither.score and zero_hopeful.score == hopeful_neither.score, "zero-only interval retains telegram scores")
	check(zero_undecided.presentation.any(func(line): return line.contains("對。數字只容得下不偏折，兩種預測都被排除了；在弄清楚是光還是儀器之前，什麼也不能說。我們照實說。")), "undecided presentation names zero-only containment")
	check(zero_hopeful.presentation.any(func(line): return line.contains("「有希望」是個寬鬆的詞。我們的數字只容得下不偏折，兩種預測都被排除了——在相信它之前，先查儀器。")), "hopeful presentation names zero-only containment")
	for grade in [zero_undecided, zero_hopeful]:
		check(not grade.presentation.any(func(line): return line.contains("對不上") or line.contains("距離")), "zero-only presentation omits neither-contained wording")



func _test_judgment_prompt() -> void:
	var tele := ["telegram"]
	var reasons := ["reason"]
	var plain := Content.judgment_prompt(tele, reasons)
	check(plain.map(func(line): return line.key) == ["telegram", "reason"], "judgment contains only telegram and reason")
	var interval := "1.75″ ± 0.10″，兩倍誤差是 1.55″ 到 1.95″"
	var prompt := Content.verdict_prompt(interval)
	check(prompt.map(func(line): return line.key) == ["verdict"], "verdict is its own dialogue")
	check(prompt[0].s == Content.E and prompt[0].t == "先看你的數字：%s。粗線是你的數字加減一個誤差，細線是兩倍誤差。你自己判斷——你的底片支持哪一個？" % interval, "Eddington neutrally asks for the player's verdict")
	check(prompt[0].choices == ["支持 0（光不偏折）", "支持 0.87″", "支持 1.75″", "尚無定論"], "verdict choices use prediction index order")


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
	_read_included(game.sim)
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
	check(not game.ui.dialog_panel.get_global_rect().intersects(game.ui.chart.get_global_rect()), "verdict choices leave the chart visible")
	check(root.gui_get_focus_owner() == game.ui._choice_buttons[0], "report puts focus on the verdict choices")
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
	check(game.ui._seq[0].key == "verdict" and game.ui._seq[0].t.contains("%.2f″ ± %.2f″，兩倍誤差是 %.2f″ 到 %.2f″" % [c.value, c.sigma, c.value - 2*c.sigma, c.value + 2*c.sigma]), "real judgment opens with the combined 2σ interval")
	check(game.ui._seq.size() == 1 and game.ui._choice_buttons.size() == 4, "only verdict choices exist before the answer")
	var evidence_before: Dictionary = game.sim.combined().duplicate(true)
	game.ui._choose(0) # Wrong: this interval contains only 1.75″.
	game._process(0.0)
	game._process(1.5)
	check(game._verdict == 0, "real verdict dialogue stores the answer")
	var at_telegram: bool = game._pending == "judgment" and game.ui._seq[game.ui._seq_i].get("key") == "telegram" \
		and game.ui._choice_buttons.size() == Judgment.TELEGRAMS.size()
	check(at_telegram, "wrong verdict reaches telegram choices after the chart hold")
	check(game._grade.is_empty() and game.sim.combined() == evidence_before, "the verdict leaves evidence and grading untouched")
	# Stop this flow on a regression so later choices do not target the wrong entry.
	if not at_telegram:
		game.stop_all_audio()
		game.queue_free()
		await process_frame
		return
	check(game.ui.viewer.visible and game.ui._viewer_locked and root.gui_get_focus_owner() == game.ui._choice_buttons[0],
		"telegram choices keep the locked evidence visible and hold focus")
	game.ui._choose(1)
	check(game.ui._seq[game.ui._seq_i].get("key") == "reason", "telegram still leads to the reason")
	check(game.ui.viewer.visible and root.gui_get_focus_owner() == game.ui._choice_buttons[0], "reason choices keep evidence visible and hold focus")
	game.ui._choose(0)
	check(game._pending == "telegram_record" and game.ui._choice_buttons.is_empty() and not game.ui.viewer.visible,
		"committing the reason closes the viewer and opens the record")
	check(game._grade == Judgment.grade(game.sim, "hopeful", "measured"), "real dialogue grades the stored measured reason")
	var wrong_grade: Dictionary = game._grade.duplicate(true)
	game.ui._advance()
	check(game._pending == "reaction" and game.ui.text_label.text == Content.verdict_feedback(0, 2, bounds),
		"advancing the record starts review with the wrong verdict correction")
	var grading_reaction: Array = game.ui._seq.slice(1)
	game._start_judgment()
	game.ui._choose(Judgment.verdict_truth(game.sim))
	game._process(0.0)
	game._process(1.5)
	game.ui._choose(1)
	game.ui._choose(0)
	check(game._grade == wrong_grade and game._grade.score == wrong_grade.score, "right and wrong verdicts yield identical grading and score")
	game.ui._advance()
	check(game._pending == "reaction" and game.ui.text_label.text == Content.verdict_feedback(2, 2, bounds),
		"the correct verdict is acknowledged in review")
	check(game.ui._seq.slice(1) == grading_reaction, "the review after verdict feedback is the same for either verdict")
	var expected_classes := ["overclaim", "overclaim", "consistent", "underclaim"]
	for verdict in 4:
		game._start_judgment()
		check(game._pending == "verdict" and game.ui._seq[0].key == "verdict", "Report opens the verdict stage")
		check(game.ui._seq[0].t == "先看你的數字：%s。粗線是你的數字加減一個誤差，細線是兩倍誤差。你自己判斷——你的底片支持哪一個？" % ("%.2f″ ± %.2f″，兩倍誤差是 %.2f″ 到 %.2f″" % [c.value, c.sigma, bounds.lo, bounds.hi]), "real first choice contains no feedback")
		game.ui._choose(verdict)
		game._process(0.0)
		game._process(1.5)
		check(game._verdict == verdict and game._verdict_truth == 2 and game._verdict_class == expected_classes[verdict], "real results handler stores verdict and class %d" % verdict)
		check(game.ui._seq[game.ui._seq_i].get("key") == "telegram", "every verdict advances to the telegram")
		game.ui._choose(1)
		game.ui._choose(0)
		check(game._grade == wrong_grade, "verdict %d earns no telegram grading advantage" % verdict)
	var story := root.get_node("Story")
	var run_count: int = story.runs.size()
	game._record_run()
	check(story.runs.size() == run_count + 1 and story.runs[-1].verdict == 3 and story.runs[-1].verdict_class == "underclaim", "real run snapshot includes verdict and verdict_class")
	story.runs.pop_back()

	game.sim.plates = [{"number": 1, "usable": true, "quality": "good", "included": true, "trail": 0.1, "value": 1.5496, "sigma": 0.1}]
	_read_plate(game.sim, game.sim.plates[0])
	game._start_judgment()
	check(game.ui._seq[0].t.contains("兩倍誤差是 1.29″ 到 1.81″") and Judgment.interval_truth(game.sim) == 1 and game.sim.evidence_class() == "favors_e",
		"setting error widens the interval so 1.75 is inside it, in the prompt, answer, and evidence class")
	game.sim.measured = true
	game._refresh_viewer()
	check(game.ui.viewer_note.text.contains("1.29–1.81″"), "viewer note matches the judgment interval")
	game.sim.plates = []
	game._start_judgment()
	check(game.ui._seq.map(func(line): return line.key) == ["telegram", "reason"], "real judgment skips the verdict when nothing was measured")
	# The fifth reason through the real judgment path (no bot route reaches it).
	game.sim.drive_rate_checked = false
	game.sim.drive_error = 0.0 if false else 1.0
	game.sim.plates = [
		{"number": 1, "usable": true, "quality": "poor", "included": true, "trail": 0.6, "value": 0.87, "sigma": 0.2},
		{"number": 2, "usable": true, "quality": "poor", "included": true, "trail": 0.6, "value": 0.87, "sigma": 0.2},
	]
	_read_included(game.sim)
	game._start_judgment()
	game.ui._choose(Judgment.verdict_truth(game.sim))
	game._process(0.0)
	game._process(1.5)
	game.ui._choose(2)
	game.ui._choose(4)
	game.ui._advance()
	check(game._pending == "reaction" and game._grade.reason_ok and game._grade.lines.any(func(l): return l.contains("Cottingham 會記得")),
		"choosing the instrument reason in the real dialogue is graded and answered")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _test_chart_ledger() -> void:
	var chart := Chart.new()
	chart.size = Vector2(560, 420)
	root.add_child(chart)
	chart.set_data([], {}, true)
	for frame in 2:
		await process_frame
	check(chart.drawn().ledger.is_empty(), "October chart with no ledger paints no bets")
	chart.set_ledger([
		{"pick": 1, "kind": "original", "tag": "1917 年押的"},
		{"pick": 1, "kind": "current", "tag": "現在押的"},
	])
	for frame in 2:
		await process_frame
	check(chart.drawn().ledger == [{"pick": 1, "kind": "current", "shape": "filled"}]
		and chart.drawn_texts().has("押的（1917 年至今沒改）"), "chart merges matching ledger entries")
	chart.free()
	var story := root.get_node("Story")
	var saved_original: Dictionary = story.bet_1917.duplicate(true)
	var game := _make_game()
	game.sim.plates = [{"number": 1, "start": 10.0, "duration": 6.0, "sunlit": false,
		"usable": true, "quality": "good", "included": true,
		"trail": 0.1, "value": 1.8, "sigma": 0.2}]
	_read_included(game.sim)
	game.sim.measured = true
	game.plate_textures = [null]
	game.ui.hide_title()
	game._open_viewer()
	var cases := [
		[1, 2, [{"pick": 1, "kind": "original", "shape": "hollow"}, {"pick": 2, "kind": "current", "shape": "filled"}], ["1917 年押的", "現在押的"]],
		[2, 2, [{"pick": 2, "kind": "current", "shape": "filled"}], ["押的（1917 年至今沒改）"]],
		[-1, 2, [{"pick": 2, "kind": "current", "shape": "filled"}], ["1919 年押的"]],
		[3, 2, [{"pick": 3, "kind": "original", "shape": "text"}, {"pick": 2, "kind": "current", "shape": "filled"}], ["1917 年押的：說不準", "現在押的"]],
		[0, 3, [{"pick": 0, "kind": "original", "shape": "hollow"}, {"pick": 3, "kind": "current", "shape": "text"}], ["1917 年押的", "現在押的：說不準"]],
		[3, 3, [{"pick": 3, "kind": "current", "shape": "text"}], ["押的（1917 年至今沒改）：說不準"]],
		[-1, 3, [{"pick": 3, "kind": "current", "shape": "text"}], ["1919 年押的：說不準"]],
		[0, -1, [{"pick": 0, "kind": "original", "shape": "hollow"}], ["1917 年押的"]],
		[-1, -1, [], []],
	]
	for scenario in cases:
		story.bet_1917 = {"pick": scenario[0], "year": 1917} if scenario[0] >= 0 else {}
		game.sim.bet_pick = scenario[1]
		game._refresh_viewer()
		for frame in 2:
			await process_frame
		check(game.ui.chart.drawn().ledger == scenario[2], "real viewer paints ledger shapes for %s -> %s" % [scenario[0], scenario[1]])
		for tag in scenario[3]:
			check(game.ui.chart.drawn_texts().has(tag), "real viewer paints ledger tag: " + tag)
		if scenario[0] < 0:
			check(not game.ui.chart.drawn_texts().any(func(tag): return tag.contains("1917")), "Príncipe-only chart invents no 1917 commitment")
	story.bet_1917 = {"pick": 1, "year": 1917}
	game.sim.bet_pick = 2
	game.sim.measured = false
	game._refresh_viewer()
	for frame in 2:
		await process_frame
	check(game.ui.chart.drawn().ledger.is_empty() and game.ui.chart.drawn().ledger_bounds.is_empty(), "before Measure no ledger items are painted")
	check(not game.ui.chart.drawn_texts().has("1917 年押的") and not game.ui.chart.drawn_texts().has("現在押的"), "before Measure no ledger tags are painted")
	story.bet_1917 = saved_original
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
		game.sim.drive_error = 0.0 if true else 1.0
		game.sim.drive_wound = true
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
		_read_included(game.sim)
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
		_read_included(game.sim)
		game.ui.hide_title()
		game._open_viewer()
		for frame in 4:
			await process_frame
		var note_before: String = game.ui.viewer_note.text
		var chart_height_before: float = game.ui.chart_scroll.custom_minimum_size.y
		await _click_control(game.ui.report_btn)
		for stage in ["verdict", "telegram", "reason"]:
			for frame in 4:
				await process_frame
			var chart_rect: Rect2 = game.ui.chart_scroll.get_global_rect()
			var dialog_rect: Rect2 = game.ui.dialog_panel.get_global_rect()
			print("report layout scale=%s stage=%s chart=%s dialogue=%s" % [scale, stage, chart_rect, dialog_rect])
			check(root.get_visible_rect().encloses(chart_rect) and not dialog_rect.intersects(chart_rect),
				"scale %s %s leaves the chart viewport visible" % [scale, stage])
			var painted: Dictionary = game.ui.chart.drawn()
			var fixed: Array = painted.ledger_bounds.duplicate()
			fixed.append_array(painted.axis_bounds)
			fixed.append_array(painted.combined_bounds)
			fixed.append(painted.result_bounds)
			check(painted.axis_bounds.size() == 3 and painted.combined_bounds.size() == 2 and painted.result_bounds.has_area()
				and painted.row_bounds.size() == 12, "scale %s %s paints pinned content and all rows" % [scale, stage])
			for rect: Rect2 in fixed:
				check(chart_rect.grow(1).encloses(Rect2(game.ui.chart.global_position + rect.position, rect.size)),
					"scale %s %s keeps pinned content visible" % [scale, stage])
			var bar: VScrollBar = game.ui.chart_scroll.get_v_scroll_bar()
			check(bar.max_value - bar.page > 0, "scale %s %s makes rows scrollable" % [scale, stage])
			check(root.get_visible_rect().encloses(dialog_rect), "scale %s %s dialogue fits viewport" % [scale, stage])
			var rule_rect: Rect2 = game.ui.viewer_rule.get_global_rect()
			check(root.get_visible_rect().encloses(rule_rect) and not dialog_rect.intersects(rule_rect),
				"scale %s %s rule fits viewport and stays above dialogue" % [scale, stage])
			match stage:
				"verdict":
					check(game.ui._seq[game.ui._seq_i].get("key") == "verdict", "real report starts at verdict")
					await _click_control(game.ui._choice_buttons[Judgment.verdict_truth(game.sim)])
					game._process(0.0)
					game._process(1.5)
				"telegram":
					check(game.ui._seq[game.ui._seq_i].get("key") == "telegram", "real report reaches telegram")
					await _click_control(game.ui._choice_buttons[1])
				"reason":
					check(game.ui._seq[game.ui._seq_i].get("key") == "reason" and game.ui._choice_buttons.size() == 5,
						"real report reaches five reason choices")
		check(game.ui.thumbs.get_child_count() == 13, "report rule layout has twelve plates and a comparison thumbnail")
		check(game.ui.viewer_rule.is_visible_in_tree() and game.ui.viewer_rule.text == "你寫下的規則：" + Content.rules_prompt(false)[-1].choices[0], "report shows the complete authored rule")
		check(game.ui.viewer_note.text == note_before and not note_before.contains("你寫下的規則"), "report rule leaves the measurement note unchanged")
		game.ui.close_viewer()
		game._open_viewer()
		check(is_equal_approx(game.ui.chart_scroll.custom_minimum_size.y, chart_height_before), "reopening the viewer restores the measurement chart height")
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
	game.sim.drive_error = 0.0 if true else 1.0
	game.sim.drive_wound = true
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
	_read_plate(game.sim, game.sim.plates[0])
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
	_read_included(game.sim)
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
		and game.ui.ending_review.text.contains("· 你量了 1 張，合併 1.75″ ± 0.22″（示意模擬）。")
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
	_read_included(game.sim)
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
