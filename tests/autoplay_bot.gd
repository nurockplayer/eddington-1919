extends Node
## End-to-end autoplay: drives the real game through synthetic input events
## (keys for movement/interaction/dialogue, mouse clicks on the plate viewer),
## takes screenshots and writes a JSON result. It is an automated smoke play,
## NOT a human playtest.
##
## Run: godot --path . -- --autoplay=careful --shots=/tmp/shots [--seed=N] [--speed=2]
## Scenarios: careful | rushed | cherry

static var runs := 0
static var first_seed := -1

var main
var scenario := "careful"
var shots_dir := ""
var log_lines: Array[String] = []
var stuck := 0
var _phase_event := ""


func _ready() -> void:
	var args: Dictionary = main._user_args()
	Engine.time_scale = float(args.get("speed", "1"))
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
	_run.call_deferred()


func on_phase(p: String) -> void:
	_phase_event = p


func _log(s: String) -> void:
	log_lines.append(s)
	print("[BOT %s] %s" % [scenario, s])


# ------------------------------------------------------------------ primitives

func _wait(sec: float) -> void:
	await get_tree().create_timer(sec, true, false, true).timeout


func _frames(n := 2) -> void:
	for i in n:
		await get_tree().process_frame


func _key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _tap(code: Key) -> void:
	_key(code, true)
	await _frames(2)
	_key(code, false)
	await _frames(2)


func _hold(code: Key, sec: float) -> void:
	_key(code, true)
	await _wait(sec)
	_key(code, false)
	await _frames(2)


func _click(pos: Vector2) -> void:
	var mv := InputEventMouseMotion.new()
	mv.position = pos
	mv.global_position = pos
	Input.parse_input_event(mv)
	await _frames(2)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.position = pos
		ev.global_position = pos
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await _frames(2)


func shot(name: String) -> void:
	if shots_dir == "":
		return
	# Wait for a drawn frame, but never hang if the OS stops drawing a hidden window.
	var drawn := [false]
	RenderingServer.frame_post_draw.connect(func(): drawn[0] = true, CONNECT_ONE_SHOT)
	var guard := 90
	while not drawn[0] and guard > 0:
		guard -= 1
		await get_tree().process_frame
	if not drawn[0]:
		_log("shot %s skipped (window not drawing)" % name)
		return
	var img := get_viewport().get_texture().get_image()
	img.save_png(shots_dir.path_join("%s_%s.png" % [scenario, name]))
	_log("shot " + name)


## Walk through waypoints using the real movement action.
func walk(points: Array) -> void:
	var p = main.player
	for target in points:
		var t2 := Vector2(target.x, target.z)
		var timeout := 12.0
		while timeout > 0.0:
			var here := Vector2(p.global_position.x, p.global_position.z)
			var d := here.distance_to(t2)
			if d < 0.35:
				break
			var to: Vector2 = t2 - here
			p.yaw = atan2(-to.x, -to.y)
			p.pitch = -0.1
			Input.action_press("move_forward")
			await _frames(1)
			timeout -= get_process_delta_time()
		Input.action_release("move_forward")
		if timeout <= 0.0:
			stuck += 1
			_log("STUCK near %s heading to %s — teleporting" % [p.global_position, target])
			p.global_position = Vector3(target.x, 0.05, target.z)
		await _frames(3)


func look(target: Vector3) -> void:
	main.player.look_at_point(target)
	await _frames(3)


## Aim and press E; returns the id under the crosshair.
func interact(target: Vector3) -> String:
	await look(target)
	var n = main.player.aimed_interactable()
	var id: String = n.get_meta("interact_id") if n else ""
	await _tap(KEY_E)
	return id


## Advance dialogue; `choices` are the option indices to pick, in order.
func talk(choices: Array = []) -> void:
	var guard := 60
	var ci := 0
	await _frames(3)
	while main.ui.dialog_active() and guard > 0:
		guard -= 1
		var e: Dictionary = main.ui._seq[main.ui._seq_i]
		if e.has("choices"):
			var pick: int = choices[ci] if ci < choices.size() else 0
			ci += 1
			_log("choose %d: %s" % [pick, e.choices[pick]])
			await _tap(KEY_1 + pick)
		else:
			await _wait(0.15)
			await _tap(KEY_E)
		await _frames(2)


# -------------------------------------------------------------------- scenario

const START := Vector3(2.6, 0, 4.2)
const EDD_FRONT := Vector3(-1.1, 0, 0.4)
const EDD_HEAD := Vector3(-1.1, 1.6, -0.9)
const DOOR_OUT := Vector3(6.6, 0, 3.0)
const DOOR_IN := Vector3(8.7, 0, 3.0)
const BOX_SPOT := Vector3(10.7, 0, 2.3)
const STATION_SPOT := Vector3(0.35, 0, -0.75)
const RIGHT_FRONT := Vector3(1.75, 0, -0.9)
const RIGHT_BACK := Vector3(1.75, 0, -5.3)
const DRIVE_SPOT := Vector3(0.85, 0, -5.65)
const FRONT_LEFT := Vector3(-1.75, 0, -0.1)
const TABLE_SPOT := Vector3(-1.8, 0, -2.45)


func _run() -> void:
	runs += 1
	if runs > 1:
		# We are inside a restarted scene: verify the restart and stop.
		_log("restart run %d: seed %d (first run seed %d) title_visible=%s" % [runs, main.sim.run_seed, first_seed, main.ui.title_panel.visible])
		await _wait(1.0)
		await shot("11_after_restart")
		var f := FileAccess.open(shots_dir.path_join("restart_%s.json" % scenario), FileAccess.WRITE)
		f.store_string(JSON.stringify({"first_seed": first_seed, "new_seed": main.sim.run_seed, "differs": main.sim.run_seed != first_seed, "title_visible": main.ui.title_panel.visible}))
		f.close()
		get_tree().quit()
		return
	first_seed = main.sim.run_seed
	_log("seed %d" % main.sim.run_seed)
	await _wait(1.0)
	await shot("00_title")
	await _click(main.ui.start_btn.get_global_rect().get_center())
	if main.phase == main.Phase.TITLE:
		main._start_game()  # fallback if the click missed
		_log("title click fallback used")
	await _wait(1.0)
	await shot("01_arrival")
	# Report to Eddington.
	await walk([Vector3(1.2, 0, 1.6), EDD_FRONT])
	var id := await interact(EDD_HEAD)
	_log("interact -> %s" % id)
	await shot("02_briefing")
	# Pause mid-dialogue: E presses must not advance it; Esc resumes.
	var before: int = main.ui._seq_i
	await _tap(KEY_ESCAPE)
	var paused_ok: bool = get_tree().paused
	await _tap(KEY_E)
	await _tap(KEY_E)
	var held: bool = main.ui._seq_i == before
	await _tap(KEY_ESCAPE)
	_log("pause check: paused=%s dialogue_held=%s resumed=%s" % [paused_ok, held, not get_tree().paused])
	await talk([1])
	if scenario == "rushed":
		# Straight to totality: no plates fetched, drive left to Cottingham alone.
		await interact(EDD_HEAD)
		await talk([0])
	else:
		await _prep_full()
	await _wait_phase("totality", 20.0)
	await _wait(2.5)
	await shot("05_totality_start")
	await _totality()
	await _wait_phase("night", 40.0)
	await _wait(1.0)
	await talk()
	await shot("07_darkroom")
	await _night()
	await _wait_phase("ending", 30.0)
	await _wait(0.8)
	await shot("10_ending")
	_finish()


func _prep_full() -> void:
	# Fetch every plate holder in one trip.
	await walk([Vector3(1.2, 0, 1.6), DOOR_OUT, DOOR_IN, BOX_SPOT])
	await look(Vector3(11.65, 1.18, 2.25))
	_log("aim at %s" % main.player.aimed_interactable().get_meta("interact_id") if main.player.aimed_interactable() else "aim at nothing")
	await shot("03_darkroom_box")
	await _hold(KEY_E, 8 * 1.2 + 0.6)
	_log("carried %d" % main.sim.plates_carried)
	await walk([DOOR_IN, DOOR_OUT, Vector3(1.6, 0, 0.8), STATION_SPOT])
	await interact(Vector3(0, 1.35, -1.92))
	_log("delivered -> available %d" % main.sim.plates_available())
	# Cottingham and the drive.
	await walk([RIGHT_FRONT, RIGHT_BACK])
	await interact(Vector3(1.35, 1.6, -6.1))
	await talk()
	await walk([DRIVE_SPOT])
	await look(Vector3(0.62, 0.92, -6.6))
	await shot("04_coelostat")
	await _hold(KEY_E, 3.5)
	_log("drive wound %s" % main.sim.drive_wound)
	await walk([RIGHT_BACK, RIGHT_FRONT, Vector3(0.5, 0, -0.1), FRONT_LEFT, TABLE_SPOT])
	await look(Vector3(-1.65, 0.89, -3.45))
	await _hold(KEY_E, 4.5)
	_log("rate checked %s" % main.sim.drive_rate_checked)
	await interact(Vector3(-2.2, 0.845, -3.35))
	await talk()
	await interact(Vector3(-2.65, 0.95, -3.45))
	await talk()
	_log("prep left %.1f s" % main.prep_left)
	await walk([FRONT_LEFT, EDD_FRONT])
	await interact(EDD_HEAD)
	await talk([0])


func _wait_phase(p: String, timeout: float) -> void:
	while _phase_event != p and timeout > 0.0:
		await _wait(0.25)
		timeout -= 0.25
	if _phase_event != p:
		_log("TIMEOUT waiting for phase %s" % p)


func _totality() -> void:
	var sim = main.sim
	var shot_mid := false
	var shot_open := false
	while not main.tot_done:
		var t: float = main.t_game
		var dens: float = sim.cloud_over_sun(t)
		var exposing: bool = sim.is_exposing()
		var want := false
		if scenario == "rushed":
			# Ignore the sky: fixed long exposures back to back.
			var dur: float = sim._open.duration if exposing else 0.0
			want = (not exposing) or dur < 18.0
			if exposing and dur >= 18.0:
				want = false
		else:
			var dur: float = sim._open.duration if exposing else 0.0
			var limit := 16.0 if sim.drive_rate_checked else 6.0
			if exposing:
				want = dens < 0.62 and dur < limit and t < sim.TOTALITY_S - 6.0
			else:
				want = dens < 0.45 and t < sim.TOTALITY_S - 10.0
		if want != exposing and (exposing or (main.change_left <= 0.0 and main.plates_left > 0)):
			await _tap(KEY_SPACE)
			_log("t=%.1f dens=%.2f -> %s" % [t, dens, "OPEN" if not exposing else "CLOSE"])
			if not exposing and not shot_open and dens < 0.45:
				shot_open = true
				await shot("06b_totality_gap_open")
		if int(t) % 30 == 0 and int(t) != int(main.t_game - get_process_delta_time() * sim.TIME_SCALE):
			_log("heartbeat t=%.0f dens=%.2f exposing=%s" % [t, dens, exposing])
		if t > 150.0 and not shot_mid:
			shot_mid = true
			await shot("06_totality_mid")
		await _frames(1)


func _night() -> void:
	var w: Dictionary = main.world
	var m: Vector3 = w.measure_pos
	await look(m)
	var id := await interact(m)
	_log("night interact -> %s" % id)
	await _frames(5)
	if not main.ui.viewer.visible:
		_log("viewer did not open; walking closer")
		await walk([m + Vector3(-1.0, 0, 0)])
		await interact(m)
	await shot("08_viewer_before")
	var plates: Array = main.sim.plates
	var omitted := -1
	for i in plates.size():
		var p: Dictionary = plates[i]
		var include := false
		match scenario:
			"rushed":
				include = true
			"cherry":
				include = p.quality == "good"
			_:
				include = p.quality == "good"
		if scenario == "cherry" and include and omitted < 0 and main.sim.count_quality("good") > 1:
			omitted = i
			include = false
		if include:
			await _click(main.ui.thumb_center(i))
			await _click(main.ui.viewer_button_center("include"))
	_log("included %s" % str(plates.filter(func(p): return p.included).map(func(p): return p.number)))
	await _click(main.ui.viewer_button_center("measure"))
	await _wait(0.4)
	if scenario == "cherry":
		# Seeing the values, change the selection: add back the omitted plate.
		await _click(main.ui.viewer_button_center("reselect"))
		if omitted >= 0:
			await _click(main.ui.thumb_center(omitted))
			await _click(main.ui.viewer_button_center("include"))
		await _click(main.ui.viewer_button_center("measure"))
		await _wait(0.3)
	await shot("09_viewer_measured")
	_log("evidence %s, combined %s" % [main.sim.evidence_class(), str(main.sim.combined())])
	await _click(main.ui.viewer_button_center("report"))
	await _frames(4)
	var ev: String = main.sim.evidence_class()
	var tele := 1
	var reason := 0
	match scenario:
		"rushed":
			tele = 0
			reason = 2
		_:
			tele = {"none": 3, "favors_e": 1, "ambiguous": 2, "favors_half": 2}[ev]
			reason = {"none": 3, "favors_e": 0, "ambiguous": 1, "favors_half": 1}[ev]
	await talk([tele, reason])
	await _wait(0.5)
	await talk()


func _finish() -> void:
	var sim = main.sim
	var result := {
		"scenario": scenario,
		"seed": sim.run_seed,
		"phase_reached": main.Phase.keys()[main.phase],
		"plates_available": sim.plates_available(),
		"drive_wound": sim.drive_wound,
		"drive_rate_checked": sim.drive_rate_checked,
		"plates": sim.plates.map(func(p): return {"n": p.number, "start": snappedf(p.start, 0.1), "dur": snappedf(p.duration, 0.1), "stars": p.stars, "fog": snappedf(p.fog, 0.01), "trail": snappedf(p.trail, 0.01), "quality": p.quality, "included": p.included, "value": snappedf(p.value, 0.01), "sigma": snappedf(p.sigma, 0.01)}),
		"combined": sim.combined(),
		"evidence": sim.evidence_class(),
		"ending_title": main._grade.get("title", ""),
		"score": main._grade.get("score", -1),
		"stuck_events": stuck,
		"log": log_lines,
	}
	if shots_dir != "":
		var f := FileAccess.open(shots_dir.path_join("result_%s.json" % scenario), FileAccess.WRITE)
		f.store_string(JSON.stringify(result, "  "))
		f.close()
	_log("DONE ending=%s evidence=%s score=%s stuck=%d" % [result.ending_title, result.evidence, result.score, stuck])
	await _wait(0.5)
	if scenario == "careful":
		# Press 「新的天空」 on the ending screen; the restarted scene continues in _run().
		var btns: Array = main.ui.ending_panel.find_children("*", "Button", true, false)
		for b in btns:
			if b.text == "新的天空":
				# Press and release without awaiting: the scene (and this bot) is freed on reload.
				var pos: Vector2 = b.get_global_rect().get_center()
				for pressed in [true, false]:
					var ev := InputEventMouseButton.new()
					ev.button_index = MOUSE_BUTTON_LEFT
					ev.position = pos
					ev.global_position = pos
					ev.pressed = pressed
					Input.parse_input_event(ev)
				return
	get_tree().quit()
