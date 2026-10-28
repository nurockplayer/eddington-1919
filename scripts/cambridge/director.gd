extends Node3D
## M1 sequence orchestration. Text and replaceable cast stay in C17/Cast.
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const ExistingDirector := preload("res://scripts/main.gd")
const Room := preload("res://scripts/cambridge/room_builder.gd")
const Figures := preload("res://scripts/cambridge/figures.gd")
const Player := preload("res://scripts/player.gd")
const UI := preload("res://scripts/ui.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")
const C17 := preload("res://scripts/cambridge/content_1917.gd")
const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const Board := preload("res://scripts/cambridge/plan_board.gd")

enum Beat { OPENING, INVESTIGATE, MENTOR, INTERLUDE, EXAM, PLAN, TRIAL, CODA, MONTAGE, DONE }
var beat := Beat.OPENING
var world: Dictionary
var player
var ui
var overlay
var report_sheet
var plan_board
var aligned := false
var residual_found := false
var kit_checked := false
var report_done := false
var viewer_opens := 0
var guess_offered := false
var _pending := ""
var _busy := true
var _clock_t := 0.0
var _light_t := 0.0
var _daylight := false
var _camera_turn: Tween
var _speaker_fill: SpotLight3D
var _lens_tween: Tween
var _conversation_active := false
var _last_speaker := ""
var score: Node
var tick: AudioStreamPlayer
var click: AudioStreamPlayer


func _ready() -> void:
	ExistingDirector._ensure_inputs()
	Story.reset()
	world = Room.build(self)
	player = Player.new()
	player.position = world.spawn
	add_child(player)
	player.look_at_point(world.targets.lightbox)
	ui = UI.new()
	add_child(ui)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.hide_title()
	# Toasts remain visible above chapter modals while the walking HUD is hidden.
	ui.toast.reparent(ui.hud.get_parent())
	ui.toast.offset_top = -185
	ui.toast.offset_bottom = -135
	ui.pause_enabled = true
	ui.quit_pressed.connect(func(): get_tree().quit())
	ui.restart_pressed.connect(func(_same): get_tree().paused = false; get_tree().reload_current_scene())
	ui.dialogue_done.connect(_dialogue_done)
	ui.dialogue_entry.connect(_frame_speaker)
	ui.cambridge_portraits = true
	# Cambridge dialogue stays below the standing figures, including at 720p.
	ui.dialog_panel.offset_top = -214
	ui.dialog_panel.offset_bottom = -18
	ui.dialog_panel.custom_minimum_size.y = 196
	_speaker_fill = SpotLight3D.new()
	_speaker_fill.name = "DialogueBounce"
	_speaker_fill.light_color = Color(1.0, 0.86, 0.69)
	_speaker_fill.spot_range = 4.0
	_speaker_fill.spot_angle = 52.0
	_speaker_fill.spot_attenuation = 1.3
	_speaker_fill.light_specular = 0.0
	_speaker_fill.shadow_enabled = true
	_speaker_fill.light_size = 0.1
	_speaker_fill.light_energy = 0.0
	add_child(_speaker_fill)
	ui.log_toggled.connect(func(_open): _sync_player())
	ui.pause_toggled.connect(func(_paused): _sync_player())
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	overlay = Overlay.new()
	report_sheet = Report.new()
	plan_board = Board.new()
	for modal in [overlay, report_sheet, plan_board]:
		modal.theme = ui.theme_res
		layer.add_child(modal)
		modal.hide()
	overlay.clue_found.connect(_clue_found)
	overlay.aligned_changed.connect(func(on):
		aligned = aligned or on
		if on: Story.clues["aligned"] = true)
	overlay.hint_requested.connect(func(): ui.show_toast(C17.viewer_hint(state()), 7.0))
	overlay.closed.connect(_viewer_closed)
	report_sheet.closed.connect(_resume)
	report_sheet.submitted.connect(_submit_report)
	plan_board.reaction.connect(func(seq): plan_board.hide(); _say(seq, "board_reaction"))
	plan_board.blocked.connect(func(card): plan_board.hide(); _say(C17.plan_blocked(card), "board_reaction"))
	plan_board.finished.connect(_finish_plan)
	_build_audio()
	ui.fade.color.a = 1.0
	_sync_player()
	await ui.fade_to(0.0, 1.1).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	await ui.show_caption(C17.intro_caption(), 2.4).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	_busy = false
	_say(C17.opening(), "opening")


func state() -> Dictionary:
	var result := Story.clues.duplicate(true)
	result.merge({"aligned": aligned, "residual_found": residual_found, "kit_checked": kit_checked,
		"report_done": report_done, "viewer_opens": viewer_opens}, true)
	return result


func _free() -> bool:
	return not get_tree().paused and not _busy and not ui.dialog_active() and not ui.log_open() and not overlay.visible and not report_sheet.visible and not plan_board.visible


func _sync_player() -> void:
	var free := _free()
	player.can_move = free and beat == Beat.INVESTIGATE
	player.can_look = free
	ui.hud.visible = not overlay.visible and not report_sheet.visible and not plan_board.visible and not ui.log_open()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if free else Input.MOUSE_MODE_VISIBLE
	if beat == Beat.INVESTIGATE:
		ui.set_objectives("[b]劍橋・1917[/b]\n核對 14 號星場的抄錄圖，交給 %s\n[color=#b8ad98]看片台 · 觀測日誌 · %s · 筆記本\nTab 對話紀錄[/color]" % [Cast.MENTOR, Cast.KIT])
	else:
		ui.set_objectives("")


func _process(delta: float) -> void:
	_light_t += delta
	# Slow overlapping waves: a quiet coal fire, without particles or shadow redraw.
	world.fire_light.light_energy = (0.48 if _daylight else 1.0) * (1.0 + 0.055 * sin(_light_t * 2.3) + 0.025 * sin(_light_t * 5.7))
	_clock_t += delta
	if _clock_t >= 1.0:
		_clock_t -= 1.0
		tick.play()
	if _free() and beat == Beat.INVESTIGATE:
		var target: Node = player.aimed_interactable()
		ui.set_prompt("［E］" + str(target.get_meta("prompt")) if target else "")
	else:
		ui.set_prompt("")


func _unhandled_input(event: InputEvent) -> void:
	if _free() and beat == Beat.INVESTIGATE and event.is_action_pressed("interact"):
		var target: Node = player.aimed_interactable()
		if target:
			get_viewport().set_input_as_handled()
			_interact(str(target.get_meta("interact_id")))


func _interact(id: String) -> void:
	click.play()
	match id:
		"lightbox":
			viewer_opens += 1
			overlay.open()
			_sync_player()
		"notebook":
			report_sheet.open(state())
			_sync_player()
		"kit":
			if aligned and not kit_checked:
				_say(C17.kit_double_check(), "double_check")
			elif _should_offer_kit_guess():
				guess_offered = true
				_say(C17.kit_guess(), "")
			else:
				_say(C17.kit_talk(state()), "")
		_:
			_say(C17.examine(id), "logbook" if id == "logbook" else "")


func _clue_found(id: String) -> void:
	Story.clues[id] = true
	if id == "residual":
		residual_found = true
	ui.show_toast(C17.viewer_feedback(id), 6.0)
	click.play()


func _viewer_closed() -> void:
	if _should_offer_kit_guess():
		guess_offered = true
		_say(C17.kit_guess(), "")
	else:
		_resume()


func _should_offer_kit_guess() -> bool:
	return viewer_opens > 0 and not guess_offered and not aligned and not Story.clues.get("log", false)


func _resume() -> void:
	_sync_player()


func _say(seq: Array, purpose: String) -> void:
	_pending = purpose
	ui.play(seq)
	_sync_player()


func _frame_speaker(speaker: String) -> void:
	_set_conversation(true)
	var actor: Node3D
	match speaker:
		Cast.KIT: actor = world.kit
		Cast.MENTOR: actor = world.mentor
		Cast.EDDINGTON: actor = world.eddington
	if not is_instance_valid(actor) or not actor.visible:
		# An unframed line (the player, an off-screen voice) returns to the
		# conversation lens instead of keeping a far speaker's long one.
		_last_speaker = ""
		if _lens_tween:
			_lens_tween.kill()
		if not is_equal_approx(player.camera.fov, 55.0):
			_lens_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			_lens_tween.tween_property(player.camera, "fov", 55.0, 0.4)
		return
	if _last_speaker == speaker and _camera_turn and _camera_turn.is_running():
		return
	_last_speaker = speaker
	if _camera_turn:
		_camera_turn.kill()
	var to_actor: Vector3 = actor.global_position - player.global_position
	if actor == world.kit:
		actor.rotation.y = atan2(-to_actor.x, -to_actor.z) + PI
	# Show the standing figure at conversation distance; keep the face in frame
	# when a player talks from close to the actor's collision capsule.
	var distance: float = Vector2(to_actor.x, to_actor.z).length()
	# Far speakers get a longer lens so they don't read small behind a near figure.
	if _lens_tween:
		_lens_tween.kill()
	_lens_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_lens_tween.tween_property(player.camera, "fov", lerpf(55.0, 40.0, smoothstep(2.5, 4.5, distance)), 0.4)
	var focus_height := lerpf(1.5, 1.1, smoothstep(1.0, 2.5, distance))
	var target := actor.global_position + Vector3(0, focus_height, 0)
	var direction: Vector3 = target - player.camera.global_position
	var yaw: float = player.yaw + wrapf(atan2(-direction.x, -direction.z) - player.yaw, -PI, PI)
	var pitch := atan2(direction.y, Vector2(direction.x, direction.z).length())
	_camera_turn = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_turn.tween_property(player, "yaw", yaw, 0.4)
	_camera_turn.tween_property(player, "pitch", pitch, 0.4)
	# A low-energy side bounce preserves the nose/cheek shadow; the desk lamp
	# and window carry the scene, rather than a camera-mounted face wash.
	_speaker_fill.position = actor.global_position + Vector3(1.15, 2.05, 0.7)
	_speaker_fill.look_at(actor.global_position + Vector3(0, 1.4, 0))
	_speaker_fill.light_color = Color(0.78, 0.85, 0.93) if _daylight else Color(1.0, 0.86, 0.69)
	_speaker_fill.light_energy = 0.28


func _set_conversation(active: bool) -> void:
	Figures.show_name_tags([world.kit, world.mentor, world.eddington], not active)
	if _conversation_active == active:
		return
	_conversation_active = active
	if _lens_tween:
		_lens_tween.kill()
	_lens_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_lens_tween.tween_property(player.camera, "fov", 55.0 if active else 72.0, 0.4)


func _dialogue_done(results: Dictionary) -> void:
	_set_conversation(false)
	if _camera_turn:
		_camera_turn.kill()
	_speaker_fill.light_energy = 0.0
	var purpose := _pending
	_pending = ""
	match purpose:
		"opening":
			beat = Beat.INVESTIGATE
		"logbook":
			Story.clues["log"] = true
		"double_check":
			kit_checked = true
			Story.clues["kit_checked"] = true
		"mentor_review":
			if results.get("revise_report", 1) == 0:
				beat = Beat.INVESTIGATE
				report_done = false
				report_sheet.open(state(), Story.report)
				_sync_player()
				return
			_say(C17.mentor_dyson(Story.report), "dyson")
			return
		"dyson":
			_interlude()
			return
		"exam":
			beat = Beat.PLAN
			_say(C17.plan_intro(), "plan_intro")
			return
		"plan_intro":
			plan_board.open()
		"board_reaction":
			plan_board.show()
		"plan_finish":
			beat = Beat.TRIAL
			_say(C17.trial_task(), "trial")
			return
		"trial":
			world.eddington.hide()
			_say(C17.mentor_after(Story.report), "mentor_after")
			return
		"mentor_after":
			_coda()
			return
		"coda":
			Story.kit_choice = int(results.get("kit_choice", 0))
			_montage()
			return
	_sync_player()


func _submit_report(report: Dictionary) -> void:
	Story.report = report.duplicate(true)
	Story.report["kit_checked"] = kit_checked
	Story.report["aligned"] = aligned
	if report.get("cause", "") == "accuse":
		Story.clues["accused_once"] = true
	report_done = true
	beat = Beat.MENTOR
	world.mentor.show()
	# Enter through the corridor, preserving the room builder's destination.
	var destination: Vector3 = world.mentor.position
	world.mentor.position = Vector3(3.7, 0, 2.4)
	_busy = true
	_sync_player()
	await create_tween().tween_property(world.mentor, "position", destination, 1.2).finished
	_busy = false

	_say(C17.mentor_review(Story.report), "mentor_review")


func _interlude() -> void:
	beat = Beat.INTERLUDE
	_busy = true
	_sync_player()
	await ui.fade_to(1.0).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	_daylight = true
	world.lamp.light_energy = 0.0
	world.floor_bounce.light_energy = 1.0
	world.floor_bounce.light_color = Color(0.73, 0.79, 0.85)
	world.window_light.light_energy = 2.1
	world.window_light.light_color = Color(0.72, 0.78, 0.82)
	world.window_glass.albedo_color = Color(0.42, 0.47, 0.51)
	world.environment.environment.ambient_light_energy = 0.82
	world.eddington.show()
	player.look_at_point(world.targets.lightbox)
	await ui.show_caption(C17.interlude_caption(), 2.4).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	await ui.fade_to(0.0).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	# A brief daylight establishing view makes the three-day change visible.
	await get_tree().create_timer(0.65).timeout
	_busy = false
	beat = Beat.EXAM
	_say(C17.eddington_exam(Story.report, state()), "exam")


func _finish_plan(ids: Array) -> void:
	Story.plan = ids.duplicate()
	plan_board.hide()
	_say(C17.plan_finish(Story.plan), "plan_finish")


func _coda() -> void:
	_busy = true
	beat = Beat.CODA
	_sync_player()
	await ui.fade_to(1.0, 0.6).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	world.mentor.hide()
	_daylight = false
	world.lamp.light_energy = 1.5
	world.floor_bounce.light_energy = 0.65
	world.floor_bounce.light_color = Color(0.55, 0.69, 0.86)
	world.window_light.light_energy = 1.1
	world.window_light.light_color = Color(0.48, 0.65, 0.82)
	world.window_glass.albedo_color = Color(0.12, 0.19, 0.23)
	world.environment.environment.ambient_light_energy = 0.62

	await ui.fade_to(0.0).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	_busy = false
	_say(C17.kit_coda(Story.report, state()), "coda")


func _montage() -> void:
	score.stop("cambridge_rain", 0.8)
	beat = Beat.MONTAGE
	_busy = true
	_sync_player()
	await ui.fade_to(1.0).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	for entry in C17.montage():
		var tag := "史實" if entry.tag == "HISTORICAL" else "虛構"
		await ui.show_caption(str(entry.t) + "\n\n（" + tag + "）", 3.2).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	Story.prologue_done = true
	beat = Beat.DONE
	get_tree().change_scene_to_file("res://scenes/departure.tscn")


func _audio(samples: PackedFloat32Array, db: float, loop := false) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = ExistingDirector._wav(samples, 22050, loop)
	p.volume_db = db
	add_child(p)
	return p


func _build_audio() -> void:
	var score_ready := Time.get_ticks_usec()
	score = ScorePlayer.new()
	add_child(score)
	score.warm(["cambridge_rain"])
	ui.log_toggled.connect(score.set_log_open)
	score.play("cambridge_rain", 1.1)
	print("[SCORE READY] scene=cambridge added_ms=%.3f" % [(Time.get_ticks_usec() - score_ready + ui.music_ready_usec) / 1000.0])
	var samples := PackedFloat32Array()
	for i in 700:
		var t := i / 22050.0
		samples.append(sin(t * TAU * 1700.0) * exp(-t * 180.0) * 0.6)
	tick = _audio(samples, -22.0)
	samples.clear()
	for i in 1800:
		var t := i / 22050.0
		samples.append((randf() - 0.5) * exp(-t * 90.0))
	click = _audio(samples, -13.0)
	samples.clear()
	var brown := 0.0
	for i in 22050 * 3:
		brown = clampf(brown + (randf() - 0.5) * 0.07, -1.0, 1.0) * 0.99
		samples.append(brown * 0.4 + (randf() - 0.5) * 0.05)
	_audio(samples, -21.0, true).play()
