extends Node
## Real-input M1 smoke driver. No world/state mutation, teleports or fallback calls.
## Persistent root child so the receipt verifies Story across real scene changes.
const Cast = preload("res://scripts/cambridge/cast.gd")

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
var _input_retries := 0
var _speaker_watched := false
var _speaker_shots: Dictionary = {}


func _ready() -> void:
	if shots_dir != "":
		DirAccess.make_dir_recursive_absolute(shots_dir)
		DirAccess.remove_absolute(shots_dir.path_join("result_" + scenario + ".json"))
	_run.call_deferred()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed > 210.0 and not _done:
		failures.append("210 second watchdog")
		_finish()
	var scene = get_tree().current_scene
	if scene and scene.get_script() and scene.get_script().resource_path.ends_with("cambridge/director.gd"):
		if not _speaker_watched:
			main = scene
			main.ui.dialogue_entry.connect(_on_dialogue_entry)
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
	if name_ in ["OPENING", "MENTOR", "INTERLUDE", "EXAM", "CODA"]:
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


func talk(choices: Array = []) -> void:
	var guard := 90
	var index := 0
	await frames()
	while is_instance_valid(main) and main.ui.dialog_active() and guard > 0:
		while _capturing > 0:
			await frames()
		guard -= 1
		var entry: Dictionary = main.ui._seq[main.ui._seq_i]
		if entry.has("choices"):
			var choice: int = int(choices[index]) if index < choices.size() else 0
			index += 1
			await tap(KEY_1 + choice)
		else:
			await tap(KEY_E)
		await frames(3)
	if guard == 0:
		failures.append("dialogue guard exhausted")


func shot(label: String) -> void:
	if shots_dir == "":
		return
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
			if main._pending == "mentor_review" and scenario == "honest" and not _revised:
				await talk([0])
				_revised = true
			else:
				# accuse: defend the accusation once, then accept the mentor's request to look again.
				await talk(([1, 0] if scenario == "accuse" else [1]) if main._pending == "mentor_review" else [0, 1])
		if main.report_sheet.visible:
			if scenario == "accuse":
				_revised = true
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
	while not Story.prologue_done:
		if is_instance_valid(main) and main.ui.dialog_active():
			await shot("dialogue_" + str(main._pending))
			await talk([1])
		await frames(5)
	while not is_instance_valid(get_tree().current_scene) or get_tree().current_scene.get_script().resource_path != "res://scripts/main.gd":
		await frames()
	main = get_tree().current_scene
	await frames(30)
	await shot("11_principe_prep")
	if main.phase != main.Phase.PREP or main.ui.title_panel.visible:
		failures.append("bridge did not enter PREP directly")
	if Story.report.get("kit_credited", false) != true: failures.append("independent check credit missing")
	if not Story.clues.get("log", false): failures.append("observing log clue missing")
	_finish()


func _finish() -> void:
	if _done: return
	_done = true
	var receipt := {"scenario": scenario, "phase_reached": "PREP" if is_instance_valid(main) and main.get_script().resource_path == "res://scripts/main.gd" and main.phase == main.Phase.PREP else "INCOMPLETE",
		"prologue_done": Story.prologue_done, "from_prologue_consumed": not Story.from_prologue,
		"clues": Story.clues, "report": Story.report, "plan": Story.plan, "kit_choice": Story.kit_choice,
		"matched": _matched, "bias_blocked": _bias_blocked, "report_revised": _revised, "beats": beats, "interactions": interactions,
		"screenshots": screenshots, "failures": failures, "human_playtest": false,
		"engine": Engine.get_version_info().string, "elapsed_seconds": snappedf(_elapsed, 0.01),
		"room_draw_calls_max_observed": _room_draw_calls, "input_retries": _input_retries}
	if shots_dir != "":
		var file := FileAccess.open(shots_dir.path_join("result_" + scenario + ".json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(receipt, "  "))
	print("[PROLOGUE %s] %s matched=%d bias_blocked=%s screenshots=%d failures=%s" % [scenario, receipt.phase_reached, _matched, _bias_blocked, screenshots.size(), str(failures)])
	get_tree().quit(0 if failures.is_empty() else 1)
