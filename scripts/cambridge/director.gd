extends Node3D
## M1 sequence orchestration. Text and replaceable cast stay in C17/Cast.
const ExistingDirector := preload("res://scripts/main.gd")
const Room := preload("res://scripts/cambridge/room_builder.gd")
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
var tick: AudioStreamPlayer
var click: AudioStreamPlayer


func _ready() -> void:
	ExistingDirector._ensure_inputs()
	Story.from_prologue = false
	Story.prologue_done = false
	Story.clues = {}
	Story.report = {}
	Story.plan = []
	Story.kit_choice = -1
	world = Room.build(self)
	player = Player.new()
	player.position = world.spawn
	add_child(player)
	player.look_at_point(world.targets.lightbox)
	ui = UI.new()
	add_child(ui)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.hide_title()
	ui.pause_enabled = true
	ui.quit_pressed.connect(func(): get_tree().quit())
	ui.restart_pressed.connect(func(_same): get_tree().paused = false; get_tree().reload_current_scene())
	ui.dialogue_done.connect(_dialogue_done)
	ui.log_toggled.connect(func(_open): _sync_player())
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
	await ui.fade_to(0.0, 1.1).finished
	await ui.show_caption(C17.intro_caption(), 2.4).finished
	_busy = false
	_say(C17.opening(), "opening")


func state() -> Dictionary:
	var result := Story.clues.duplicate(true)
	result.merge({"aligned": aligned, "residual_found": residual_found, "kit_checked": kit_checked,
		"report_done": report_done, "viewer_opens": viewer_opens}, true)
	return result


func _free() -> bool:
	return not _busy and not ui.dialog_active() and not ui.log_open() and not overlay.visible and not report_sheet.visible and not plan_board.visible


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
			elif viewer_opens > 0 and not guess_offered:
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
	if viewer_opens > 0 and not guess_offered:
		guess_offered = true
		_say(C17.kit_guess(), "")
	else:
		_resume()


func _resume() -> void:
	_sync_player()


func _say(seq: Array, purpose: String) -> void:
	_pending = purpose
	ui.play(seq)
	_sync_player()


func _dialogue_done(results: Dictionary) -> void:
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
				report_sheet.open(state())
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
	player.look_at_point(world.mentor.position + Vector3(0, 1.5, 0))
	_say(C17.mentor_review(Story.report), "mentor_review")


func _interlude() -> void:
	beat = Beat.INTERLUDE
	_busy = true
	_sync_player()
	await ui.fade_to(1.0).finished
	world.lamp.light_energy = 0.0
	world.window_light.light_energy = 1.4
	world.eddington.show()
	player.look_at_point(world.eddington.position + Vector3(0, 1.5, 0))
	await ui.show_caption(C17.interlude_caption(), 2.4).finished
	await ui.fade_to(0.0).finished
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
	await ui.fade_to(1.0, 0.6).finished
	world.mentor.hide()
	world.lamp.light_energy = 1.1
	world.window_light.light_energy = 0.4
	player.look_at_point(world.kit.position + Vector3(0, 1.5, 0))
	await ui.fade_to(0.0).finished
	_busy = false
	_say(C17.kit_coda(Story.report, state()), "coda")


func _montage() -> void:
	beat = Beat.MONTAGE
	_busy = true
	_sync_player()
	await ui.fade_to(1.0).finished
	for entry in C17.montage():
		await ui.show_caption(str(entry.t) + "\n（" + str(entry.tag) + "）", 2.5).finished
	Story.prologue_done = true
	Story.from_prologue = true
	beat = Beat.DONE
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _audio(samples: PackedFloat32Array, db: float, loop := false) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = ExistingDirector._wav(samples, 22050, loop)
	p.volume_db = db
	add_child(p)
	return p


func _build_audio() -> void:
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
