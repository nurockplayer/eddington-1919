extends Node3D
## Conversion arc move D — the October 1919 Cambridge epilogue. The 1917 room, with
## Ashby and the orrery, after the Príncipe coda and before the ending screen.

const Settings := preload("res://scripts/settings.gd")
const Prompts := preload("res://scripts/prompts.gd")
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const ExistingDirector := preload("res://scripts/main.gd")
const Room := preload("res://scripts/cambridge/room_builder.gd")
const Player := preload("res://scripts/player.gd")
const UI := preload("res://scripts/ui.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")
const Content := preload("res://scripts/cambridge/content_epilogue.gd")
const ChartOverlay := preload("res://scripts/cambridge/epilogue_chart.gd")
const Ending := preload("res://scripts/ending.gd")

enum Beat { OPENING, LETTER, CHART, WEIGHT, LEDGER, ORRERY, ORRERY_TALK, CLOSE, ENDING }
var beat := Beat.OPENING
var world: Dictionary
var player
var ui
var chart
var _pending := ""
var _busy := true
var _clock_t := 0.0
var _light_t := 0.0
var _orrery_camera: Camera3D
var _camera_turn: Tween
var _speaker_fill: OmniLight3D
var _last_speaker := ""
var score: Node
var tick: AudioStreamPlayer
var street: AudioStreamPlayer


func _ready() -> void:
	ExistingDirector._ensure_inputs()
	world = Room.build(self, false)
	world.letter_prop.position = Vector3(-0.6, 0.845, 0.55)
	world.letter_hotspot.position = Vector3(-0.6, 0.86, 0.55)
	world.targets.letter = world.letter_hotspot.position
	# October 1919: Kit has not come back from the observatory; the desk is Ashby's.
	world.kit.visible = false
	var kit_shape := world.kit.get_meta("room_collision_shape") as CollisionShape3D
	if kit_shape:
		kit_shape.disabled = true
	world.mentor.visible = true
	# The 1917 copyist's empty-desk volume covers the letter from the south; 1919 has
	# no use for it, and its collider would take the ray before the letter does.
	_disable_hotspot("empty_desk")
	player = Player.new()
	player.position = world.spawn
	add_child(player)
	player.look_at_point(world.targets.notebook)
	ui = UI.new()
	add_child(ui)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.hide_title()
	ui.pause_enabled = true
	ui.quit_pressed.connect(func(): get_tree().quit())
	ui.title_pressed.connect(_return_to_title)
	ui.restart_pressed.connect(_restart)
	ui.dialogue_done.connect(_dialogue_done)
	ui.dialogue_entry.connect(_frame_speaker)
	ui.log_toggled.connect(func(_open): _sync_player())
	ui.pause_toggled.connect(func(_paused): _sync_player())
	ui.text_size_button.pressed.connect(func(): chart.refresh_fonts())
	ui.dialog_panel.offset_top = -214
	ui.dialog_panel.offset_bottom = -18
	ui.dialog_panel.custom_minimum_size.y = 196
	var layer := CanvasLayer.new()
	layer.layer = 9
	add_child(layer)
	chart = ChartOverlay.new()
	chart.theme = ui.theme_res
	layer.add_child(chart)
	chart.completed.connect(_chart_completed)
	_speaker_fill = OmniLight3D.new()
	_speaker_fill.name = "EpilogueDialogueBounce"
	_speaker_fill.light_color = Color(1.0, 0.86, 0.69)
	_speaker_fill.omni_range = 4.0
	_speaker_fill.omni_attenuation = 1.3
	_speaker_fill.light_specular = 0.0
	_speaker_fill.light_energy = 0.0
	add_child(_speaker_fill)
	_set_prompt_meta("letter", "讀 Dyson 的信")
	_set_prompt_meta("orrery", "看太陽系儀")
	Settings.apply_quality(get_tree())
	_build_audio()
	ui.fade.color.a = 1.0
	_sync_player()
	await ui.fade_to(0.0, 1.1).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	await ui.show_caption(Content.intro_caption(), 2.4).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	_busy = false
	_say(Content.opening(), "opening")


## Removes an inactive hotspot's collider so it cannot take the interaction ray.
func _disable_hotspot(id: String) -> void:
	for body in find_children("*", "StaticBody3D", true, false):
		if str(body.get_meta("interact_id", "")) != id:
			continue
		body.collision_layer = 0
		for child in body.get_children():
			if child is CollisionShape3D:
				(child as CollisionShape3D).disabled = true


func _set_prompt_meta(id: String, prompt: String) -> void:
	for body in find_children("*", "StaticBody3D", true, false):
		if str(body.get_meta("interact_id", "")) == id:
			body.set_meta("prompt", prompt)


func _free() -> bool:
	return not get_tree().paused and not _busy and not ui.dialog_active() and not ui.log_open() and not chart.visible and beat != Beat.ENDING


func _sync_player() -> void:
	var free := _free()
	chart.input_blocked = get_tree().paused or _busy or ui.log_open() or ui.dialog_active()
	player.can_move = free and beat in [Beat.LETTER, Beat.ORRERY]
	player.can_look = free
	ui.hud.visible = not chart.visible and not ui.log_open() and not ui.dialog_active() and not _busy and beat != Beat.ENDING
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if free else Input.MOUSE_MODE_VISIBLE
	var objective := ""
	match beat:
		Beat.LETTER: objective = "讀桌上 Dyson 的信。"
		Beat.ORRERY: objective = "太陽系儀還在架上。"
	ui.set_objectives("[b]劍橋・1919 年 10 月[/b]\n" + objective if objective != "" else "")


func _process(delta: float) -> void:
	_light_t += delta
	var flicker := 1.0 + 0.04 * sin(_light_t * 2.3) + 0.02 * sin(_light_t * 5.7)
	world.fire_light.light_energy = 0.8 * flicker
	Room.glow_embers(world.ember_mat, flicker, _light_t)
	Room.swing_pendulum(world.pendulum, _light_t)
	Room.StarDecor.turn_orrery(world.orrery, _light_t)
	_clock_t += delta
	if _clock_t >= 1.0:
		_clock_t -= 1.0
		tick.play()
	if _free():
		var target: Node = player.aimed_interactable()
		var id := str(target.get_meta("interact_id")) if target else ""
		var available := _available(id)
		ui.set_prompt("［" + Prompts.key("interact") + "］" + str(target.get_meta("prompt")) if available else "")
	else:
		ui.set_prompt("")


func _available(id: String) -> bool:
	return (beat == Beat.LETTER and id == "letter") or (beat == Beat.ORRERY and id in ["orrery", "mentor"])


func _unhandled_input(event: InputEvent) -> void:
	if _free() and event.is_action_pressed("interact"):
		var target: Node = player.aimed_interactable()
		if target and _available(str(target.get_meta("interact_id"))):
			get_viewport().set_input_as_handled()
			_interact(str(target.get_meta("interact_id")))


func _interact(id: String) -> void:
	match id:
		"letter":
			_say(Content.letter(), "letter")
		"orrery":
			_orrery_camera = Room.StarDecor.orrery_closeup(self, world.orrery)
			beat = Beat.ORRERY_TALK
			_say(Content.orrery_talk(Content.suspect_text(Story.mercury_suspect)), "orrery_talk")
		"mentor":
			# The objective already says where to go; Ashby repeats it without new prose.
			ui.show_toast("太陽系儀還在架上。", 3.0)
	_sync_player()


func _chart_completed() -> void:
	chart.hide()
	beat = Beat.WEIGHT
	_say(Content.weight(), "weight")


func _say(seq: Array, purpose: String) -> void:
	_pending = purpose
	ui.play(seq)
	_sync_player()


func _store(key: String, value) -> void:
	if not Story.runs.is_empty():
		Story.runs.back()[key] = value


func _dialogue_done(results: Dictionary) -> void:
	if _camera_turn:
		_camera_turn.kill()
	_speaker_fill.light_energy = 0.0
	var purpose := _pending
	_pending = ""
	match purpose:
		"opening":
			beat = Beat.LETTER
		"letter":
			beat = Beat.CHART
			chart.open(Story.runs.back())
		"weight":
			var choice := int(results.get("astro_weight", 0))
			_store("astro_weight", choice)
			beat = Beat.LEDGER
			var seq: Array = Content.weight_reply(choice)
			seq.append_array(Content.ledger(Story.runs.back(), Story.bet_1917, Story.bet))
			_say(seq, "ledger")
			return
		"ledger":
			beat = Beat.ORRERY
		"orrery_talk":
			_store("click", int(results.get("click", 0)))
			_say(Content.click_reply(int(results.get("click", 0))), "click_reply")
			return
		"click_reply":
			Room.StarDecor.end_orrery_closeup(_orrery_camera, player.camera)
			_orrery_camera = null
			_say(Content.final_reason(), "final_reason")
			return
		"final_reason":
			var choice := int(results.get("final_reason", -1))
			_store("final_reason", choice)
			var choices: Array = Content.final_reason()[0].choices
			_store("final_reason_text", str(choices[choice]) if choice >= 0 and choice < choices.size() else "")
			_say(Content.final_reply(choice) + Content.close(), "close")
			return
		"close":
			_end_epilogue()
			return
	_sync_player()


func _end_epilogue() -> void:
	beat = Beat.ENDING
	_busy = true
	_sync_player()
	await ui.fade_to(1.0, 1.2).set_pause_mode(Tween.TWEEN_PAUSE_STOP).finished
	_busy = false
	score.play("coda_resolution", 0.6)
	var ending: Dictionary = Ending.build(Story.runs.back(), Ending.story_view(Story))
	ui.show_ending(ending.title, ending.body, ending.history, ending.review, ending.telegram,
		Story.ending_plate, Story.ending_plate_caption)
	ui.pause_enabled = false
	ui.fade.color.a = 0.0
	ui.hud.visible = false
	ui.set_prompt("")
	player.can_move = false
	player.can_look = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _restart(same_sky: bool) -> void:
	if beat == Beat.ENDING:
		var back: Dictionary = Story.runs.back()
		ExistingDirector.prepare_replay(int(back.seed) if same_sky else randi() % 100000, same_sky, true)
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/main.tscn")
		return
	get_tree().paused = false
	if not Story.runs.is_empty():
		for key in ["astro_weight", "click", "final_reason"]:
			Story.runs.back().erase(key)
	get_tree().reload_current_scene()


func _return_to_title() -> void:
	Story.reset()
	UI.history.clear()
	ExistingDirector.prepare_title()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _frame_speaker(speaker: String) -> void:
	var actor: Node3D
	match speaker:
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


func _audio(samples: PackedFloat32Array, db: float, loop := false) -> AudioStreamPlayer:
	var audio := AudioStreamPlayer.new()
	audio.bus = "SFX"
	audio.stream = ExistingDirector._wav(samples, 22050, loop)
	audio.volume_db = db
	add_child(audio)
	return audio


func _build_audio() -> void:
	var score_ready := Time.get_ticks_usec()
	score = ScorePlayer.new()
	add_child(score)
	score.warm(["coda_resolution"])
	ui.log_toggled.connect(score.set_log_open)
	print("[SCORE READY] scene=epilogue added_ms=%.3f" % [(Time.get_ticks_usec() - score_ready + ui.music_ready_usec) / 1000.0])
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
