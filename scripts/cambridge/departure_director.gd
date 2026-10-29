extends Node3D
## M2 staging only; all authored dialogue remains in Content.
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const ExistingDirector := preload("res://scripts/main.gd")
const Room := preload("res://scripts/cambridge/room_builder.gd")
const Player := preload("res://scripts/player.gd")
const UI := preload("res://scripts/ui.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")
const Content := preload("res://scripts/cambridge/content_departure.gd")
const Checklist := preload("res://scripts/cambridge/departure_checklist.gd")

enum Beat { OPENING, CHECKLIST, CHECKING, KIT, PROMISE, FAREWELL, MONTAGE, DONE }
var beat := Beat.OPENING
var world: Dictionary
var player
var ui
var checklist
var _pending := ""
var _busy := true
var _clock_t := 0.0
var _light_t := 0.0
var _camera_turn: Tween
var _speaker_fill: OmniLight3D
var _last_speaker := ""
var score: Node
var tick: AudioStreamPlayer
var street: AudioStreamPlayer
var keepsake: HBoxContainer


class LoupeIcon extends Control:
	func _draw() -> void:
		draw_circle(Vector2(16, 14), 10, Color(0.32, 0.40, 0.42, 0.6))
		draw_arc(Vector2(16, 14), 12, 0, TAU, 24, Color(0.72, 0.52, 0.25), 3.0, true)
		draw_line(Vector2(24, 23), Vector2(33, 33), Color(0.65, 0.46, 0.22), 5.0, true)


func _ready() -> void:
	ExistingDirector._ensure_inputs()
	world = Room.build(self, true)
	player = Player.new()
	player.position = world.spawn
	add_child(player)
	player.look_at_point(world.targets.kit)
	ui = UI.new()
	add_child(ui)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.hide_title()
	ui.pause_enabled = true
	ui.quit_pressed.connect(func(): get_tree().quit())
	ui.restart_pressed.connect(func(_same):
		get_tree().paused = false
		Story.bond_tone = ""
		Story.slip_fix = -1
		Story.departure_done = false
		get_tree().reload_current_scene())
	ui.dialogue_done.connect(_dialogue_done)
	ui.dialogue_entry.connect(_frame_speaker)
	ui.log_toggled.connect(func(_open): _sync_player())
	ui.pause_toggled.connect(func(_paused): _sync_player())
	ui.dialog_panel.offset_top = -214
	ui.dialog_panel.offset_bottom = -18
	ui.dialog_panel.custom_minimum_size.y = 196
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	checklist = Checklist.new()
	checklist.theme = ui.theme_res
	layer.add_child(checklist)
	checklist.row_requested.connect(_read_row)
	checklist.completed.connect(_checked)
	checklist.closed.connect(func(): beat = Beat.KIT; _sync_player())
	_speaker_fill = OmniLight3D.new()
	_speaker_fill.name = "DepartureDialogueBounce"
	_speaker_fill.light_color = Color(1.0, 0.86, 0.69)
	_speaker_fill.omni_range = 4.0
	_speaker_fill.omni_attenuation = 1.3
	_speaker_fill.light_specular = 0.0
	_speaker_fill.light_energy = 0.0
	add_child(_speaker_fill)
	_build_keepsake()
	_build_audio()
	ui.fade.color.a = 1.0
	_sync_player()
	await ui.fade_to(0.0, 1.1).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	await ui.show_caption(Content.intro_caption(), 2.4).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	_busy = false
	_say(Content.opening(), "opening")


func _free() -> bool:
	return not get_tree().paused and not _busy and not ui.dialog_active() and not ui.log_open() and not checklist.visible


func _sync_player() -> void:
	var free := _free()
	checklist.input_blocked = get_tree().paused or _busy or ui.log_open() or ui.dialog_active()
	player.can_move = free and beat in [Beat.CHECKLIST, Beat.KIT, Beat.FAREWELL]
	player.can_look = free
	ui.hud.visible = not checklist.visible and not ui.log_open() and not ui.dialog_active() and not _busy
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if free else Input.MOUSE_MODE_VISIBLE
	var objective := ""
	match beat:
		Beat.CHECKLIST: objective = "走到看片台，核對最後一頁。"
		Beat.KIT: objective = "清單收好了。和 Kit 說說話。"
		Beat.FAREWELL: objective = "Ashby 先生在走廊等你。"
	ui.set_objectives("[b]劍橋・1919 年 3 月[/b]\n" + objective if objective != "" else "")


func _process(delta: float) -> void:
	_light_t += delta
	var flicker := 1.0 + 0.04 * sin(_light_t * 2.3) + 0.02 * sin(_light_t * 5.7)
	world.fire_light.light_energy = 0.8 * flicker
	Room.glow_embers(world.ember_mat, flicker, _light_t)
	Room.swing_pendulum(world.pendulum, _light_t)
	_clock_t += delta
	if _clock_t >= 1.0:
		_clock_t -= 1.0
		tick.play()
	if _free():
		var target: Node = player.aimed_interactable()
		var id := str(target.get_meta("interact_id")) if target else ""
		var available := _available(id)
		ui.set_prompt("［E］" + str(target.get_meta("prompt")) if available else "")
	else:
		ui.set_prompt("")


func _available(id: String) -> bool:
	return (beat == Beat.CHECKLIST and id == "lightbox") or (beat == Beat.KIT and id == "kit") or (beat == Beat.FAREWELL and id in ["mentor", "workbook"])


func _unhandled_input(event: InputEvent) -> void:
	if _free() and event.is_action_pressed("interact"):
		var target: Node = player.aimed_interactable()
		if target and _available(str(target.get_meta("interact_id"))):
			get_viewport().set_input_as_handled()
			_interact(str(target.get_meta("interact_id")))


func _interact(id: String) -> void:
	match id:
		"lightbox":
			beat = Beat.CHECKING
			checklist.open()
		"kit": _say(Content.before_closing(), "bond")
		"mentor": _say(Content.mentor_farewell(Story.slip_fix), "gift")
		"workbook":
			_frame_point(world.targets.workbook)
			ui.show_toast("1919 年 5 月 29 日", 4.0)
	_sync_player()


func _read_row(_index: int) -> void:
	checklist.begin_read()
	_say(Content.kit_reads(checklist.entries[checklist.active_index]), "read")


func _checked(result: Dictionary) -> void:
	_say(Content.slip_found(result.caught_by_player, result.false_alarm), "slip")


func _say(seq: Array, purpose: String) -> void:
	_pending = purpose
	ui.play(seq)
	_sync_player()


func _dialogue_done(results: Dictionary) -> void:
	if _camera_turn:
		_camera_turn.kill()
	_speaker_fill.light_energy = 0.0
	var purpose := _pending
	_pending = ""
	match purpose:
		"opening": beat = Beat.CHECKLIST
		"read": checklist.allow_mark()
		"slip":
			Story.slip_fix = int(results.get("slip_fix", 0))
			checklist.show_correction(Story.slip_fix)
			# Reading time for the changed paper; progress always requires a click.
			await get_tree().create_timer(0.85, false).timeout
			checklist.continue_btn.disabled = false
		"bond":
			Story.bond_tone = "close" if int(results.get("bond", 0)) == 0 else "warm"
			beat = Beat.PROMISE
			_say(Content.sky_promise(Story.bond_tone), "promise")
			return
		"promise": beat = Beat.FAREWELL
		"gift":
			keepsake.show()
			_busy = true
			_sync_player()
			await get_tree().create_timer(1.8, false).timeout
			_montage()
			return
	_sync_player()


func _frame_speaker(speaker: String) -> void:
	# The authored workbook gesture gets a prop shot, then conversation returns to Kit.
	var entry: Dictionary = ui._seq[ui._seq_i]
	if _pending == "promise" and str(entry.get("t", "")).contains("翻開工作簿"):
		world.workbook.open_workbook()
		_last_speaker = ""
		_frame_point(world.targets.workbook)
		return
	var actor: Node3D
	match speaker:
		Cast.KIT: actor = world.kit
		Cast.MENTOR: actor = world.mentor
	if not is_instance_valid(actor) or not actor.visible:
		return
	if _last_speaker == speaker and _camera_turn and _camera_turn.is_running():
		return
	_last_speaker = speaker
	var to_actor: Vector3 = actor.global_position - player.global_position
	actor.rotation.y = atan2(-to_actor.x, -to_actor.z) + PI
	var distance := Vector2(to_actor.x, to_actor.z).length()
	var focus_height := lerpf(1.5, 0.85, smoothstep(1.0, 2.5, distance))
	_frame_point(actor.global_position + Vector3(0, focus_height, 0))
	var toward_camera: Vector3 = (player.global_position - actor.global_position).normalized()
	_speaker_fill.position = actor.global_position + toward_camera * 1.0 + Vector3(0, 1.5, 0)
	_speaker_fill.light_energy = 0.85


func _frame_point(target: Vector3) -> void:
	if _camera_turn:
		_camera_turn.kill()
	var direction: Vector3 = target - player.camera.global_position
	var yaw: float = player.yaw + wrapf(atan2(-direction.x, -direction.z) - player.yaw, -PI, PI)
	var pitch := atan2(direction.y, Vector2(direction.x, direction.z).length())
	_camera_turn = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_turn.tween_property(player, "yaw", yaw, 0.4)
	_camera_turn.tween_property(player, "pitch", pitch, 0.4)


func _build_keepsake() -> void:
	keepsake = HBoxContainer.new()
	keepsake.position = Vector2(28, 90)
	var icon := LoupeIcon.new()
	icon.custom_minimum_size = Vector2(42, 40)
	keepsake.add_child(icon)
	var label := Label.new()
	label.text = Cast.MENTOR_GIFT
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", UI.PAPER)
	keepsake.add_child(label)
	ui.get_child(0).add_child(keepsake)
	keepsake.hide()


func _montage() -> void:
	score.play("departure_motif", 0.6)
	beat = Beat.MONTAGE
	_busy = true
	_sync_player()
	await ui.fade_to(1.0).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	keepsake.hide()
	for entry in Content.montage():
		var tag := "史實" if entry.tag == "HISTORICAL" else "虛構"
		await ui.show_caption(str(entry.t) + "\n\n（" + tag + "）", 3.2).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	Story.departure_done = true
	Story.from_prologue = true
	beat = Beat.DONE
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _audio(samples: PackedFloat32Array, db: float, loop := false) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.stream = ExistingDirector._wav(samples, 22050, loop)
	audio.volume_db = db
	add_child(audio)
	return audio


func _build_audio() -> void:
	var score_ready := Time.get_ticks_usec()
	score = ScorePlayer.new()
	add_child(score)
	score.warm(["departure_motif"])
	ui.log_toggled.connect(score.set_log_open)
	print("[SCORE READY] scene=departure added_ms=%.3f" % [(Time.get_ticks_usec() - score_ready + ui.music_ready_usec) / 1000.0])
	var samples := PackedFloat32Array()
	for i in 700:
		var t := i / 22050.0
		samples.append(sin(t * TAU * 1700.0) * exp(-t * 180.0) * 0.6)
	tick = _audio(samples, -26.0)
	samples.clear()
	var brown := 0.0
	for i in 22050 * 4:
		brown = clampf(brown + (randf() - 0.5) * 0.025, -1.0, 1.0) * 0.99
		samples.append(brown * 0.3)
	street = _audio(samples, -32.0, true)
	street.play()
