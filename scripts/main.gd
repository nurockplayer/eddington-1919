extends Node3D
## Game director for the slice: phases, interactions, and the loop
## prepare → expose through cloud → inspect plates → judge → reaction.

const Sim := preload("res://scripts/eclipse_sim.gd")
const World := preload("res://scripts/world_builder.gd")
const Player := preload("res://scripts/player.gd")
const UI := preload("res://scripts/ui.gd")
const Content := preload("res://scripts/content.gd")
const Judgment := preload("res://scripts/judgment.gd")
const PlateRender := preload("res://scripts/plate_render.gd")
const Look := preload("res://scripts/look.gd")
const SKY_SHADER := preload("res://shaders/eclipse_sky.gdshader")
const DepartureWorkbook := preload("res://scripts/cambridge/departure_props.gd")
const DepartureContent := preload("res://scripts/cambridge/content_departure.gd")
const CodaContent := preload("res://scripts/content_coda.gd")

enum Phase { TITLE, PREP, TOTALITY, NIGHT, ENDING, CODA }
enum CodaStep { OPENING, WORKBOOK, LOUPE, KIT, FADING }

const PREP_S := 150.0            # real seconds of preparation (paused while talking)
const HOLD := {"drive": 3.0, "chronometer": 4.0, "plate_box": 1.2}

static var next_seed := -1

var sim
var ui
var player
var world: Dictionary
var phase := Phase.TITLE
var prep_left := PREP_S
var t_game := 0.0                # totality clock, game-seconds
var change_left := 0.0           # plate change in progress
var plates_left := 0
var tot_done := false
var hold_t := 0.0
var hold_id := ""
var met_cottingham := false
var plate_textures: Array = []
var comparison_tex: Texture2D
var _tick_acc := 0.0
var _warned_end := false
var _glanced := false
var _busy := false               # in a scripted transition
var _pending := ""               # what the current dialogue is for

var sky_mat: ShaderMaterial
var env: Environment
var sun: DirectionalLight3D
var audio_tick: AudioStreamPlayer
var audio_click: AudioStreamPlayer
var audio_amb: AudioStreamPlayer
var bot: Node
var _look_sun := 1.0             # art-look gains (scripts/look.gd); 1.0 with --no-grade
var _look_ambient := 1.0
var _departure_workbook_seen := false
var _came_from_departure := false
var _night_departure_workbook: Node3D
var coda_step := CodaStep.OPENING
var _camera_turn: Tween
var _coda_highlight: OmniLight3D
var _coda_transition: Tween


func _ready() -> void:
	_ensure_inputs()
	_came_from_departure = Story.from_prologue
	if not _came_from_departure:
		Story.reset()
	var args := _user_args()
	# A restart's chosen sky wins over the command line, which only seeds the first run.
	var seed_ := next_seed if next_seed >= 0 else int(args.get("seed", "-1"))
	if seed_ < 0:
		seed_ = randi() % 100000
	sim = Sim.new(seed_)
	_build_environment()
	var wb = World.new(self)
	wb.look = not args.has("no-grade")
	world = wb.build()
	if Story.departure_done or _came_from_departure:
		_add_departure_loupe(wb)
	world.eddington.rotation.y = PI
	player = Player.new()
	player.position = Vector3(2.6, 0.05, 4.2)
	add_child(player)
	player.yaw = deg_to_rad(20)
	ui = UI.new()
	add_child(ui)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	ui.start_pressed.connect(_start_game)
	ui.prologue_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/cambridge.tscn"))
	ui.log_toggled.connect(func(_open): _sync_player_input())
	ui.pause_toggled.connect(func(_paused): _sync_player_input())
	ui.log_toggled.connect(_sync_coda_log)
	ui.quit_pressed.connect(func(): get_tree().quit())
	ui.restart_pressed.connect(_restart)
	ui.dialogue_done.connect(_on_dialogue_done)
	ui.plate_toggled.connect(_on_plate_toggled)
	ui.measure_pressed.connect(_on_measure)
	ui.reselect_pressed.connect(_on_reselect)
	ui.report_pressed.connect(_on_report)
	ui.viewer_closed.connect(_on_viewer_closed)
	_build_audio()
	player.can_move = false
	player.can_look = false
	ui.set_objectives("")
	ui.hud.visible = false
	_update_sky_prep()
	if Story.from_prologue:
		Story.from_prologue = false
		_start_game()
		ui.show_caption("1919 年 5 月 29 日・普林西比", 2.4)
	if args.has("prologue-autoplay") and not Story.prologue_done:
		var prologue_bot: Script = load("res://tests/prologue_bot.gd")
		if prologue_bot:
			var runner: Node = prologue_bot.new()
			runner.main = self
			runner.scenario = args["prologue-autoplay"]
			runner.shots_dir = args.get("shots", "")
			get_tree().root.add_child.call_deferred(runner)
	if args.has("benchmark"):
		# tests/ is excluded from exports, so in a build this flag is ignored and the game runs normally.
		var bench_script: Script = load("res://tests/benchmark.gd")
		if bench_script == null:
			push_warning("benchmark unavailable in this build")
		else:
			var bench: Node = bench_script.new()
			bench.main = self
			# DirAccess.make_dir_recursive_absolute() needs an absolute path: resolve
			# res:// and repo-relative arguments (e.g. art/validation/x) against the project.
			var out: String = args.benchmark
			if out.begins_with("res://"):
				out = ProjectSettings.globalize_path(out)
			elif not out.is_absolute_path():
				out = ProjectSettings.globalize_path("res://" + out)
			bench.out_dir = out
			add_child(bench)
			return
	if args.has("autoplay"):
		var bot_script: Script = load("res://tests/autoplay_bot.gd")
		if bot_script == null:
			push_warning("autoplay unavailable in this build")
			return
		bot = bot_script.new()
		bot.main = self
		bot.scenario = args.autoplay
		bot.shots_dir = args.get("shots", "")
		add_child(bot)


func _user_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return out


static func _ensure_inputs() -> void:
	var map := {
		"move_forward": [KEY_W], "move_back": [KEY_S], "move_left": [KEY_A], "move_right": [KEY_D],
		"look_left": [KEY_LEFT], "look_right": [KEY_RIGHT], "look_up": [KEY_UP], "look_down": [KEY_DOWN],
		"run": [KEY_SHIFT], "interact": [KEY_E], "shutter": [KEY_SPACE], "pause": [KEY_ESCAPE],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
			for k in map[action]:
				var ev := InputEventKey.new()
				ev.physical_keycode = k
				InputMap.action_add_event(action, ev)
	var mb := InputEventMouseButton.new()
	mb.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event("shutter", mb):
		InputMap.action_add_event("shutter", mb)


# ------------------------------------------------------------------ Environment

func _build_environment() -> void:
	sky_mat = ShaderMaterial.new()
	sky_mat.shader = SKY_SHADER
	sky_mat.set_shader_parameter("cloud_tex", ImageTexture.create_from_image(sim.cloud_img))
	sky_mat.set_shader_parameter("wind", sim.wind)
	sky_mat.set_shader_parameter("cloud_scale", sim.CLOUD_SCALE)
	sky_mat.set_shader_parameter("sun_dir", sim.sun_dir)
	sky_mat.set_shader_parameter("sun_r", sim.SUN_R)
	sky_mat.set_shader_parameter("star_pos", sim.star_offsets)
	var mags := PackedFloat32Array()
	for i in sim.STAR_COUNT:
		mags.append(1.0 - i * 0.06)
	sky_mat.set_shader_parameter("star_mag", mags)
	var sky := Sky.new()
	sky.sky_material = sky_mat
	sky.process_mode = Sky.PROCESS_MODE_REALTIME
	sky.radiance_size = Sky.RADIANCE_SIZE_256
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_sky_contribution = 0.6
	env.ambient_light_color = Color(0.55, 0.57, 0.6)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_hdr_threshold = 1.2
	env.fog_enabled = true
	env.fog_density = 0.0035
	env.fog_light_color = Color(0.62, 0.65, 0.68)
	env.fog_sky_affect = 0.0
	if not _user_args().has("no-grade"):
		Look.apply_grade(env)
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, -sim.sun_dir, Vector3.UP)
	sun.shadow_enabled = true
	sun.light_color = Color(1.0, 0.96, 0.88)
	if not _user_args().has("no-grade"):
		Look.apply_cinematic(env, sun, sky_mat)
		_look_sun = Look.SUN_GAIN
		_look_ambient = Look.AMBIENT_GAIN


## Fraction of the solar disc not covered by the Moon for a contact value.
func _crescent(contact: float) -> float:
	var s := (1.0 - contact) * 2.1
	if s >= 2.0:
		return 1.0
	var overlap := 2.0 * acos(s / 2.0) - (s / 2.0) * sqrt(4.0 - s * s)
	return clampf(1.0 - overlap / PI, 0.0, 1.0)


func _apply_light(contact: float, darkness: float, cloud_t: float, night: float) -> void:
	sky_mat.set_shader_parameter("contact", contact)
	sky_mat.set_shader_parameter("darkness", darkness)
	sky_mat.set_shader_parameter("cloud_time", cloud_t)
	sky_mat.set_shader_parameter("night", night)
	sky_mat.set_shader_parameter("star_vis", clampf((darkness - 0.85) / 0.15, 0.0, 1.0) * (1.0 - night))
	var dens: float = sim.cloud_over_sun(cloud_t)
	var vis := _crescent(contact) * (1.0 - darkness)
	sun.light_energy = (0.15 + 1.4 * vis * (1.0 - dens * 0.85)) * (1.0 - night) * _look_sun
	if darkness > 0.95 or night > 0.5:
		sun.light_energy = 0.0
	var amb_day := Color(0.55, 0.57, 0.6)
	var amb_tot := Color(0.10, 0.11, 0.17)
	var amb_night := Color(0.03, 0.035, 0.05)
	env.ambient_light_color = amb_day.lerp(amb_tot, darkness).lerp(amb_night, night)
	env.ambient_light_energy = lerpf(1.0, 0.55, darkness) * _look_ambient
	env.fog_light_color = Color(0.62, 0.65, 0.68).lerp(Color(0.07, 0.08, 0.12), maxf(darkness, night))


func _update_sky_prep() -> void:
	var f := 1.0 - prep_left / PREP_S
	var contact := lerpf(0.62, 0.985, f)
	var darkness := pow(f, 3.0) * 0.45
	_apply_light(contact, darkness, -prep_left, 0.0)


# ------------------------------------------------------------------------ Audio

static func _wav(samples: PackedFloat32Array, rate := 22050, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_end = samples.size()
	return w


func _build_audio() -> void:
	var tick := PackedFloat32Array()
	for i in 700:
		var t := i / 22050.0
		tick.append(sin(t * TAU * 1900.0) * exp(-t * 180.0) * 0.6 + (randf() - 0.5) * exp(-t * 400.0) * 0.4)
	audio_tick = AudioStreamPlayer.new()
	audio_tick.stream = _wav(tick)
	audio_tick.volume_db = -8.0
	add_child(audio_tick)
	var click := PackedFloat32Array()
	for i in 2200:
		var t := i / 22050.0
		click.append((randf() - 0.5) * exp(-t * 60.0) + sin(t * TAU * 220.0) * exp(-t * 40.0) * 0.5)
	audio_click = AudioStreamPlayer.new()
	audio_click.stream = _wav(click)
	audio_click.volume_db = -4.0
	add_child(audio_click)
	# Soft wind / dripping-leaves bed (brown noise loop).
	var amb := PackedFloat32Array()
	var b := 0.0
	for i in 22050 * 4:
		b = clampf(b + (randf() - 0.5) * 0.06, -1.0, 1.0) * 0.996
		var drip := 0.0
		if randf() < 0.0004:
			drip = 0.5
		amb.append(b * 0.5 + drip)
	audio_amb = AudioStreamPlayer.new()
	audio_amb.stream = _wav(amb, 22050, true)
	audio_amb.volume_db = -20.0
	add_child(audio_amb)
	audio_amb.play()


# ------------------------------------------------------------------------ Flow

func _start_game() -> void:
	ui.hide_title()
	ui.pause_enabled = true
	ui.hud.visible = true
	phase = Phase.PREP
	player.can_move = true
	player.can_look = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	ui.show_toast("上午的雷雨在十一點半左右停了。日偏食已經開始，太陽在雲後時隱時現。\n找 Eddington 報到——他在望遠鏡旁。", 7.0)
	_refresh_objectives()


func _restart(same_sky: bool) -> void:
	next_seed = sim.run_seed if same_sky else randi() % 100000
	get_tree().paused = false
	get_tree().reload_current_scene()


func _process(delta: float) -> void:
	if player.global_position.y < -3.0:
		player.velocity = Vector3.ZERO
		player.global_position = (world.darkroom_spot if phase in [Phase.NIGHT, Phase.CODA] else Vector3(2.6, 0, 4.2)) + Vector3(0, 0.1, 0)
		ui.show_toast("你繞回了觀測站。")
	match phase:
		Phase.PREP:
			_process_prep(delta)
		Phase.TOTALITY:
			_process_totality(delta)
		Phase.NIGHT, Phase.CODA:
			_process_interaction(delta)
	if phase != Phase.TITLE and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and _ui_free() and bot == null:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _ui_free() -> bool:
	return not get_tree().paused and not ui.log_open() and not ui.dialog_active() and not ui.viewer.visible and not ui.ending_panel.visible and not ui.title_panel.visible and not _busy


func _sync_player_input() -> void:
	var free := _ui_free() and phase != Phase.TITLE
	player.can_move = free and phase in [Phase.PREP, Phase.NIGHT, Phase.CODA]
	player.can_look = free
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if free else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	if phase == Phase.TOTALITY and _ui_free() and not tot_done:
		if event.is_action_pressed("shutter") or event.is_action_pressed("interact"):
			_toggle_shutter()
			get_viewport().set_input_as_handled()
			return
	if not _ui_free():
		return
	if event.is_action_pressed("interact"):
		var n: Node = player.aimed_interactable()
		if n:
			_interact(n.get_meta("interact_id"))


# ----------------------------------------------------------------- Preparation

func _process_prep(delta: float) -> void:
	if _ui_free():
		prep_left -= delta
		_update_sky_prep()
	var minutes_to_14_13 := prep_left / PREP_S * 23.0
	var local_min := 13 * 60 + 13 + 60 - minutes_to_14_13  # 14:13 at zero
	ui.set_clock("下午 %d:%02d　·　全食倒數 %d:%02d（時間壓縮）" % [int(local_min / 60.0) - 12, int(local_min) % 60, int(maxf(prep_left, 0.0)) / 60, int(maxf(prep_left, 0.0)) % 60])
	_process_interaction(delta)
	if prep_left <= 0.0 and _ui_free():
		_begin_totality()


func _process_interaction(delta: float) -> void:
	if not _ui_free():
		ui.set_prompt("")
		ui.set_hold(0.0)
		return
	var n: Node = player.aimed_interactable()
	var id: String = n.get_meta("interact_id") if n else ""
	ui.set_prompt(_prompt_for(id, n))
	ui.crosshair.modulate = Color(1, 0.85, 0.5) if id != "" else Color(1, 1, 1, 0.6)
	if id in HOLD and _hold_allowed(id) and Input.is_action_pressed("interact"):
		if hold_id != id:
			hold_id = id
			hold_t = 0.0
		hold_t += delta
		ui.set_hold(hold_t / HOLD[id])
		if hold_t >= HOLD[id]:
			hold_t = 0.0
			_hold_complete(id)
	else:
		hold_id = ""
		hold_t = 0.0
		ui.set_hold(0.0)


func _hold_allowed(id: String) -> bool:
	if phase != Phase.PREP:
		return false
	match id:
		"drive":
			return not sim.drive_wound
		"chronometer":
			return sim.drive_wound and not sim.drive_rate_checked
		"plate_box":
			return sim.plates_carried + sim.plates_delivered < sim.MAX_EXTRA_PLATES
	return false


func _prompt_for(id: String, n: Node) -> String:
	if id == "":
		return ""
	var name_: String = n.get_meta("prompt")
	if phase == Phase.CODA:
		if coda_step == CodaStep.WORKBOOK and id == "departure_workbook":
			return "［E］再讀工作簿最後一頁。" if _departure_workbook_seen else "［E］在工作簿記下你看到的天空。"
		if coda_step == CodaStep.LOUPE and id == "mentor_loupe":
			return "［E］拿起 Ashby 先生給的放大鏡。"
		return ""
	if id == "mentor_loupe" and Story.departure_done and phase in [Phase.PREP, Phase.NIGHT]:
		return "［E］Ashby 先生給的放大鏡。"
	if phase == Phase.NIGHT:
		match id:
			"measure":
				return "［E］檢視底片"
			"eddington":
				return "［E］和 Eddington 說話"
			"departure_workbook":
				return "［E］在工作簿記下你看到的天空。" if not _departure_workbook_seen else ""
		return ""
	match id:
		"eddington", "cottingham":
			return "［E］和 %s 說話" % name_
		"drive":
			return "［按住 E］上發條" if not sim.drive_wound else "時鐘驅動：發條已上滿"
		"chronometer":
			if sim.drive_wound and not sim.drive_rate_checked:
				return "［按住 E］替 Cottingham 報秒、校走速"
			return "［E］看天文鐘"
		"plate_box":
			var left: int = sim.MAX_EXTRA_PLATES - sim.plates_carried - sim.plates_delivered
			if left <= 0:
				return "底片匣都拿完了"
			return "［按住 E］拿底片匣（手上 %d，箱裡還有 %d）" % [sim.plates_carried, left]
		"station":
			if sim.plates_carried > 0:
				return "［E］把 %d 個底片匣放上架子" % sim.plates_carried
			return "底片架：可用底片 %d 張" % sim.plates_available()
		"plan":
			return "［E］讀曝光計畫"
		"oxford_case":
			return "［E］看牛津比對底片"
		"measure":
			return "測量桌——今晚才會用到"
	return name_


func _hold_complete(id: String) -> void:
	match id:
		"drive":
			sim.drive_wound = true
			audio_click.play()
			ui.show_toast("發條上滿了。" + ("Cottingham：「好，接著去天文鐘那裡。」" if met_cottingham else ""))
		"chronometer":
			sim.drive_rate_checked = true
			audio_click.play()
			ui.show_toast("你對著天文鐘一秒一秒報數。Cottingham：「慢了一點……好，對上了。」")
		"plate_box":
			sim.plates_carried += 1
			audio_click.play()
	_refresh_objectives()


func _interact(id: String) -> void:
	if phase == Phase.CODA:
		if coda_step == CodaStep.WORKBOOK and id == "departure_workbook":
			_night_departure_workbook.call("open_workbook")
			_focus_coda(_night_departure_workbook.global_position)
			var seq: Array = CodaContent.workbook_again() if _departure_workbook_seen else DepartureContent.principe_workbook(Story.bond_tone)
			_departure_workbook_seen = true
			_say(seq, "coda_workbook")
		elif coda_step == CodaStep.LOUPE and id == "mentor_loupe":
			coda_step = CodaStep.KIT
			_focus_coda(get_node("AshbyLoupeHotspot").global_position)
			_say(CodaContent.ashby_answer(_grade.fit, _grade.clean, sim.combined().n > 0), "coda_loupe")
		return
	if id == "mentor_loupe" and Story.departure_done and phase in [Phase.PREP, Phase.NIGHT]:
		ui.show_toast("Ashby 先生給的放大鏡。", 4.0)
		return
	if phase == Phase.NIGHT:
		match id:
			"measure":
				_open_viewer()
			"eddington":
				if sim.measured:
					_start_judgment()
				else:
					_say([{"s": Content.E, "t": "先到測量桌看看底片吧。"}], "")
			"departure_workbook":
				if Story.departure_done and not _departure_workbook_seen:
					_departure_workbook_seen = true
					_night_departure_workbook.call("open_workbook")
					_say(DepartureContent.principe_workbook(Story.bond_tone), "")
		return
	if phase != Phase.PREP:
		return
	match id:
		"eddington":
			if not sim.briefed:
				var seq: Array = Content.briefing()
				if Story.prologue_done:
					seq.append({"s": Content.E, "t": preload("res://scripts/cambridge/content_1917.gd").principe_callback(Story)})
				_say(seq, "briefing")
			else:
				_say(Content.eddington_prep(), "eddington_prep")
		"cottingham":
			if not met_cottingham:
				met_cottingham = true
				_say(Content.cottingham_first(), "")
			elif sim.drive_rate_checked:
				_say(Content.cottingham_done(), "")
			elif sim.drive_wound:
				_say(Content.cottingham_after_wind(), "")
			else:
				_say([{"s": Content.C, "t": "驅動箱就在我旁邊——按住 E 上發條。"}], "")
		"station":
			if sim.plates_carried > 0:
				sim.plates_delivered += sim.plates_carried
				sim.plates_carried = 0
				audio_click.play()
				_update_rack()
				ui.show_toast("可用底片：%d 張。" % sim.plates_available())
		"plan":
			sim.read_plan = true
			_say(Content.plan_text(), "")
		"oxford_case":
			_say(Content.oxford_text(), "")
		"chronometer":
			ui.show_toast("天文鐘的滴答聲在潮濕的空氣裡顯得很響。")
		"measure":
			ui.show_toast("測量桌。今晚，底片會在這裡被逐張比對。")
	_refresh_objectives()


func _update_rack() -> void:
	var rack: Node3D = world.rack
	for c in rack.get_children():
		c.queue_free()
	var builder := World.new(rack)
	builder.look = not _user_args().has("no-grade")
	for i in sim.plates_available():
		builder.box(Vector3(0.09, 0.32, 0.26), Vector3(-0.33 + i * 0.056, 0.16, 0), Color(0.2, 0.15, 0.1).lightened((i % 3) * 0.05), rack, false)


func _say(seq: Array, purpose: String) -> void:
	_pending = purpose
	ui.play(seq)
	_sync_player_input()


func _on_dialogue_done(results: Dictionary) -> void:
	if phase == Phase.CODA and _camera_turn:
		_camera_turn.kill()
	var purpose := _pending
	_pending = ""
	match purpose:
		"briefing":
			sim.briefed = true
			ui.show_toast("目標已更新。")
		"eddington_prep":
			if results.get("prep", -1) == 0:
				_begin_totality()
		"judgment":
			_after_judgment(results)
		"reaction":
			if _came_from_departure:
				_begin_coda()
			else:
				_show_ending()
		"coda_opening":
			coda_step = CodaStep.WORKBOOK
			if _departure_workbook_seen:
				# Already written at night: reread it without another required interaction.
				_night_departure_workbook.call("open_workbook")
				_focus_coda(_night_departure_workbook.global_position)
				_say(CodaContent.workbook_again(), "coda_workbook")
			else:
				_highlight_coda(_night_departure_workbook.global_position)
		"coda_workbook":
			coda_step = CodaStep.LOUPE
			_highlight_coda(get_node("AshbyLoupeHotspot").global_position)
		"coda_loupe":
			_say(CodaContent.kit_close(Story.bond_tone), "coda_kit")
		"coda_kit":
			_end_coda()
	_refresh_objectives()
	_sync_player_input()


func _refresh_objectives() -> void:
	if phase == Phase.PREP:
		var ok := func(b: bool) -> String: return "[color=#9c9]✓[/color]" if b else "☐"
		var lines := ["[b]準備（全食之前）[/b]"]
		lines.append("%s 向 Eddington 報到" % ok.call(sim.briefed))
		lines.append("%s 從暗房搬底片匣到望遠鏡架（已放 %d／%d，手上 %d）" % [ok.call(sim.plates_delivered >= sim.MAX_EXTRA_PLATES), sim.plates_delivered, sim.MAX_EXTRA_PLATES, sim.plates_carried])
		lines.append("%s 協助 Cottingham 上發條" % ok.call(sim.drive_wound))
		lines.append("%s 用天文鐘替他校走速" % ok.call(sim.drive_rate_checked))
		lines.append("[color=#a99]可選：讀曝光計畫、看牛津比對底片[/color]")
		if sim.briefed:
			lines.append("[color=#db8]準備好了就告訴 Eddington，或等倒數結束[/color]")
		ui.set_objectives("\n".join(lines))
	elif phase == Phase.CODA:
		var objective := ""
		if coda_step == CodaStep.WORKBOOK:
			objective = "再讀工作簿最後一頁" if _departure_workbook_seen else "在工作簿記下你看到的天空"
		elif coda_step == CodaStep.LOUPE:
			objective = "拿起 Ashby 先生給的放大鏡"
		ui.set_objectives("[b]夜晚・暗房[/b]\n☐ " + objective if objective != "" else "")
	elif phase == Phase.NIGHT:
		if sim.measured:
			ui.set_objectives("[b]夜晚・暗房[/b]\n☐ 向 Eddington 報告你的判斷")
		else:
			ui.set_objectives("[b]夜晚・暗房[/b]\n☐ 到測量桌檢視並量測底片")
	else:
		ui.set_objectives("")


# -------------------------------------------------------------------- Totality

func _begin_totality() -> void:
	if phase != Phase.PREP:
		return
	_busy = true
	phase = Phase.TOTALITY
	ui.set_prompt("")
	ui.set_objectives("")
	if sim.plates_carried > 0:
		sim.plates_delivered += sim.plates_carried
		sim.plates_carried = 0
		_update_rack()
	plates_left = sim.plates_available()
	player.can_move = false
	await ui.fade_to(1.0, 0.7).finished
	player.global_position = world.station_pos + Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	player.look_at_point(player.camera.global_position + sim.sun_dir * 10.0)
	world.eddington.position = Vector3(-0.75, 0, -1.55)
	world.eddington.rotation.y = deg_to_rad(-90)
	world.cottingham.position = Vector3(0.75, 0, -1.3)
	world.cottingham.rotation.y = deg_to_rad(110)
	world.roof.visible = false
	t_game = 0.0
	_apply_light(1.0, 1.0, 0.0, 0.0)
	await ui.fade_to(0.0, 1.2).finished
	_busy = false
	_sync_player_input()
	var note := ""
	if not sim.drive_wound:
		note = "\nCottingham 只能自己趕著上發條，來不及對時。"
	elif not sim.drive_rate_checked:
		note = "\n發條上滿了，但走速沒有校過。"
	ui.show_toast("帆布遮陽頂已經捲起。第二接觸——全食開始，節拍器開始數秒。\n抬頭看雲：雲薄時按［空白鍵］喊「開始」，雲厚或快結束時再按一次喊「停」。" + note, 7.0)
	if bot:
		bot.on_phase("totality")


func _toggle_shutter() -> void:
	if sim.is_exposing():
		var p: Dictionary = sim.close_shutter(false)
		audio_click.play()
		plates_left -= 1
		ui.show_toast("你：「停！」　Cottingham 蓋上遮光板。第 %d 號底片曝光 %.1f 秒。" % [p.number, p.duration], 3.0)
		if plates_left > 0:
			change_left = sim.PLATE_CHANGE_S
	elif change_left > 0.0:
		ui.show_toast("Eddington 還在換片……", 1.5)
	elif plates_left <= 0:
		ui.show_toast("底片用完了。", 2.0)
	else:
		sim.open_shutter(t_game)
		audio_click.play()
		ui.show_toast("你：「開始！」　Cottingham 移開遮光板。", 2.0)


func _process_totality(delta: float) -> void:
	if _busy or tot_done or ui.log_open() or get_tree().paused:
		return
	var dt: float = delta * sim.TIME_SCALE
	t_game += dt
	var dens: float = sim.cloud_over_sun(t_game)
	if sim.is_exposing():
		sim.accumulate(dt, dens)
	if change_left > 0.0:
		change_left = maxf(change_left - dt, 0.0)
	_apply_light(1.0, 1.0, t_game, 0.0)
	_tick_acc += dt
	if _tick_acc >= 1.0:
		_tick_acc -= 1.0
		audio_tick.play()
	if t_game > 150.0 and not _glanced:
		_glanced = true
		ui.show_toast("Eddington 抬頭看了一眼：「雲還是很厚……繼續。」", 3.5)
	if t_game > sim.TOTALITY_S - 18.0 and not _warned_end:
		_warned_end = true
		ui.show_toast("太陽西緣開始發亮——第三接觸快到了！", 3.0)
	var left := maxf(sim.TOTALITY_S - t_game, 0.0)
	var status := ""
	if sim.is_exposing():
		status = "[color=#fd8]● 曝光中 %.1f 秒[/color]" % sim._open.duration
	elif change_left > 0.0:
		status = "[color=#aaa]Eddington 換片中…[/color]"
	elif plates_left > 0:
		status = "[color=#9c9]底片就緒[/color]——等雲變薄"
	else:
		status = "[color=#e88]底片用完了[/color]"
	ui.set_totality(true, "[b]全食[/b]　剩餘 %d 秒（共 302）\n底片 剩 %d／%d　已拍 %d\n%s\n[color=#998]［空白鍵／E／左鍵］開始・停[/color]" % [int(left), plates_left, sim.plates_available(), sim.plates.size(), status])
	ui.set_clock("")
	if t_game >= sim.TOTALITY_S:
		_end_totality()


func _end_totality() -> void:
	tot_done = true
	var ruined: bool = sim.is_exposing()
	if ruined:
		sim.close_shutter(true)
	ui.set_totality(false)
	audio_click.play()
	ui.show_toast("第三接觸。陽光像鑽石一樣從月亮邊緣迸出來。" + ("\n快門還開著——最後那張底片曝到了陽光。" if ruined else ""), 5.0)
	var tw := create_tween()
	tw.tween_method(func(v): _apply_light(1.0 - v * 0.2, 1.0 - v, t_game + v * 10.0, 0.0), 0.0, 1.0, 3.0)
	await tw.finished
	await get_tree().create_timer(1.5).timeout
	_begin_night()


# ----------------------------------------------------------------------- Night

func _begin_night() -> void:
	_busy = true
	await ui.fade_to(1.0, 1.2).finished
	phase = Phase.NIGHT
	comparison_tex = PlateRender.render(sim, null)
	plate_textures.clear()
	for p in sim.plates:
		plate_textures.append(PlateRender.render(sim, p))
	_apply_light(0.0, 0.0, 400.0, 1.0)
	world.lamp.light_energy = 1.1
	world.safelight.light_energy = Look.NIGHT_SAFELIGHT if _look_ambient < 1.0 else 0.25
	if Story.departure_done or _came_from_departure:
		_add_night_workbook()
	world.eddington.position = world.eddington_night
	world.eddington.rotation.y = deg_to_rad(-120)
	world.cottingham.position = world.darkroom_spot + Vector3(-1.5, 0, 1.2)
	player.global_position = world.darkroom_spot + Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	player.look_at_point(world.measure_pos)
	await ui.show_caption("接下來的六個夜晚\n暗房裡，底片一張張沖洗出來（時間壓縮）", 2.4).finished
	await ui.fade_to(0.0, 1.0).finished
	_busy = false
	player.can_move = true
	_refresh_objectives()
	_say(Content.night_intro(sim.plates.size()), "")
	if bot:
		bot.on_phase("night")


func _add_departure_loupe(wb) -> void:
	# The keepsake sits at the table's east edge, clear of the normal center-line
	# ray to the measuring sheet so both interactions remain independently usable.
	var p: Vector3 = world.measure_pos + Vector3(0.40, 0.042, -0.16)
	var ring: Node3D = wb.cyl(0.105, 0.025, p, wb.P("brass"), null, false)
	ring.name = "AshbyBrassLoupeRing"
	var glass: Node3D = wb.cyl(0.075, 0.009, p + Vector3(0, 0.018, 0), Color(0.16, 0.22, 0.24), null, false)
	glass.name = "AshbyBrassLoupeGlass"
	var handle: Node3D = wb.box(Vector3(0.055, 0.025, 0.24), p + Vector3(0, 0.004, 0.15), wb.P("brass"), null, false)
	handle.name = "AshbyBrassLoupeHandle"
	var hotspot: Node3D = wb.hotspot(Vector3(0.40, 0.24, 0.36), p + Vector3(0, 0.10, 0.04), "mentor_loupe", "Ashby 先生給的放大鏡。")
	hotspot.name = "AshbyLoupeHotspot"


func _add_night_workbook() -> void:
	# Keep it on the measuring table and east of the normal sheet aim point.
	var position: Vector3 = world.measure_pos + Vector3(0.43, 0.03, 0.23)
	_night_departure_workbook = DepartureWorkbook.new() as Node3D
	_night_departure_workbook.name = "PríncipeDepartureWorkbook"
	_night_departure_workbook.position = position
	add_child(_night_departure_workbook)
	var hotspot: Node3D = World.new(self).hotspot(Vector3(0.42, 0.24, 0.42), position + Vector3(0, 0.10, 0), "departure_workbook", "在工作簿記下你看到的天空")
	hotspot.name = "PríncipeDepartureWorkbookHotspot"


# ------------------------------------------------------------------------ Coda

func _begin_coda() -> void:
	phase = Phase.CODA
	coda_step = CodaStep.OPENING
	world.eddington.hide()
	world.cottingham.hide()
	# Hidden actors must not leave an invisible capsule in the player's path.
	world.eddington.process_mode = Node.PROCESS_MODE_DISABLED
	world.cottingham.process_mode = Node.PROCESS_MODE_DISABLED
	world.eddington.position.y = -20.0
	world.cottingham.position.y = -20.0
	if not is_instance_valid(_night_departure_workbook):
		_add_night_workbook()
	_coda_highlight = OmniLight3D.new()
	_coda_highlight.light_color = Color(1.0, 0.85, 0.57)
	_coda_highlight.light_energy = 0.0
	_coda_highlight.omni_range = 0.65
	add_child(_coda_highlight)
	_focus_coda(_night_departure_workbook.global_position)
	_say(CodaContent.opening(), "coda_opening")
	if bot:
		bot.on_phase("coda")


func _highlight_coda(target: Vector3) -> void:
	_coda_highlight.global_position = target + Vector3(0, 0.28, 0)
	_coda_highlight.light_energy = 0.45


func _focus_coda(target: Vector3) -> void:
	if _camera_turn:
		_camera_turn.kill()
	var direction: Vector3 = target - player.camera.global_position
	var yaw: float = player.yaw + wrapf(atan2(-direction.x, -direction.z) - player.yaw, -PI, PI)
	var pitch := clampf(atan2(direction.y, Vector2(direction.x, direction.z).length()), -1.45, 1.45)
	_camera_turn = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_camera_turn.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_camera_turn.tween_property(player, "yaw", yaw, 0.6)
	_camera_turn.tween_property(player, "pitch", pitch, 0.6)


func _sync_coda_log(open: bool) -> void:
	if phase != Phase.CODA:
		return
	for tw in [_camera_turn, _coda_transition]:
		if tw and tw.is_valid():
			if open:
				tw.pause()
			else:
				tw.play()


func _end_coda() -> void:
	coda_step = CodaStep.FADING
	_busy = true
	_coda_highlight.light_energy = 0.0
	# Lamp out, a breath of darkness, then the ending. Esc and Tab hold this beat.
	_coda_transition = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_coda_transition.tween_property(world.lamp, "light_energy", 0.0, 0.7)
	_coda_transition.tween_property(world.safelight, "light_energy", 0.0, 0.7)
	_coda_transition.chain().tween_interval(0.6)
	_coda_transition.chain().tween_property(ui.fade, "color:a", 1.0, 1.3)
	await _coda_transition.finished
	_busy = false
	_show_ending()


func _open_viewer() -> void:
	ui.open_viewer(sim.plates, comparison_tex, plate_textures, sim.measured)
	_sync_player_input()
	_refresh_viewer()


func _refresh_viewer() -> void:
	var rows := []
	for p in sim.included_usable():
		rows.append({"label": "第%d號" % p.number, "value": p.value, "sigma": p.sigma, "weak": p.quality != "good"})
	ui.chart.set_data(rows, sim.combined(), sim.measured)
	var good: int = sim.count_quality("good")
	var poor: int = sim.count_quality("poor")
	var bad: int = sim.count_quality("unusable")
	var sel: int = sim.plates.filter(func(p): return p.included).size()
	var note := "共 %d 張：星像清楚 %d、可量但有瑕疵 %d、星不足五顆 %d。\n已勾選 %d 張。" % [sim.plates.size(), good, poor, bad, sel]
	if sim.measured:
		var c: Dictionary = sim.combined()
		if c.n > 0:
			note += "\n[color=#fd8]合併：%.2f″ ± %.2f″[/color]" % [c.value, c.sigma]
	ui.set_viewer_note(note)
	ui.refresh_thumbs()


func _on_plate_toggled(i: int, on: bool) -> void:
	if sim.measured:
		return
	sim.plates[i].included = on
	_refresh_viewer()


func _on_measure() -> void:
	var sel: Array = sim.plates.filter(func(p): return p.included).map(func(p): return p.number)
	if sim.measured_selection != null and sel != sim.measured_selection:
		sim.reselected_after_seeing = true
	sim.measured_selection = sel
	sim.measured = true
	ui.set_viewer_locked(true)
	_refresh_viewer()
	_refresh_objectives()


func _on_reselect() -> void:
	sim.measured = false
	ui.set_viewer_locked(false)
	_refresh_viewer()
	_refresh_objectives()


func _on_viewer_closed() -> void:
	ui.close_viewer()
	_sync_player_input()


func _on_report() -> void:
	ui.close_viewer()
	_start_judgment()


var _grade: Dictionary
var _telegram := 0
var _reason := 0


func _start_judgment() -> void:
	var tele := Judgment.TELEGRAMS.map(func(t): return t.text)
	var rea := Judgment.REASONS.map(func(r): return r.text)
	_say(Content.judgment_prompt(tele, rea), "judgment")


func _after_judgment(results: Dictionary) -> void:
	_telegram = results.get("telegram", 1)
	_reason = results.get("reason", 1)
	_grade = Judgment.grade(sim, Judgment.TELEGRAMS[_telegram].id, Judgment.REASONS[_reason].id)
	var seq := []
	for l in _grade.lines:
		seq.append({"s": Content.E, "t": l})
	seq.append({"s": Content.C, "t": Content.cottingham_coda(sim)})
	_say(seq, "reaction")


func _show_ending() -> void:
	phase = Phase.ENDING
	ui.pause_enabled = false
	ui.hud.visible = false
	player.can_move = false
	player.can_look = false
	ui.fade.color.a = 0.0
	var c: Dictionary = sim.combined()
	var lines := []
	lines.append("[center][color=#c9b48a]你的電報[/color]\n[font_size=26][b]%s[/b][/font_size]\n[color=#b8ad98]理由：%s[/color][/center]\n" % [Judgment.TELEGRAMS[_telegram].text, Judgment.REASONS[_reason].text])
	lines.append("[b]Eddington 的回應[/b]")
	for l in _grade.lines:
		lines.append("· " + l)
	lines.append("")
	lines.append("[b]你留下的證據[/b]")
	lines.append("· 拍了 %d 張底片（可用底片 %d 張）。星像清楚 %d、有瑕疵 %d、星不足五顆 %d。" % [sim.plates.size(), sim.plates_available(), sim.count_quality("good"), sim.count_quality("poor"), sim.count_quality("unusable")])
	if c.n > 0:
		lines.append("· 你量了 %d 張，合併 %.2f″ ± %.2f″（示意模擬）。" % [c.n, c.value, c.sigma])
	else:
		lines.append("· 沒有量出任何數值。")
	lines.append("· 時鐘驅動：%s。" % ("上了發條並校過走速" if sim.drive_rate_checked else ("上了發條但沒校走速" if sim.drive_wound else "由 Cottingham 匆忙處理")))
	var history := []
	history.append("\n[b]歷史上[/b] [color=#8f8676](HISTORICAL_RECORD，詳見 docs/PROVENANCE.md)[/color]")
	history.append("普林西比在 302 秒的全食中拍了 16 張底片，曝光 2 到 20 秒；雲在全食最後三分之一才明顯變薄。前十張幾乎沒有星，最後只有兩張、五顆星能用於量測。Eddington 在島上量了一張，結果與愛因斯坦的預測相符；他發給 Dyson 的電報說雲很厚，但「有希望」（常被引作 \"Through cloud. Hopeful.\"，確切措辭仍待核對）。")
	history.append("1919 年 11 月 6 日，皇家學會與皇家天文學會聯席會議公布結果。報告最倚重的是巴西 Sobral 的 4 吋望遠鏡（1.98″ ± 0.12″）；普林西比是 1.61″ ± 0.30″（機率誤差）。Sobral 天體照相儀的結果因焦距改變、星像模糊而未採用——這是有紀錄的技術理由，而非掩蓋。一次遠征並沒有讓所有疑問就此消失。")
	history.append("\n[color=#8f8676][font_size=15]虛構與示意：玩家角色、全部對白、時鐘驅動需要協助的情節、雲的細節、底片影像與所有數值。場景為推測重建；普林西比站沒有已知的現場照片，原始底片也已佚失。[/font_size][/color]")
	ui.show_ending(_grade.title, "\n".join(lines), "\n".join(history))
	if bot:
		bot.on_phase("ending")
