extends Node
## Real-input M1 smoke driver. No world/state mutation, teleports or fallback calls.
## Persistent root child so the receipt verifies Story across real scene changes.
const Cast = preload("res://scripts/cambridge/cast.gd")
const ScorePlayer = preload("res://scripts/audio/score_player.gd")

var main
var scenario := "honest"
var shots_dir := ""
var failures: Array[String] = []
var screenshots: Array[String] = []
var beats: Array[String] = []
var interactions: Array[String] = []
var _elapsed := 0.0
var _done := false
var _shot_beats: Dictionary = {}
var _matched := 0
var _bias_blocked := false
var _revised := false
var _capturing := 0
var _room_draw_calls := 0
var _departure_draw_calls := 0
var _input_retries := 0
var _speaker_watched := false
var _speaker_scene_id := 0
var _departure_handled := false
var _speaker_shots: Dictionary = {}
var _choice_shots: Dictionary = {}
var _coda_capture_seen: Dictionary = {}
var _coda_fade_capture_started := false
var _coda_checks := {"workbook": false, "loupe": false, "kit_close": false, "lamp_out": false, "complete": false}


func _ready() -> void:
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
		DirAccess.remove_absolute(shots_dir.path_join("result_" + scenario + ".json"))
	_run.call_deferred()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed > 900.0 and not _done:
		failures.append("900 second watchdog")
		_finish()
	var scene = get_tree().current_scene
	if is_instance_valid(main) and main.get_script() and main.get_script().resource_path == "res://scripts/main.gd" and main.phase == main.Phase.CODA and main.coda_step == main.CodaStep.FADING and not _coda_fade_capture_started:
		_coda_fade_capture_started = true
		_capture_coda_lamp_out.call_deferred()
	if scene and scene.get_script() and scene.get_script().resource_path.ends_with("cambridge/departure_director.gd"):
		if _speaker_scene_id != scene.get_instance_id():
			main = scene
			main.ui.dialogue_entry.connect(_on_dialogue_entry)
			_speaker_scene_id = scene.get_instance_id()
			_speaker_watched = true
		if not _departure_handled:
			_departure_handled = true
			_departure_run.call_deferred()
		var name_: String = main.Beat.keys()[main.beat]
		if not _shot_beats.has("M2_" + name_):
			_shot_beats["M2_" + name_] = true
			beats.append("M2_" + name_)
			_beat_shot(name_)
		if main._free():
			_departure_draw_calls = maxi(_departure_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
	if scene and scene.get_script() and scene.get_script().resource_path.ends_with("cambridge/director.gd"):
		if _speaker_scene_id != scene.get_instance_id():
			main = scene
			main.ui.dialogue_entry.connect(_on_dialogue_entry)
			_speaker_scene_id = scene.get_instance_id()
			_speaker_watched = true
		if scene.beat == scene.Beat.INVESTIGATE and scene._free():
			_room_draw_calls = maxi(_room_draw_calls, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)))
		var name_: String = scene.Beat.keys()[scene.beat]
		if not _shot_beats.has(name_):
			_shot_beats[name_] = true
			beats.append(name_)
			_beat_shot(name_)


func _beat_shot(name_: String) -> void:
	_capturing += 1
	if name_ == "INTERLUDE":
		var establishing_wait := 8.0
		while establishing_wait > 0.0 and is_instance_valid(main) and (not main._daylight or main.ui.fade.color.a > 0.01):
			await get_tree().process_frame
			establishing_wait -= get_process_delta_time()
		await shot("interlude_room")
	if name_ in ["OPENING", "MENTOR", "INTERLUDE", "EXAM", "CODA", "CHECKING", "KIT", "PROMISE", "FAREWELL"]:
		var wait_left := 18.0
		while wait_left > 0.0 and is_instance_valid(main) and not main.ui.dialog_active():
			await get_tree().process_frame
			wait_left -= get_process_delta_time()
		if not is_instance_valid(main) or not main.ui.dialog_active():
			failures.append("beat shot did not reach visible dialogue: " + name_)
			_capturing -= 1
			return
		await _wait_for_camera_settle()
	else:
		await get_tree().create_timer(0.45).timeout
	await shot("beat_" + name_.to_lower())
	if name_ == "EXAM":
		if not main._daylight or main.world.lamp.light_energy > 0.01 or main.world.window_light.light_energy < 1.0:
			failures.append("exam daylight state was not active at interlude screenshot")
		else:
			await shot("interlude_daylight")
	_capturing -= 1


func _on_dialogue_entry(speaker: String) -> void:
	if not is_instance_valid(main) or not main.world:
		return
	if main.get_script().resource_path.ends_with("cambridge/departure_director.gd") and main._pending == "promise":
		var current_entry: Dictionary = main.ui._seq[main.ui._seq_i]
		if str(current_entry.get("t", "")).contains("翻開工作簿"):
			_capture_workbook()
	var label := ""
	if speaker == Cast.KIT and main.world.kit.visible:
		label = "kit"
	elif speaker == Cast.MENTOR and main.world.mentor.visible:
		label = "mentor"
	elif speaker == Cast.EDDINGTON and main.world.eddington.visible:
		label = "eddington"
	if label == "":
		return
	var beat_label: String = main.Beat.keys()[main.beat].to_lower()
	var shot_key := "%s/%s" % [beat_label, label]
	if _speaker_shots.has(shot_key):
		return
	_speaker_shots[shot_key] = true
	_capture_speaker(beat_label, label)


func _capture_speaker(beat_label: String, label: String) -> void:
	_capturing += 1
	await _wait_for_camera_settle()
	await shot("speaker_" + beat_label + "_" + label)
	_capturing -= 1


func _capture_workbook() -> void:
	_capturing += 1
	await _wait_for_camera_settle()
	await get_tree().create_timer(0.65).timeout
	await shot("m2_workbook")
	_capturing -= 1


func _wait_for_camera_settle() -> void:
	var wait_left := 3.0
	while wait_left > 0.0 and is_instance_valid(main) and main._camera_turn and main._camera_turn.is_running():
		await get_tree().process_frame
		wait_left -= get_process_delta_time()
	await get_tree().create_timer(0.45).timeout


func frames(n := 3) -> void:
	for i in n:
		await get_tree().process_frame


func key(code: Key, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.keycode = code
	ev.physical_keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)


func tap(code: Key) -> void:
	key(code, true)
	await frames(2)
	key(code, false)
	await frames(3)


func click_at(pos: Vector2) -> void:
	pos = get_viewport().get_stretch_transform() * pos
	var motion := InputEventMouseMotion.new()
	motion.position = pos
	motion.global_position = pos
	Input.parse_input_event(motion)
	await frames()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = pos
		event.global_position = pos
		event.pressed = pressed
		Input.parse_input_event(event)
		await frames()


func click_button(button: Button) -> void:
	await frames()
	var observed := [false]
	var listener := func(): observed[0] = true
	button.pressed.connect(listener)
	for attempt in 3:
		if not is_instance_valid(button) or not button.is_visible_in_tree():
			break
		print("[PROLOGUE INPUT] click ", button.text, " ", button.get_global_rect(), " attempt=", attempt + 1)
		await click_at(button.get_global_rect().get_center())
		if observed[0]:
			break
		_input_retries += 1
		await frames(8)
	if is_instance_valid(button) and button.pressed.is_connected(listener):
		button.pressed.disconnect(listener)
	if not observed[0]:
		failures.append("button did not accept real click after 3 attempts")
		_finish()


func drag(from: Vector2, to: Vector2) -> void:
	var stretch := get_viewport().get_stretch_transform()
	from = stretch * from
	to = stretch * to
	var down := InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = from
	down.global_position = from
	down.pressed = true
	Input.parse_input_event(down)
	await frames()
	var motion := InputEventMouseMotion.new()
	motion.position = to
	motion.global_position = to
	motion.relative = to - from
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(motion)
	await frames()
	down = InputEventMouseButton.new()
	down.button_index = MOUSE_BUTTON_LEFT
	down.position = to
	down.global_position = to
	down.pressed = false
	Input.parse_input_event(down)
	await frames()


func look(target: Vector3) -> void:
	var p = main.player
	var delta: Vector3 = target - p.camera.global_position
	var yaw := atan2(-delta.x, -delta.z)
	var pitch := atan2(delta.y, Vector2(delta.x, delta.z).length())
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(-wrapf(yaw - p.yaw, -PI, PI) / p.MOUSE_SENS, -(pitch - p.pitch) / p.MOUSE_SENS) * get_viewport().get_stretch_transform().get_scale()
	Input.parse_input_event(motion)
	await frames(5)


func walk(target: Vector3) -> void:
	var budget := 9.0
	while budget > 0.0:
		var p = main.player
		var here := Vector2(p.global_position.x, p.global_position.z)
		if here.distance_to(Vector2(target.x, target.z)) < 0.22:
			break
		await look(Vector3(target.x, p.camera.global_position.y, target.z))
		key(KEY_W, true)
		await frames(2)
		budget -= get_process_delta_time() * 7.0
	key(KEY_W, false)
	await frames(3)
	if budget <= 0.0:
		failures.append("movement blocked on way to " + str(target))


func interact(id: String) -> void:
	await look(main.world.targets[id])
	var target: Node = main.player.aimed_interactable()
	var actual := str(target.get_meta("interact_id")) if target else "none"
	print("[PROLOGUE INPUT] interact ", id, " -> ", actual)
	interactions.append(actual)
	if actual != id:
		failures.append("aim expected %s got %s" % [id, actual])
	await tap(KEY_E)


func talk(choices: Array = [], default_choice := 0) -> void:
	var guard := 90
	var index := 0
	await frames()
	while is_instance_valid(main) and main.ui.dialog_active() and guard > 0:
		while _capturing > 0:
			await frames()
		guard -= 1
		var entry: Dictionary = main.ui._seq[main.ui._seq_i]
		if entry.has("choices"):
			await frames(3)
			if main.ui.dialog_panel.get_global_rect().end.y > get_viewport().get_visible_rect().end.y + 1.0:
				failures.append("dialogue choices extend below the viewport")
			var choice_label: String = main.Beat.keys()[main.beat].to_lower() + "_" + str(main._pending)
			if not _choice_shots.has(choice_label):
				_choice_shots[choice_label] = true
				await _wait_for_camera_settle()
				await shot("choice_" + choice_label)
			var choice: int = int(choices[index]) if index < choices.size() else default_choice
			index += 1
			await tap(KEY_1 + choice)
		else:
			await tap(KEY_E)
		await frames(3)
	if guard == 0:
		failures.append("dialogue guard exhausted")


func talk_keys(choices_by_key: Dictionary, default_choice := 0) -> void:
	var guard := 120
	while is_instance_valid(main) and main.ui.dialog_active() and guard > 0:
		while _capturing > 0:
			await frames()
		guard -= 1
		var entry: Dictionary = main.ui._seq[main.ui._seq_i]
		if entry.has("choices"):
			await frames(3)
			var choice: int = int(choices_by_key.get(str(entry.get("key", "")), default_choice))
			var choice_label: String = main.Beat.keys()[main.beat].to_lower() + "_" + str(main._pending)
			if not _choice_shots.has(choice_label):
				_choice_shots[choice_label] = true
				await _wait_for_camera_settle()
				await shot("choice_" + choice_label)
			await tap(KEY_1 + choice)
		else:
			await tap(KEY_E)
		await frames(3)
	if guard == 0:
		failures.append("keyed dialogue guard exhausted")


func shot(label: String) -> void:
	if shots_dir == "":
		return
	if is_instance_valid(main) and main.get_script() and main.get_script().resource_path.ends_with("cambridge/departure_director.gd") and not label.begins_with("m2_"):
		label = "m2_" + label
	# Native windows can stop drawing behind another application on macOS.
	# Bring this real game window forward before waiting for rendered evidence.
	DisplayServer.window_move_to_foreground()
	var drawn := [false]
	RenderingServer.frame_post_draw.connect(func(): drawn[0] = true, CONNECT_ONE_SHOT)
	var draw_wait := 8.0
	while not drawn[0] and draw_wait > 0.0:
		await get_tree().process_frame
		draw_wait -= get_process_delta_time()
	if not drawn[0]:
		failures.append("window did not draw: " + label)
		return
	var path := shots_dir.path_join(scenario + "_" + label + ".png")
	var error := get_viewport().get_texture().get_image().save_png(path)
	if error == OK:
		screenshots.append(path)
	else:
		failures.append("screenshot write failed: " + label)


func _run() -> void:
	await frames(30)
	if scenario not in ["honest", "tidy", "accuse"]:
		failures.append("unknown scenario")
		_finish()
		return
	await shot("00_title")
	await click_button(main.ui.prologue_btn)
	while not get_tree().current_scene.get_script().resource_path.ends_with("cambridge/director.gd"):
		await frames()
	main = get_tree().current_scene
	while main._busy:
		await frames()
	await shot("01_opening")
	await tap(KEY_TAB)
	if not main.ui.log_open(): failures.append("Tab did not open log")
	await shot("01b_log")
	await tap(KEY_TAB)
	await talk()
	if scenario == "honest":
		await walk(Vector3(2.7, 0, 1.7))
		await interact("kit")
		await _wait_for_camera_settle()
		await shot("close_kit")
		await talk()
		await walk(Vector3(0, 0, 2.35))
	await look(main.world.targets.lightbox)
	await shot("investigate_room")
	await look(Vector3(0, 1.4, 3.1))
	await shot("investigate_door")
	await interact("notebook")
	await shot("02_report_gated")
	if main.report_sheet.option_buttons.has("cause/both"):
		failures.append("both cause visible without clues")
	await click_button(main.report_sheet.close_btn)
	await interact("lightbox")
	await shot("03_mismatch")
	var viewer = main.overlay
	await click_at(viewer.detail_position("label_mirrored"))
	await click_at(viewer.detail_position("arrow_tilted"))
	if not main.ui.toast.is_visible_in_tree():
		failures.append("viewer clue feedback toast hidden")
	var center: Vector2 = viewer.canvas_rect().get_center()
	await drag(center, center + Vector2(27, 12))
	await drag(center + Vector2(27, 12), center)
	await click_button(viewer.buttons.flip)
	await shot("04_flipped")
	for i in 6:
		await click_button(viewer.buttons.right)
	if not viewer.aligned:
		failures.append("overlay failed geometric alignment")
	_matched = preload("res://scripts/cambridge/overlay_math.gd").match_count(preload("res://scripts/cambridge/overlay_math.gd").transformed_copy(viewer.flipped, viewer.angle_deg, viewer.offset))
	await shot("05_aligned")
	await click_at(viewer.detail_position("residual"))
	await shot("06_loupe")
	await click_button(viewer.buttons.close)
	await talk()
	await walk(Vector3(2.45, 0, 1.4))
	await walk(Vector3(2.5, 0, -0.15))
	await interact("logbook")
	await shot("07_logbook")
	await talk()
	await walk(Vector3(2.1, 0, -0.15))
	await walk(Vector3(2.1, 0, 2.35))
	await walk(Vector3(0.6, 0, 2.35))
	await interact("kit")
	await talk()
	await walk(Vector3(0.8, 0, 1.65))
	await interact("notebook")
	var sheet = main.report_sheet
	var selections: Array = ["cause/both", "original/keep", "residual/unresolved"]
	if scenario == "tidy": selections = ["cause/both", "original/redraw", "residual/delete"]
	if scenario == "accuse": selections = ["cause/accuse", "original/keep", "residual/new_object"]
	for id in selections:
		if sheet.option_buttons.has(id):
			await click_button(sheet.option_buttons[id])
		else:
			failures.append("missing report option " + id)
	await shot("08_report")
	await click_button(sheet.submit_btn)
	while not main.plan_board.visible:
		if main.ui.dialog_active():
			await shot("dialogue_" + str(main._pending))
			if main._pending == "mentor_review":
				var has_revision_prompt := false
				for entry in main.ui._seq:
					if entry.get("key", "") == "revise_report":
						has_revision_prompt = true
				if scenario == "honest" and has_revision_prompt:
					failures.append("honest report unexpectedly offered revise_report")
				if scenario != "honest" and not has_revision_prompt:
					failures.append("hasty report omitted revise_report")
				if scenario == "accuse" and not _revised:
					# First review: defend once, then accept the request to look again.
					await talk([1, 0])
					_revised = true
				else:
					# Accept every later mentor choice, including tidy's first review.
					await talk([], 1)
			else:
				await talk([0, 1])
		if main.report_sheet.visible:
			if scenario == "accuse":
				selections = ["cause/both", "original/keep", "residual/new_object"]
			for id in selections:
				await click_button(main.report_sheet.option_buttons[id])
			await shot("08b_revised_report")
			await click_button(main.report_sheet.submit_btn)
		await frames(5)
	var board = main.plan_board
	# Exercise the reconsideration path in all three runs.
	for id in ["comparison", "far_stars", "keep_agreeing"]:
		await click_button(board.card_buttons[id])
		await talk()
	await shot("09_bias_plan")
	await click_button(board.finish_btn)
	_bias_blocked = main.ui.dialog_active() and main.beat == main.Beat.PLAN and Story.plan.is_empty()
	if not _bias_blocked: failures.append("bias plan was not blocked")
	await talk()
	await click_button(board.card_buttons.keep_agreeing)
	await click_button(board.card_buttons.rules_first)
	await talk()
	await shot("10_fair_plan")
	await click_button(board.finish_btn)
	# Drain the last M1 report-plan/coda dialogue until its 1918 bridge hands off.
	while not Story.prologue_done:
		if is_instance_valid(main) and main.get_script() and main.get_script().resource_path.ends_with("cambridge/director.gd") and main.ui.dialog_active():
			await shot("dialogue_" + str(main._pending))
			await talk([1])
		await frames(5)
	# M1 now transitions into the authored M2 scene. Its dedicated routine runs the
	# checklist and choices while this persistent runner waits for the M2 completion flag.
	while not Story.departure_done:
		await frames(5)
	while not is_instance_valid(get_tree().current_scene) or get_tree().current_scene.get_script().resource_path != "res://scripts/main.gd":
		await frames()
	main = get_tree().current_scene
	await frames(30)
	await shot("11_principe_prep")
	if main.phase != main.Phase.PREP or main.ui.title_panel.visible:
		failures.append("bridge did not enter PREP directly")
	var expected_bond := "close" if scenario == "honest" else "warm"
	var expected_fix := 1 if scenario == "tidy" else 0
	if Story.bond_tone != expected_bond: failures.append("unexpected M2 bond tone: " + Story.bond_tone)
	if Story.slip_fix != expected_fix: failures.append("unexpected M2 correction choice: %d" % Story.slip_fix)
	if not Story.departure_done: failures.append("M2 completion flag missing at PREP")
	if Story.report.get("kit_credited", false) != true: failures.append("independent check credit missing")
	if not Story.clues.get("log", false): failures.append("observing log clue missing")
	# Honest is the full cross-era route: reuse the ordinary 1919 careful bot's
	# real-input routine, then drive the prologue-only coda through its hotspots.
	# Tidy and accuse retain the established PREP receipt contract.
	if scenario == "honest":
		await _continue_honest_to_ending()
	_finish()


func _continue_honest_to_ending() -> void:
	var route: Node = load("res://tests/autoplay_bot.gd").new()
	route.main = main
	route.scenario = "careful"
	route.shots_dir = shots_dir
	route.real_input_only = true
	route.continuation_helper = true
	add_child(route)
	# These routines use the same walk, look, E, Space, and UI click inputs as the
	# standalone 1919 careful route. This attached helper stays passive until its
	# routines are called, and never edits Story or gameplay state.
	await route.walk([Vector3(1.2, 0, 1.6), Vector3(-1.1, 0, 0.4)])
	var briefing_id: String = await route.interact(Vector3(-1.1, 1.6, -0.9))
	if briefing_id != "eddington":
		failures.append("honest 1919 briefing aim expected eddington, got " + briefing_id)
		return
	await route.talk([1])
	await route._prep_full()
	var phase_guard := 45.0
	while (main.phase != main.Phase.TOTALITY or main._busy) and phase_guard > 0.0:
		await frames(2)
		phase_guard -= get_process_delta_time()
	if main.phase != main.Phase.TOTALITY or main._busy:
		failures.append("honest 1919 route did not reach totality")
		return
	if route.stuck > 0:
		failures.append("honest 1919 route could not walk to %d waypoint(s)" % route.stuck)
		return
	await route._totality()
	phase_guard = 60.0
	while (main.phase != main.Phase.NIGHT or main._busy) and phase_guard > 0.0:
		await frames(2)
		phase_guard -= get_process_delta_time()
	if main.phase != main.Phase.NIGHT or main._busy:
		failures.append("honest 1919 route did not reach night")
		return
	await route.talk()
	# Catch the coda's opening dialogue at its real entry event. The helper stops
	# draining as soon as the phase changes, leaving it for this persistent runner.
	if not main.ui.dialogue_entry.is_connected(_on_coda_dialogue_entry):
		main.ui.dialogue_entry.connect(_on_coda_dialogue_entry)
	await route._night()
	phase_guard = 30.0
	while main.phase != main.Phase.CODA and phase_guard > 0.0:
		await frames(2)
		phase_guard -= get_process_delta_time()
	if main.phase != main.Phase.CODA:
		failures.append("honest route did not enter CODA after judgment")
		return
	await frames(30)
	await shot("coda_opening")
	await talk()
	await tap(KEY_TAB)
	if not main.ui.log_open(): failures.append("Tab did not open coda log")
	await tap(KEY_TAB)
	await tap(KEY_ESCAPE)
	var paused := get_tree().paused
	await tap(KEY_E)
	await tap(KEY_ESCAPE)
	if not paused or get_tree().paused: failures.append("coda pause/resume input was unsafe")
	# Workbook interaction is mandatory even if the night phase already wrote
	# one; the authored coda selects the appropriate new/repeat response.
	var workbook: Node = main.find_child("PríncipeDepartureWorkbookHotspot", true, false)
	if workbook == null:
		failures.append("coda workbook hotspot missing")
		return
	await look(workbook.global_position)
	var aimed: Node = main.player.aimed_interactable()
	if aimed == null or str(aimed.get_meta("interact_id", "")) != "departure_workbook":
		failures.append("coda workbook was not aimed by normal input")
		return
	await shot("coda_workbook")
	interactions.append("departure_workbook")
	await tap(KEY_E)
	await talk()
	_coda_checks.workbook = main.coda_step == main.CodaStep.LOUPE
	await shot("coda_lamp")
	var loupe: Node = main.find_child("AshbyLoupeHotspot", true, false)
	if loupe == null:
		failures.append("coda loupe hotspot missing")
		return
	await look(loupe.global_position)
	aimed = main.player.aimed_interactable()
	if aimed == null or str(aimed.get_meta("interact_id", "")) != "mentor_loupe":
		failures.append("coda loupe was not aimed by normal input")
		return
	await shot("coda_loupe")
	interactions.append("mentor_loupe")
	await tap(KEY_E)
	await talk()
	# Loupe response advances through Kit's close and the lamp fade.
	await talk()
	_coda_checks.loupe = main.coda_step == main.CodaStep.FADING or main.phase == main.Phase.ENDING
	_coda_checks.kit_close = _coda_capture_seen.has("coda_kit_close")
	phase_guard = 30.0
	while main.phase != main.Phase.ENDING and phase_guard > 0.0:
		await frames(2)
		phase_guard -= get_process_delta_time()
	if main.phase != main.Phase.ENDING:
		failures.append("coda did not reach ENDING")
		return
	_coda_checks.complete = true
	_coda_checks.lamp_out = _coda_capture_seen.has("coda_lamp_out")
	await frames(30)
	await shot("ending")
	# Exercise the expandable historical record through its visible button.
	for b in main.ui.ending_panel.find_children("*", "Button", true, false):
		if b.text == "歷史上發生了什麼":
			await click_button(b)
			await frames(8)
			await shot("ending_history")
			return
	failures.append("ending history toggle button missing")


func _on_coda_dialogue_entry(_speaker: String) -> void:
	if not is_instance_valid(main) or main.phase != main.Phase.CODA:
		return
	var label := ""
	match str(main._pending):
		"coda_opening": label = "coda_opening_dialogue"
		"coda_workbook": label = "coda_workbook_dialogue"
		"coda_loupe": label = "coda_ashby_response"
		"coda_kit": label = "coda_kit_close"
	if label == "" or _coda_capture_seen.has(label):
		return
	_coda_capture_seen[label] = true
	_capturing += 1
	_capture_coda_dialogue.call_deferred(label)


func _capture_coda_dialogue(label: String) -> void:
	await _wait_for_camera_settle()
	await shot(label)
	_capturing -= 1


func _capture_coda_lamp_out() -> void:
	var wait_left := 5.0
	while is_instance_valid(main) and main.phase == main.Phase.CODA and main.world.lamp.light_energy > 0.05 and wait_left > 0.0:
		await frames(2)
		wait_left -= get_process_delta_time()
	if is_instance_valid(main) and main.phase == main.Phase.CODA:
		_coda_capture_seen["coda_lamp_out"] = true
		await shot("coda_lamp_out")


func _departure_run() -> void:
	var deadline := 45.0
	while is_instance_valid(main) and main._busy and deadline > 0.0:
		await frames()
		deadline -= get_process_delta_time()
	if deadline <= 0.0:
		failures.append("M2 scene did not finish its arrival transition")
		_finish()
		return
	await shot("m2_arrival")
	await talk_keys({"open": 0})
	await walk(Vector3(-0.85, 0, 1.3))
	await interact("lightbox")
	var sheet = main.checklist
	if not is_instance_valid(sheet) or not sheet.visible:
		failures.append("lightbox did not open M2 checklist")
		_finish()
		return
	await shot("m2_checklist")
	var guard := 20
	while sheet.visible and sheet.active_index < sheet.entries.size() and guard > 0:
		# A row becomes markable only after Kit's authored readback dialogue.
		if main.ui.dialog_active():
			await talk_keys({})
		if not sheet.visible or sheet.active_index >= sheet.entries.size():
			break
		if not sheet.ready_to_mark:
			await frames(2)
			continue
		var entry: Dictionary = sheet.entries[sheet.active_index]
		var is_slip := bool(entry.get("slip", false))
		var reject := (scenario == "honest" or scenario == "accuse") and is_slip
		if scenario == "accuse" and entry.get("id", "") == "s21":
			reject = true
		var row: Array = sheet.row_buttons[sheet.active_index]
		if row.size() < 2:
			failures.append("checklist row is missing real yes/no buttons")
			break
		await click_button(row[1] if reject else row[0])
		await shot("m2_row_" + str(entry.get("id", "")))
		guard -= 1
	if guard <= 0:
		failures.append("M2 checklist did not complete")
		_finish()
		return
	if main.ui.dialog_active():
		await talk_keys({"slip_fix": 1 if scenario == "tidy" else 0})
	if sheet.visible and is_instance_valid(sheet.continue_btn):
		var correction_wait := 3.0
		while sheet.continue_btn.disabled and correction_wait > 0.0:
			await frames()
			correction_wait -= get_process_delta_time()
		if sheet.continue_btn.disabled:
			failures.append("corrected checklist did not become dismissible")
			_finish()
			return
		await shot("m2_corrected_list")
		await click_button(sheet.continue_btn)
	await walk(Vector3(-1.75, 0, 1.4))
	await interact("kit")
	await talk_keys({"bond": 0 if scenario == "honest" else (1 if scenario == "tidy" else 2)})
	var expected_bond := "close" if scenario == "honest" else "warm"
	if main.beat != main.Beat.FAREWELL or Story.bond_tone != expected_bond:
		failures.append("Kit conversation did not reach expected M2 state: beat=%s tone=%s" % [main.Beat.keys()[main.beat], Story.bond_tone])
		_finish()
		return
	await talk_keys({"promise": 0})
	await walk(Vector3(0, 0, 2.35))
	await walk(Vector3(0, 0, 5.0))
	await look(Vector3(0, 1.3, 0))
	await shot("m2_packed_room")
	await interact("mentor")
	if interactions.is_empty() or interactions.back() != "mentor":
		failures.append("corridor interaction did not reach Ashby")
		_finish()
		return
	await talk_keys({"gift": 0})
	var gift_wait := 3.0
	while not main.keepsake.visible and gift_wait > 0.0:
		await frames()
		gift_wait -= get_process_delta_time()
	if not main.keepsake.visible:
		failures.append("Ashby farewell did not display the gift icon")
		_finish()
		return
	await shot("m2_farewell")
	# The M2 montage owns the final scene transition and sets departure_done.


func _finish() -> void:
	if _done: return
	_done = true
	var score_failures: Array[String] = []
	if scenario == "honest":
		score_failures = ScorePlayer.run_failures(true)
		failures.append_array(score_failures)
	var phase_reached := "INCOMPLETE"
	if is_instance_valid(main) and main.get_script().resource_path == "res://scripts/main.gd":
		if main.phase == main.Phase.PREP: phase_reached = "PREP"
		elif main.phase == main.Phase.ENDING: phase_reached = "ENDING"
	var receipt := {"scenario": scenario, "phase_reached": phase_reached,
		"prologue_done": Story.prologue_done, "from_prologue_consumed": not Story.from_prologue,
		"bond_tone": Story.bond_tone, "slip_fix": Story.slip_fix, "departure_done": Story.departure_done,
		"clues": Story.clues, "report": Story.report, "plan": Story.plan, "kit_choice": Story.kit_choice,
		"matched": _matched, "bias_blocked": _bias_blocked, "report_revised": _revised, "beats": beats, "interactions": interactions,
		"screenshots": screenshots, "failures": failures, "human_playtest": false,
		"score": int(main._grade.get("score", -1)) if is_instance_valid(main) and main.get_script().resource_path == "res://scripts/main.gd" else -1,
		"coda_checks": _coda_checks,
		"score_cue_log": ScorePlayer.cue_log.duplicate(true), "score_failures": score_failures,
		"engine": Engine.get_version_info().string, "elapsed_seconds": snappedf(_elapsed, 0.01),
		"room_draw_calls_max_observed": _room_draw_calls, "departure_draw_calls_max_observed": _departure_draw_calls,
		"input_retries": _input_retries}
	var run_seed := -1
	var evidence := "-"
	if is_instance_valid(main) and main.get_script().resource_path == "res://scripts/main.gd":
		run_seed = main.sim.run_seed
		evidence = main.sim.evidence_class()
	print("[PROLOGUE %s] score cue checks=%s cue_log=%s" % [scenario, str(score_failures), JSON.stringify(ScorePlayer.cue_log)])
	if shots_dir != "":
		var file := FileAccess.open(shots_dir.path_join("result_" + scenario + ".json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(receipt, "  "))
	print("[PROLOGUE %s] %s seed=%d evidence=%s score=%d matched=%d bias_blocked=%s screenshots=%d failures=%s" % [scenario, receipt.phase_reached, run_seed, evidence, receipt.score, _matched, _bias_blocked, screenshots.size(), str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
