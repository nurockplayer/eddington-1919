extends Node3D

const Settings := preload("res://scripts/settings.gd")

const Prompts := preload("res://scripts/prompts.gd")
## Game director for the slice: phases, interactions, and the loop
## prepare → expose through cloud → inspect plates → judge → reaction.

const Sim := preload("res://scripts/eclipse_sim.gd")
const World := preload("res://scripts/world_builder.gd")
const Player := preload("res://scripts/player.gd")
const UI := preload("res://scripts/ui.gd")
const Content := preload("res://scripts/content.gd")
const Ending := preload("res://scripts/ending.gd")
const Chart := preload("res://scripts/chart.gd")
const Cues := preload("res://scripts/totality_cues.gd")
const Judgment := preload("res://scripts/judgment.gd")
const PlateRender := preload("res://scripts/plate_render.gd")
const Style := preload("res://scripts/style.gd")
const LookPost := preload("res://scripts/look_post.gd")
const Look := preload("res://scripts/look.gd")
const NightSky := preload("res://scripts/night_sky.gd")
const Fireflies := preload("res://scripts/fireflies.gd")
const NightMeteors := preload("res://scripts/night_meteors.gd")
const SunCrescents := preload("res://scripts/sun_crescents.gd")
const SKY_SHADER := preload("res://shaders/eclipse_sky.gdshader")
const DepartureWorkbook := preload("res://scripts/cambridge/departure_props.gd")
const DepartureContent := preload("res://scripts/cambridge/content_departure.gd")
const CodaContent := preload("res://scripts/content_coda.gd")
const ScorePlayer := preload("res://scripts/audio/score_player.gd")

enum Phase { TITLE, PREP, TOTALITY, NIGHT, ENDING, CODA }
enum CodaStep { OPENING, WORKBOOK, LOUPE, KIT, FADING }

const BED_DIR := "res://assets/sfx/"
# Overall RMS in dBFS measured with ffmpeg astats, 2026-11-14 JST.
const BED_RMS_DB := {"birds": -29.70, "insects": -34.79, "surf": -23.85}

const PREP_S := 150.0            # real seconds of preparation (paused while talking)
const PASSAGE_S := 60.0          # real seconds approaching totality
const DAY_RETURN_S := 12.0
const THIRD_CONTACT_S := 3.0
const THIRD_CONTACT_CLOUD_S := 10.0
const EXPOSURE_STEP_S := 0.25    # game seconds between cloud samples during exposure
const TOTALITY_SCORE_DELAY_S := 2.0  # real seconds after second contact
const TOTALITY_SCORE_FADE_S := 1.2
const TOTALITY_INSECTS_FADE_S := 3.0
const TOTALITY_INSECTS_TRIM_DB := -6.0
# The surf ducks while the view goes dark, holds through the unscored gap after
# second contact, and swells back under the score once it enters.
const TOTALITY_SURF_DIP_DB := -18.0
const TOTALITY_SURF_DIP_S := 1.5
const TOTALITY_SURF_RETURN_S := 8.0
const TOTALITY_ACTION_DB := 8.0
const TOTALITY_MUSIC_DB := -16.0
const TOTALITY_AMBIENCE_DB := -12.0
const HOLD := {"drive": 3.0, "plate_box": 1.2}
## FICTION: player observation and trim requests use an illustrative diagram.
const Calibration := preload("res://scripts/coelostat_calibration.gd")
var calibration: Control

static var next_seed := -1
## Survives a 1919 replay (reload) so a prologue player keeps Story continuity and the coda;
## choosing the prologue again resets Story in Cambridge.
static var replay_from_prologue := false
static var replay_pending := false
static var replay_same_sky := true

var _is_replay := false
var _run_record_index := -1

var sim
var ui
var player
var world: Dictionary
var phase := Phase.TITLE
var prep_left := PREP_S
var rehearsing := false
var _rehearsal_step := 0
var _rehearsal_time := 0.0
var _rehearsal_opened := 0.0
var _rehearsal_exposure: Dictionary = {}
var _rehearsal_roof_visible := true
var _rehearsal_yaw := 0.0
var _rehearsal_pitch := 0.0
var _rehearsal_position := Vector3.ZERO
var _rehearsal_velocity := Vector3.ZERO
var t_game := 0.0                # totality clock, game-seconds
var _totality_rate := Sim.TIME_SCALE
var _holder_spent := false
var change_left := 0.0           # plate change in progress
var plate_changed := false       # a plate change was made this run (the workbook remembers it)
var plates_left := 0
var tot_done := false
var _day_return: Tween
var hold_t := 0.0
var hold_id := ""
var _hold_latched := false
var _interact_needs_release := false
var met_cottingham := false
var plate_textures: Array = []
var comparison_tex: Texture2D
var _comparison_fetched := false
var _tick_acc := 0.0
var _warned_end := false
var _glanced := false
const GLANCE_THICK := 0.6  # cloud_over_sun at or above this reads as 「雲還是很厚」
# M5 callouts: one-shot per run unless noted (long exposure resets per plate).
var _ever_exposed := false
var _long_called := false
var _callout_last_plate := false
var _callout_plates_left := false
var _callout_nudged := false
var _was_changing := false
var _busy := false               # in a scripted transition
var _pending := ""               # what the current dialogue is for
var _speaking_pose: World.WorkingPose

var sky_mat: ShaderMaterial
var meteors: Node  # NightMeteors, built with the sky
var env: Environment
var sun: DirectionalLight3D
var audio_tick: AudioStreamPlayer
var audio_click: AudioStreamPlayer
var audio_open: AudioStreamPlayer
var audio_change: AudioStreamPlayer
var audio_third: AudioStreamPlayer
var audio_insects: AudioStreamPlayer
var _insects_db := -9.2
var audio_surf: AudioStreamPlayer
var _surf_db := -22.9
var audio_birds: AudioStreamPlayer
var _totality_actions_bus: int
var _totality_ambience_bus: int
var _birds_tween: Tween
var _birds_quiet := false
var _sfx_log: Array[String] = []
var _sfx_samples: Dictionary = {}
var _night_bed_tween: Tween
var _night_bed_stopping := false
var bot: Node
var _look_sun := 1.0             # art-look gains (scripts/look.gd); 1.0 with --no-grade
var _look_ambient := 1.0
var _look := {}
var _style: RefCounted
var _departure_workbook_seen := false
var _came_from_departure := false
var _paired_cables: Node
var _night_departure_workbook: DepartureWorkbook
var coda_step := CodaStep.OPENING
var _camera_turn: Tween
var _coda_highlight: OmniLight3D
var _coda_transition: Tween
var score: Node
var _resolution_started := false
var _score_exposing := false


func _ready() -> void:
	_ensure_inputs()
	var darkroom := Story.darkroom_resume
	Story.darkroom_resume = {}
	_came_from_departure = Story.from_prologue or replay_from_prologue if darkroom.is_empty() else darkroom.from_departure
	replay_from_prologue = false
	_is_replay = replay_pending
	replay_pending = false
	if darkroom.is_empty():
		if not _came_from_departure:
			Story.reset(_is_replay)
		# Conversion arc A: new runs start from the 1917 page.
		if Story.prologue_done and not Story.bet_1917.is_empty():
			Story.bet = Story.bet_1917.duplicate(true)
		Story.kit_first = -1
	var args := _user_args()
	_style = Style.from_args(args)
	# A restart's chosen sky wins over the command line, which only seeds the first run.
	var seed_ := next_seed if next_seed >= 0 else int(args.get("seed", "-1"))
	if not darkroom.is_empty():
		seed_ = darkroom.seed
	if seed_ < 0:
		seed_ = randi() % 100000
	sim = Sim.new(seed_)
	_build_environment()
	var wb = World.new(self)
	wb.look = not args.has("no-grade")
	wb.engraving_pilot = _style != null
	world = wb.build()
	world.sun_crescents = SunCrescents.new()
	world.sun_crescents.setup(wb.palm_crowns, sim.sun_dir)
	add_child(world.sun_crescents)
	world.fireflies = Fireflies.new()
	world.fireflies.setup(wb.palm_crowns)
	add_child(world.fireflies)
	if Story.departure_done or _came_from_departure:
		_add_departure_loupe(wb)
	world.eddington.rotation.y = PI
	player = Player.new()
	player.step_surface = "earth"
	player.position = Vector3(2.6, 0.05, 4.2)
	add_child(player)
	if not _look.is_empty():
		player.camera.fov = _look.fov
		var post := LookPost.new()
		post.setup(_look.vignette, _look.grain)
		add_child(post)
	player.yaw = deg_to_rad(20)
	ui = UI.new()
	add_child(ui)
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	if _style != null:
		_style.apply(self)
	ui.start_pressed.connect(_start_from_title)
	ui.prologue_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/cambridge.tscn"))
	ui.continue_pressed.connect(_continue_from_title)
	ui.log_toggled.connect(func(_open): _sync_player_input())
	ui.pause_toggled.connect(func(_paused): _sync_player_input())
	ui.log_toggled.connect(_sync_coda_log)
	ui.quit_pressed.connect(func(): get_tree().quit())
	ui.restart_pressed.connect(_restart)
	ui.title_pressed.connect(_return_to_title)
	ui.dialogue_entry.connect(_on_dialogue_entry)
	ui.dialogue_done.connect(_on_dialogue_done)
	ui.plate_toggled.connect(_on_plate_toggled)
	ui.blink_hint_shown.connect(_save_darkroom)
	ui.measure_pressed.connect(_on_measure)
	ui.reading_set.connect(_on_reading_set)
	ui.reselect_pressed.connect(_on_reselect)
	ui.report_pressed.connect(_on_report)
	ui.viewer_closed.connect(_on_viewer_closed)
	calibration = Calibration.new()
	ui.get_child(0).add_child(calibration)
	calibration.hide()
	calibration.finished.connect(_close_calibration)
	calibration.visibility_changed.connect(func(): ui.hud.visible = not calibration.visible)
	Settings.apply_quality(get_tree())
	_build_audio()
	player.can_move = false
	player.can_look = false
	ui.set_objectives("")
	ui.hud.visible = false
	_update_sky_prep()
	if not darkroom.is_empty():
		_restore_darkroom(darkroom)
	elif Story.from_prologue:
		Story.from_prologue = false
		# The departure montage ends black; start here black and fade the new day in.
		ui.fade.color.a = 1.0
		_start_game()
		ui.fade_to(0.0, 1.0)
		ui.show_caption(L.t("1919 年 5 月 29 日・普林西比"), 2.4)
	if args.has("prologue-autoplay") and not Story.prologue_done:
		var prologue_bot: Script = load("res://tests/prologue_bot.gd")
		if prologue_bot:
			var runner: Node = prologue_bot.new()
			runner.main = self
			runner.scenario = args["prologue-autoplay"]
			runner.shots_dir = args.get("shots", "")
			runner.dwell = float(args.get("bot-dwell", "0"))
			get_tree().root.add_child.call_deferred(runner)
	if args.has("benchmark"):
		# DirAccess.make_dir_recursive_absolute() needs an absolute path: resolve
		# res:// and repo-relative arguments (e.g. art/validation/x) against the project.
		var out: String = args.benchmark
		if out.begins_with("res://"):
			out = ProjectSettings.globalize_path(out)
		elif not out.is_absolute_path():
			out = ProjectSettings.globalize_path("res://" + out)
		if args.has("bench-cambridge"):
			# Load dynamically: the Cambridge director already preloads this script.
			var director: Script = load("res://scripts/cambridge/director.gd")
			director.bench_cambridge_out = out
			get_tree().change_scene_to_file.call_deferred("res://scenes/cambridge.tscn")
			return
		# tests/ is excluded from exports, so in a build this flag is ignored and the game runs normally.
		var bench_script: Script = load("res://tests/benchmark.gd")
		if bench_script == null:
			push_warning("benchmark unavailable in this build")
		else:
			var bench: Node = bench_script.new()
			bench.main = self
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
		bot.dwell = float(args.get("bot-dwell", "0"))
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
		"toggle_fullscreen": [KEY_F11], "toggle_log": [KEY_TAB],
		"trim_fine": [KEY_SHIFT], "trim_leave": [KEY_B],
		"overlay_rotate_left": [KEY_Q], "overlay_rotate_right": [KEY_E],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			if not InputMap.action_has_event(action, ev):
				InputMap.action_add_event(action, ev)
	var axes := {
		"trim_fine": [JOY_AXIS_TRIGGER_LEFT, 1.0],
		"gamepad_look_left": [JOY_AXIS_RIGHT_X, -1.0], "gamepad_look_right": [JOY_AXIS_RIGHT_X, 1.0],
		"gamepad_look_up": [JOY_AXIS_RIGHT_Y, -1.0], "gamepad_look_down": [JOY_AXIS_RIGHT_Y, 1.0],
		"move_left": [JOY_AXIS_LEFT_X, -1.0], "move_right": [JOY_AXIS_LEFT_X, 1.0],
		"move_forward": [JOY_AXIS_LEFT_Y, -1.0], "move_back": [JOY_AXIS_LEFT_Y, 1.0],
		"look_left": [JOY_AXIS_RIGHT_X, -1.0], "look_right": [JOY_AXIS_RIGHT_X, 1.0],
		"overlay_rotate_left": [JOY_AXIS_RIGHT_X, -1.0], "overlay_rotate_right": [JOY_AXIS_RIGHT_X, 1.0],
		"look_up": [JOY_AXIS_RIGHT_Y, -1.0], "look_down": [JOY_AXIS_RIGHT_Y, 1.0],
	}
	for action in axes:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		InputMap.action_set_deadzone(action, 0.25)
		var motion := InputEventJoypadMotion.new()
		motion.axis = axes[action][0]
		motion.axis_value = axes[action][1]
		if not InputMap.action_has_event(action, motion):
			InputMap.action_add_event(action, motion)
	# Sticks move the player/paper; only arrows and D-pad navigate UI focus.
	for action in ["ui_left", "ui_right", "ui_up", "ui_down"]:
		for event in InputMap.action_get_events(action):
			if event is InputEventJoypadMotion:
				InputMap.action_erase_event(action, event)
	var buttons := {
		"trim_leave": [JOY_BUTTON_B], "ui_accept": [JOY_BUTTON_A], "ui_cancel": [JOY_BUTTON_B],
		"ui_up": [JOY_BUTTON_DPAD_UP], "ui_down": [JOY_BUTTON_DPAD_DOWN],
		"ui_left": [JOY_BUTTON_DPAD_LEFT], "ui_right": [JOY_BUTTON_DPAD_RIGHT],
		"run": [JOY_BUTTON_LEFT_STICK], "interact": [JOY_BUTTON_A],
		"shutter": [JOY_BUTTON_RIGHT_SHOULDER, JOY_BUTTON_X], "pause": [JOY_BUTTON_START],
		"toggle_log": [JOY_BUTTON_BACK], "overlay_rotate_left": [JOY_BUTTON_LEFT_SHOULDER],
		"overlay_rotate_right": [JOY_BUTTON_RIGHT_SHOULDER],
	}
	for action in buttons:
		for index in buttons[action]:
			var button := InputEventJoypadButton.new()
			button.button_index = index
			if not InputMap.action_has_event(action, button):
				InputMap.action_add_event(action, button)
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
	sky_mat.set_shader_parameter("contact", 0.8)
	sky_mat.set_shader_parameter("third_contact", Vector2.ZERO)
	sky_mat.set_shader_parameter("star_pos", sim.star_offsets)
	var mags := PackedFloat32Array()
	for i in sim.STAR_COUNT:
		mags.append(1.0 - i * 0.06)
	sky_mat.set_shader_parameter("star_mag", mags)
	NightSky.apply(sky_mat)
	meteors = NightMeteors.new()
	meteors.setup(sky_mat)
	add_child(meteors)
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
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	add_child(sun)
	sun.look_at_from_position(Vector3.ZERO, -sim.sun_dir, Vector3.UP)
	sun.shadow_enabled = true
	sun.light_color = Color(1.0, 0.96, 0.88)
	var args := _user_args()
	if not args.has("no-grade"):
		var sets := str(args.get("look-set", ""))
		for bad in Look.override_errors(sets):
			printerr("LOOK-SET ERROR: ignored ", bad)
		_look = Look.principe(sets)
		Look.apply_principe(env, sun, sky_mat, _look)
		_look_sun = _look.sun_gain
		_look_ambient = _look.ambient_gain
	we.set_meta("standard_ssao", env.ssao_enabled)
	we.set_meta("standard_sdfgi", env.sdfgi_enabled)
	we.set_meta("standard_volumetric_fog", env.volumetric_fog_enabled)
	we.add_to_group("quality_env")


## r06: characters turn their heads toward the player at conversation distance
## (LookAtModifier3D added by world_builder._person). Purely presentational.
var _npc_looks := []   # [[body, LookAtModifier3D], ...], found once


func _update_npc_look() -> void:
	if player == null:
		return
	if _npc_looks.is_empty():
		for npc_body in [world.eddington, world.cottingham]:
			for m in (npc_body as Node).find_children("look_at", "LookAtModifier3D", true, false):
				(m as LookAtModifier3D).target_node = (m as Node).get_path_to(player.camera)
				_npc_looks.append([npc_body, m])
		if _npc_looks.is_empty():
			_npc_looks.append(null)  # primitive figures: nothing to drive
	var eye: Vector3 = player.camera.global_position
	for pair in _npc_looks:
		if pair == null:
			continue
		var d: float = (pair[0] as Node3D).global_position.distance_to(eye)
		(pair[1] as LookAtModifier3D).influence = clampf((4.5 - d) / 2.0, 0.0, 0.25)


## Fraction of the solar disc not covered by the Moon for a contact value.
func _crescent(contact: float) -> float:
	var s := (1.0 - contact) * 2.1
	if s >= 2.0:
		return 1.0
	var overlap := 2.0 * acos(s / 2.0) - (s / 2.0) * sqrt(4.0 - s * s)
	return clampf(1.0 - overlap / PI, 0.0, 1.0)


func _apply_light(contact: float, darkness: float, cloud_t: float, night: float, before_second_contact := false, day_return := false) -> void:
	# Distant cards print only as the inked totality/night tree line, never a day wash.
	var forest_ink := maxf(smoothstep(0.85, 1.0, darkness) if _style != null else float(darkness > 0.95), night)
	for layer in $ForestEdge.get_children():
		layer.set_instance_shader_parameter("print_card", forest_ink > 0.0)
		layer.set_instance_shader_parameter("print_coverage", forest_ink)
	sky_mat.set_shader_parameter("contact", contact)
	sky_mat.set_shader_parameter("before_second_contact", before_second_contact)
	sky_mat.set_shader_parameter("darkness", darkness)
	sky_mat.set_shader_parameter("cloud_time", cloud_t)
	sky_mat.set_shader_parameter("third_contact_cloud_clock", Vector3(sim.TOTALITY_S, _totality_rate, THIRD_CONTACT_CLOUD_S / THIRD_CONTACT_S))
	sky_mat.set_shader_parameter("night", night)
	if meteors:
		meteors.set_night(night > 0.5)
	sky_mat.set_shader_parameter("star_vis", clampf((darkness - 0.85) / 0.15, 0.0, 1.0) * (1.0 - night))
	var dens: float = sim.cloud_over_sun(cloud_t)
	var vis := _crescent(contact) * (1.0 - darkness)
	var sun_floor := 0.15 if _look.is_empty() else float(_look.sun_floor) * (1.0 - darkness)
	var daylight := (1.0 - smoothstep(0.9, 0.95, darkness) if _style != null else float(darkness <= 0.95)) * (1.0 - night)
	sun.light_energy = (sun_floor + 1.4 * vis * (1.0 - dens * 0.85)) * daylight * _look_sun
	if world.has("sun_crescents"):
		var lit := daylight * SunCrescents.sunlight(vis, dens)
		world.sun_crescents.set_eclipse(contact, lit)
	world.doorway_daylight.light_energy = 16.0 * (1.0 - darkness) * (1.0 - night)
	world.oxford_lantern.visible = night > 0.5
	world.oxford_lantern_light.light_energy = 8.0 * night
	if world.has("fireflies"):
		world.fireflies.set_night(night > 0.5)
	var amb_day := Color(0.55, 0.57, 0.6)
	var amb_tot := Color(0.10, 0.11, 0.17)
	var amb_night := Color(0.03, 0.035, 0.05)
	env.ambient_light_color = amb_day.lerp(amb_tot, darkness).lerp(amb_night, night)
	env.ambient_light_energy = lerpf(1.0, 0.55, darkness) * _look_ambient
	env.fog_light_color = Color(0.62, 0.65, 0.68).lerp(Color(0.07, 0.08, 0.12), maxf(darkness, night))
	if _style != null and not world.is_empty():
		_style.light(self, contact, darkness, night)
		_style.quad_material.set_shader_parameter("day_return_cloud_time", t_game if day_return else -1.0)
	_sync_style_sky()


func _update_sky_prep() -> void:
	var f := 1.0 - prep_left / PREP_S
	var contact := lerpf(0.62, 0.985, f)
	var darkness := pow(f, 3.0) * 0.45
	if _style != null:
		darkness = 1.0 - smoothstep(0.0, PASSAGE_S, prep_left)
	_apply_light(contact, darkness, -prep_left, 0.0, true)


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
	var score_ready := Time.get_ticks_usec()
	score = ScorePlayer.new()
	add_child(score)
	score.totality_bus = &"Totality Music"
	_audio_submix(score.totality_bus, &"Music", TOTALITY_MUSIC_DB)
	_totality_actions_bus = _audio_submix(&"Totality Actions", &"SFX", 0.0)
	_totality_ambience_bus = _audio_submix(&"Totality Ambience", &"SFX", 0.0)
	score.warm(["totality_drone", "totality_glass", "totality_edge", "coda_resolution"])
	ui.log_toggled.connect(score.set_log_open)
	print("[SCORE READY] scene=1919 added_ms=%.3f" % [(Time.get_ticks_usec() - score_ready + ui.music_ready_usec) / 1000.0])
	var tick := PackedFloat32Array()
	for i in 700:
		var t := i / 22050.0
		tick.append(sin(t * TAU * 1900.0) * exp(-t * 180.0) * 0.6 + (randf() - 0.5) * exp(-t * 400.0) * 0.4)
	audio_tick = AudioStreamPlayer.new()
	audio_tick.bus = &"Totality Actions"
	audio_tick.stream = _wav(tick)
	audio_tick.volume_db = -11.0
	add_child(audio_tick)
	var click := PackedFloat32Array()
	for i in 2200:
		var t := i / 22050.0
		click.append((randf() - 0.5) * exp(-t * 60.0) + sin(t * TAU * 220.0) * exp(-t * 40.0) * 0.5)
	audio_click = AudioStreamPlayer.new()
	audio_click.bus = &"Totality Actions"
	audio_click.stream = _wav(click)
	audio_click.volume_db = -12.0
	add_child(audio_click)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19190529
	var opening := PackedFloat32Array()
	var low := 0.0
	var slow := 0.0
	for i in int(22050 * 0.18):
		var t := i / 22050.0
		var noise := rng.randf_range(-1.0, 1.0)
		low = lerpf(low, noise, 0.20)
		slow = lerpf(slow, noise, 0.035)
		var tail := minf((0.18 - t) / 0.025, 1.0)
		opening.append((sin(TAU * 140.0 * t) * exp(-t * 35.0) * 0.48
			+ (low - slow) * sin(PI * t / 0.18) * 0.50) * tail)
	_sfx_samples["open"] = opening
	audio_open = AudioStreamPlayer.new()
	audio_open.bus = &"Totality Actions"
	audio_open.stream = _wav(opening)
	audio_open.volume_db = -8.0
	add_child(audio_open)
	var changing := PackedFloat32Array()
	low = 0.0
	slow = 0.0
	for i in int(22050 * 1.5):
		var t := i / 22050.0
		var noise := rng.randf_range(-1.0, 1.0)
		low = lerpf(low, noise, 0.28)
		slow = lerpf(slow, noise, 0.045)
		var sample := 0.0
		for start in [0.0, 0.8]:
			var local: float = t - start
			if local >= 0.0 and local < 0.35:
				sample += (low - slow) * sin(PI * local / 0.35) * 0.55
		for start in [0.45, 1.25]:
			var local: float = t - start
			if local >= 0.0 and local < 0.20:
				sample += (sin(TAU * 180.0 * local) * 0.42
					+ sin(TAU * 310.0 * local) * 0.12) * exp(-local * 45.0)
		changing.append(sample)
	_sfx_samples["change"] = changing
	audio_change = AudioStreamPlayer.new()
	audio_change.bus = &"Totality Actions"
	audio_change.stream = _wav(changing)
	audio_change.volume_db = -10.0
	add_child(audio_change)
	var third := PackedFloat32Array()
	for i in int(22050 * 1.6):
		var t := i / 22050.0
		var envelope := minf(t / 0.05, 1.0) * exp(-t * 3.8) * minf((1.6 - t) / 0.1, 1.0)
		third.append((sin(TAU * 1320.0 * t) * 0.22 + sin(TAU * 1980.0 * t) * 0.12) * envelope)
	_sfx_samples["third"] = third
	audio_third = AudioStreamPlayer.new()
	audio_third.bus = "SFX"
	audio_third.stream = _wav(third)
	audio_third.volume_db = -3.0
	add_child(audio_third)
	var insects := PackedFloat32Array()
	var periods := [0.5, 0.6, 0.75, 6.0 / 7.0]
	var phases := [0.04, 0.17, 0.31, 0.48]
	var carriers := [4100.0, 4370.0, 4660.0, 4930.0]
	var previous_noise := 0.0
	for i in 22050 * 6:
		var t := i / 22050.0
		var sample := 0.0
		for voice in 4:
			var local := fposmod(t + phases[voice], periods[voice])
			var duration := (3.0 + (voice % 2)) / 30.0
			if local < duration:
				var pulse := sin(PI * fposmod(local * 30.0, 1.0))
				sample += sin(TAU * carriers[voice] * t) * pulse * pulse * sin(PI * local / duration) * 0.10
		var noise := rng.randf_range(-1.0, 1.0)
		# Every voice completes whole chirp/carrier periods; taper only the hiss.
		var edge := minf(minf(t, 6.0 - t) / 0.01, 1.0)
		sample += (noise - previous_noise) * 0.006 * edge
		previous_noise = noise
		insects.append(sample)
	_sfx_samples["insects"] = insects
	audio_insects = AudioStreamPlayer.new()
	audio_insects.bus = &"Totality Ambience"
	audio_insects.stream = _wav(insects, 22050, true)
	if _bed_sampled("insects"):
		var stream: AudioStreamOggVorbis = load(BED_DIR + "bed_insects.ogg")
		stream.loop = true
		audio_insects.stream = stream
		_insects_db = _bed_target(insects, -9.2) - BED_RMS_DB["insects"]
	audio_insects.volume_db = _insects_db
	add_child(audio_insects)
	var surf := PackedFloat32Array()
	var brown := 0.0
	low = 0.0
	for i in 22050 * 8:
		brown = clampf(brown + rng.randf_range(-0.03, 0.03), -1.0, 1.0) * 0.996
		low = lerpf(low, brown, 0.02)
		surf.append(low)
	# Remove endpoint drift before swelling, so the distant rumble joins quietly.
	var first := surf[0]
	var drift := surf[surf.size() - 1] - first
	var surf_peak := 0.0
	for i in surf.size():
		var t := i / 22050.0
		surf[i] = (surf[i] - drift * i / (surf.size() - 1.0)) * (0.55 + 0.45 * pow(sin(PI * t / 8.0), 2.0))
		surf_peak = maxf(surf_peak, absf(surf[i]))
	for i in surf.size():
		surf[i] *= 0.6 / surf_peak
	_sfx_samples["surf"] = surf
	audio_surf = AudioStreamPlayer.new()
	audio_surf.bus = &"Totality Ambience"
	audio_surf.stream = _wav(surf, 22050, true)
	if _bed_sampled("surf"):
		var stream: AudioStreamOggVorbis = load(BED_DIR + "bed_surf.ogg")
		stream.loop = true
		audio_surf.stream = stream
		_surf_db = _bed_target(surf, -22.9) - BED_RMS_DB["surf"]
	audio_surf.volume_db = _surf_db
	add_child(audio_surf)
	audio_surf.play()
	var birds := PackedFloat32Array()
	birds.resize(22050 * 10)
	# Eight seeded calls, spaced far enough apart for four notes and seam silence.
	for call in 8:
		var start := 0.4 + call * 1.15 + rng.randf_range(0.0, 0.15)
		var notes := rng.randi_range(2, 4)
		var rising := rng.randf() < 0.5
		for note in notes:
			var duration := rng.randf_range(0.06, 0.18)
			var from_hz := 2600.0 if rising else 3800.0
			var to_hz := 3400.0 if rising else 2900.0
			var offset := int((start + note * 0.22) * 22050)
			for i in int(duration * 22050):
				var t := i / 22050.0
				var envelope := 0.5 - 0.5 * cos(TAU * t / duration)
				var angle := TAU * (from_hz * t + 0.5 * (to_hz - from_hz) * t * t / duration)
				birds[offset + i] = sin(angle) * envelope * 0.6
	_sfx_samples["birds"] = birds
	audio_birds = AudioStreamPlayer.new()
	audio_birds.bus = "SFX"
	audio_birds.stream = _wav(birds, 22050, true)
	audio_birds.volume_db = -23.9
	if _bed_sampled("birds"):
		var stream: AudioStreamOggVorbis = load(BED_DIR + "bed_birds.ogg")
		stream.loop = true
		audio_birds.stream = stream
		audio_birds.volume_db = _bed_target(birds, -23.9) - BED_RMS_DB["birds"]
	add_child(audio_birds)
	audio_birds.play()


func _audio_submix(bus: StringName, parent: StringName, db: float) -> int:
	var index := AudioServer.get_bus_index(bus)
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus)
		AudioServer.set_bus_send(index, parent)
	AudioServer.set_bus_volume_db(index, db)
	return index


func _bed_sampled(name: String) -> bool:
	return ResourceLoader.exists(BED_DIR + "bed_" + name + ".ogg")


func _bed_target(samples: PackedFloat32Array, volume_db: float) -> float:
	var sum_sq := 0.0
	for sample in samples:
		sum_sq += sample * sample
	return linear_to_db(sqrt(sum_sq / samples.size())) + volume_db


func _sfx(name: String) -> void:
	var sounds := {"open": audio_open, "close": audio_click, "change": audio_change, "third": audio_third}
	sounds[name].play()
	_sfx_log.append(name)


func _quiet_birds() -> void:
	if _birds_quiet:
		return
	_birds_quiet = true
	_sfx_log.append("birds_quiet")
	_birds_tween = create_tween()
	_birds_tween.tween_property(audio_birds, "volume_db", -60.0, 6.0)
	_birds_tween.tween_callback(audio_birds.stop)


func _start_night_bed() -> void:
	if audio_insects.playing:
		return
	_night_bed_stopping = false
	audio_insects.volume_db = -60.0
	audio_insects.play()
	_sfx_log.append("insects")
	_night_bed_tween = create_tween()
	_night_bed_tween.tween_property(audio_insects, "volume_db", _insects_db, 3.0)


func _stop_night_bed() -> void:
	if not audio_insects.playing or _night_bed_stopping:
		return
	_night_bed_stopping = true
	if _night_bed_tween and _night_bed_tween.is_valid():
		_night_bed_tween.kill()
	_night_bed_tween = create_tween()
	_night_bed_tween.tween_property(audio_insects, "volume_db", -60.0, 1.0)
	_night_bed_tween.tween_callback(audio_insects.stop)


func _exit_tree() -> void:
	# Scene changes and normal quit need the same cleanup as the autoplay path.
	for tween in [_camera_turn, _coda_transition]:
		if tween and tween.is_valid():
			tween.kill()
	stop_all_audio()


func stop_all_audio() -> void:
	if _birds_tween and _birds_tween.is_valid():
		_birds_tween.kill()
	if _night_bed_tween and _night_bed_tween.is_valid():
		_night_bed_tween.kill()
	for sound in [audio_tick, audio_click, audio_open, audio_change, audio_third, audio_insects, audio_surf, audio_birds]:
		sound.stop()


# ------------------------------------------------------------------------ Flow

func _continue_from_title() -> void:
	var chapter := Checkpoint.restore()
	if chapter == "":
		return
	if chapter == "principe":
		Story.from_prologue = true
	# A continued chapter starts with no log from the run that ended.
	UI.history.clear()
	get_tree().change_scene_to_file(Checkpoint.scene(chapter))


# The title hands over through black, so 1919 fades in instead of cutting.
func _start_from_title() -> void:
	if phase != Phase.TITLE:
		return
	await ui.fade_to(1.0, 0.4).finished
	if phase != Phase.TITLE:
		return
	_start_game()
	await ui.fade_to(0.0, 0.8).finished


func _start_game() -> void:
	ui.hide_title()
	ui.pause_enabled = true
	ui.hud.visible = true
	phase = Phase.PREP
	player.can_move = true
	player.can_look = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if _is_replay and not Story.runs.is_empty():
		_say(Content.replay_opening(Story.runs.size() + 1, replay_same_sky), "")
	else:
		ui.show_toast(L.t("上午的雷雨在十一點半左右停了。日偏食已經開始，太陽在雲後時隱時現。\n找 Eddington 報到——他在望遠鏡旁。"), 7.0)
	_refresh_objectives()


func _return_to_title() -> void:
	Story.reset()
	# A new game starts with no log and a fresh sky.
	UI.history.clear()
	prepare_title()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


## The static hand-off a chapter needs before returning to the title.
static func prepare_title() -> void:
	next_seed = -1
	# A replay's origin flag must not survive into the title run.
	replay_from_prologue = false
	replay_pending = false


func _restart(same_sky: bool) -> void:
	prepare_replay(sim.run_seed if same_sky else randi() % 100000, same_sky, _came_from_departure)
	get_tree().paused = false
	get_tree().reload_current_scene()


## The static hand-off a chapter needs before reloading or leaving for a replay.
static func prepare_replay(seed_value: int, same_sky: bool, from_prologue: bool) -> void:
	next_seed = seed_value
	replay_from_prologue = from_prologue
	replay_pending = true
	replay_same_sky = same_sky


func _process(delta: float) -> void:
	if _verdict_hold_s > 0.0 and not get_tree().paused and not ui.log_open():
		# Begin counting only after the confirmed report has had a frame to appear.
		if _verdict_hold_first_frame:
			_verdict_hold_first_frame = false
		else:
			_verdict_hold_s -= delta
			if _verdict_hold_s <= 0.0:
				_offer_telegram()
	_update_npc_look()
	if player.global_position.y < -3.0:
		player.velocity = Vector3.ZERO
		player.global_position = (world.darkroom_spot if phase in [Phase.NIGHT, Phase.CODA] else Vector3(2.6, 0, 4.2)) + Vector3(0, 0.1, 0)
		ui.show_toast(L.t("你繞回了觀測站。"))
	match phase:
		Phase.PREP:
			_process_prep(delta)
		Phase.TOTALITY:
			_process_totality(delta)
		Phase.NIGHT, Phase.CODA:
			_process_interaction(delta)
	_sync_style_sky()
	if phase != Phase.TITLE and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and _ui_free() and bot == null:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and not get_tree().paused:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _sync_style_sky() -> void:
	if _style == null:
		return
	for name in ["contact", "before_second_contact", "cloud_tex", "cloud_time", "third_contact_cloud_clock", "practice_cloud", "wind", "cloud_scale"]:
		_style.quad_material.set_shader_parameter(name, sky_mat.get_shader_parameter(name))
	_style.quad_material.set_shader_parameter("diamond", sky_mat.get_shader_parameter("third_contact").y)


func _ui_free() -> bool:
	return _verdict_hold_s <= 0.0 and not calibration.visible and not get_tree().paused and not ui.log_open() and not ui.dialog_active() and not ui.viewer.visible and not ui.ending_panel.visible and not ui.title_panel.visible and not _busy


func _sync_player_input() -> void:
	var free := _ui_free() and phase != Phase.TITLE
	player.can_move = free and not rehearsing and phase in [Phase.PREP, Phase.NIGHT, Phase.CODA]
	player.can_look = free
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if free else Input.MOUSE_MODE_VISIBLE


func _unhandled_input(event: InputEvent) -> void:
	var interact := event.is_action_pressed("interact")
	if rehearsing and _ui_free():
		if event.is_action_pressed("shutter") or interact:
			if interact and _rehearsal_step == 2:
				_change_rehearsal_holder()
			else:
				_rehearse_shutter()
			get_viewport().set_input_as_handled()
		return
	if phase == Phase.TOTALITY and _ui_free() and not tot_done:
		if event.is_action_pressed("shutter") or interact:
			if interact and _holder_spent and change_left <= 0.0:
				_order_plate_change()
			else:
				_toggle_shutter()
			get_viewport().set_input_as_handled()
			return
	if not _ui_free():
		return
	if interact:
		var n: Node = player.aimed_interactable()
		if n:
			_interact(n.get_meta("interact_id"))


# ----------------------------------------------------------------- Preparation

func _process_prep(delta: float) -> void:
	if rehearsing:
		if _rehearsal_step < 2 and _ui_free():
			var previous := _rehearsal_time
			_rehearsal_time += delta
			if _rehearsal_step == 1:
				# FICTION: integrate the displayed practice cloud, in compressed game seconds.
				var until := minf(_rehearsal_time, 12.5)
				while previous < until:
					var dt := minf(0.05, until - previous)
					var density := _rehearsal_cloud(previous + dt * 0.5)
					var game_dt: float = dt * sim.TIME_SCALE
					_rehearsal_exposure.duration += game_dt
					_rehearsal_exposure.clear += (1.0 - density) * game_dt
					_rehearsal_exposure.cloudy += density * game_dt
					previous += dt
			sky_mat.set_shader_parameter("practice_cloud", _rehearsal_cloud(_rehearsal_time))
			sky_mat.set_shader_parameter("cloud_time", _rehearsal_time - prep_left)
			if _rehearsal_step == 0 and _rehearsal_time >= 9.5:
				_miss_rehearsal(Content.rehearsal_feedback("never", ""))
			elif _rehearsal_step == 1 and _rehearsal_time >= 12.5:
				_sfx("close")
				_miss_rehearsal(_rehearsal_feedback(false))
			else:
				_update_rehearsal_hud()
		elif _rehearsal_step == 2:
			_update_rehearsal_hud()
		return
	if _ui_free() or (calibration.visible and not get_tree().paused):
		var active_delta := minf(delta, maxf(prep_left, 0.0))
		prep_left -= active_delta
		if calibration.visible:
			calibration.advance(active_delta)
			if prep_left <= 0.0:
				_close_calibration()
		_update_sky_prep()
	var minutes_to_14_13 := prep_left / PREP_S * 23.0
	var local_min := 13 * 60 + 13 + 60 - minutes_to_14_13  # 14:13 at zero
	var countdown := ceili(maxf(prep_left, 0.0))
	ui.set_clock(L.t("下午 %d:%02d　·　全食倒數 %d:%02d（時間壓縮）") % [int(local_min / 60.0) - 12, int(local_min) % 60, countdown / 60, countdown % 60])
	_process_interaction(delta)
	if prep_left <= 0.0 and _ui_free():
		_begin_totality()


func _process_interaction(delta: float) -> void:
	if not _ui_free():
		_cancel_hold()
		ui.set_prompt("")
		return
	var n: Node = player.aimed_interactable()
	var id: String = n.get_meta("interact_id") if n else ""
	ui.prompt_label.position.y = 200.0 if id == "departure_workbook" else (300.0 if id == "mentor_loupe" else 550.0)
	ui.set_prompt(_prompt_for(id, n))
	ui.crosshair.modulate = Color.WHITE if ui.paper_hud else (Color(1, 0.85, 0.5) if id != "" else Color(1, 1, 1, 0.6))
	var holding := Input.is_action_pressed("interact")
	var pressed := Input.is_action_just_pressed("interact")
	if _interact_needs_release:
		if holding:
			# The press that closed the pause panel is not a new interaction.
			holding = false
			pressed = false
		else:
			_interact_needs_release = false
	if Settings.hold_toggle:
		if pressed and id in HOLD and _hold_allowed(id):
			_hold_latched = not (_hold_latched and hold_id == id)
		holding = _hold_latched and hold_id in ["", id]
	if id in HOLD and _hold_allowed(id) and holding:
		if hold_id != id:
			hold_id = id
			hold_t = 0.0
		hold_t += delta
		ui.set_hold(hold_t / HOLD[id])
		if hold_t >= HOLD[id]:
			hold_t = 0.0
			_hold_complete(id)
	else:
		_cancel_hold()


func _cancel_hold() -> void:
	_hold_latched = false
	hold_id = ""
	hold_t = 0.0
	ui.set_hold(0.0)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PAUSED:
			_cancel_hold()
		NOTIFICATION_UNPAUSED:
			_interact_needs_release = true


func _hold_allowed(id: String) -> bool:
	if phase != Phase.PREP:
		return false
	match id:
		"drive":
			return not sim.drive_wound
		"plate_box":
			return sim.plates_carried + sim.plates_delivered < sim.MAX_EXTRA_PLATES
	return false


func _prompt_for(id: String, n: Node) -> String:
	if id == "":
		return ""
	var name_: String = n.get_meta("prompt")
	if phase == Phase.CODA:
		if coda_step == CodaStep.WORKBOOK and id == "departure_workbook":
			return L.t("［%s］再讀工作簿最後一頁。") % Prompts.key("interact") if _departure_workbook_seen else L.t("［%s］在工作簿記下你看到的天空。") % Prompts.key("interact")
		if coda_step == CodaStep.LOUPE and id == "mentor_loupe":
			return L.t("［%s］拿起 Ashby 先生給的放大鏡。") % Prompts.key("interact")
		return ""
	if id == "mentor_loupe" and Story.departure_done and phase in [Phase.PREP, Phase.NIGHT]:
		return L.t("［%s］Ashby 先生給的放大鏡。") % Prompts.key("interact")
	if phase == Phase.NIGHT:
		match id:
			"measure":
				return L.t("［%s］檢視底片") % Prompts.key("interact")
			"oxford_case":
				return L.t("［%s］看牛津比對底片") % Prompts.key("interact")
			"eddington":
				return L.t("［%s］和 Eddington 說話") % Prompts.key("interact")
			"departure_workbook":
				return L.t("［%s］在工作簿記下你看到的天空。") % Prompts.key("interact") if not _departure_workbook_seen else ""
		return ""
	match id:
		"eddington", "cottingham":
			return L.t("［%s］和 %s 說話") % [Prompts.key("interact"), name_]
		"drive":
			if not sim.drive_wound:
				return L.t("［按 %s 開始］上發條") % Prompts.key("interact") if Settings.hold_toggle else L.t("［按住 %s］上發條") % Prompts.key("interact")
			return L.t("［%s］觀察追蹤、請 Cottingham 微調") % Prompts.key("interact")
		"chronometer":
			return L.t("［%s］看天文鐘") % Prompts.key("interact")
		"plate_box":
			var left: int = sim.MAX_EXTRA_PLATES - sim.plates_carried - sim.plates_delivered
			if left <= 0:
				return L.t("底片匣都拿完了")
			if Settings.hold_toggle:
				return L.t("［按 %s 開始］拿底片匣（手上 %d，箱裡還有 %d）") % [Prompts.key("interact"), sim.plates_carried, left]
			return L.t("［按住 %s］拿底片匣（手上 %d，箱裡還有 %d）") % [Prompts.key("interact"), sim.plates_carried, left]
		"station":
			if sim.plates_carried > 0:
				return L.tn("［%s］把 %d 個底片匣放上架子", sim.plates_carried) % [Prompts.key("interact"), sim.plates_carried]
			return L.t("底片架：可用底片 %d 張") % sim.plates_available()
		"plan":
			return L.t("［%s］讀曝光計畫") % Prompts.key("interact")
		"oxford_case":
			return L.t("［%s］看牛津比對底片") % Prompts.key("interact")
		"measure":
			return L.t("測量桌——今晚才會用到")
	return name_


func _hold_complete(id: String) -> void:
	match id:
		"drive":
			sim.drive_wound = true
			_interact_needs_release = true
			audio_click.play()
			ui.show_toast(L.t("發條上滿了。") + (L.t("Cottingham：「好，放開按鍵，再看追蹤示意圖。」") if met_cottingham else ""))
		"plate_box":
			sim.plates_carried += 1
			audio_click.play()
	_refresh_objectives()


func _interact(id: String) -> void:
	if phase == Phase.CODA:
		if coda_step == CodaStep.WORKBOOK and id == "departure_workbook":
			_night_departure_workbook.call("open_workbook")
			_focus_coda(_night_departure_workbook.global_position)
			var seq: Array = CodaContent.workbook_again(_night_departure_workbook.kit_line) if _departure_workbook_seen else DepartureContent.principe_workbook(Story.bond_tone, sim.plates, plate_changed)
			_departure_workbook_seen = true
			_say(seq, "coda_workbook")
		elif coda_step == CodaStep.LOUPE and id == "mentor_loupe":
			coda_step = CodaStep.KIT
			_focus_coda(get_node("AshbyLoupeHotspot").global_position)
			var measured_any: bool = sim.combined().n > 0
			var any_usable: bool = sim.plates.any(func(p): return p.usable)
			var residual_found: bool = Story.clues.get("residual", false)  # found, whatever the report says
			var reprise := CodaContent.small_numbers(residual_found, measured_any, Story.want)
			_say(CodaContent.ashby_answer(_grade.fit, _grade.clean, measured_any, any_usable,
				int(Story.bet.get("ashby", 0)) == 1, _pressed_eddington, _verdict_class) + reprise, "coda_loupe")
		return
	if id == "mentor_loupe" and Story.departure_done and phase in [Phase.PREP, Phase.NIGHT]:
		ui.show_toast(L.t("Ashby 先生給的放大鏡。"), 4.0)
		return
	if phase == Phase.NIGHT:
		match id:
			"measure":
				if _needs_comparison_fetch():
					_say(Content.comparison_errand(), "")
					return
				if sim.rule_id == "":
					_say(Content.rules_prompt(Story.plan.has("rules_first"),
						int(Story.exam.get("q1", -1)) if Story.prologue_done else -1,
						Story.runs.back().rule_id if not Story.runs.is_empty() else ""), "rules")
				else:
					_open_viewer()
			"oxford_case":
				if _needs_comparison_fetch():
					_comparison_fetched = true
					_save_darkroom()
					_say(Content.comparison_fetched(), "")
					_refresh_objectives()
				else:
					_say(Content.oxford_text(), "")
			"eddington":
				if sim.measured:
					_start_judgment()
				else:
					_say([{"s": Content.E, "t": L.t("先到測量桌看看底片吧。")}], "")
			"departure_workbook":
				if Story.departure_done and not _departure_workbook_seen:
					_night_departure_workbook.call("open_workbook")
					_say(DepartureContent.principe_workbook(Story.bond_tone, sim.plates, plate_changed), "night_workbook")
		return
	if phase != Phase.PREP:
		return
	match id:
		"drive":
			if sim.drive_wound and not _interact_needs_release and not calibration.visible:
				_cancel_hold()
				calibration.open(sim)
				_sync_player_input()
		"eddington":
			if not sim.briefed:
				var seq: Array = Content.briefing(Story.prologue_done)
				if Story.prologue_done:
					seq.append({"s": Content.E, "t": preload("res://scripts/cambridge/content_1917.gd").principe_callback(Story)})
				_say(seq, "briefing")
			else:
				var plates: int = sim.BASE_PLATES + mini(sim.plates_delivered + sim.plates_carried, sim.MAX_EXTRA_PLATES)
				_say(Content.eddington_prep(plates, sim.drive_wound, sim.drive_rate_checked, sim.plates_carried), "eddington_prep")
		"cottingham":
			if sim.drive_rate_checked:
				_say(Content.cottingham_done(), "")
			elif not met_cottingham:
				met_cottingham = true
				_say(Content.cottingham_first(), "")
			elif sim.drive_wound:
				_say(Content.cottingham_after_wind(), "")
			else:
				_say([{"s": Content.C, "t": L.t("驅動箱就在我旁邊——按一下 %s 開始上發條。") % Prompts.key("interact") if Settings.hold_toggle else L.t("驅動箱就在我旁邊——按住 %s 上發條。") % Prompts.key("interact")}], "")
		"sundy":
			# HISTORICAL_RECORD: host and labour; RECONSTRUCTION: wording.
			_say([{"s": "", "t": L.t("Roça Sundy。莊園主人 Jerónimo Carneiro 讓遠征隊自由調用莊園的人手。挑夫把箱子扛過樹林，放定天鏡的石墩是莊園的工人砌的。報告謝了莊園主人，卻沒有寫下任何一個工人的名字。")}], "")
		"station":
			if sim.plates_carried > 0:
				sim.plates_delivered += sim.plates_carried
				sim.plates_carried = 0
				audio_click.play()
				_update_rack()
				ui.show_toast(L.t("可用底片：%d 張。") % sim.plates_available())
		"plan":
			sim.read_plan = true
			_say(Content.plan_text(), "")
		"oxford_case":
			_say(Content.oxford_text(), "")
		"chronometer":
			ui.show_toast(L.t("天文鐘的滴答聲在潮濕的空氣裡顯得很響。"))
		"measure":
			ui.show_toast(L.t("測量桌。今晚，底片會在這裡被逐張比對。"))
	_refresh_objectives()


func _close_calibration() -> void:
	calibration.hide()
	_interact_needs_release = true
	_refresh_objectives()
	_sync_player_input()


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


func _set_darkroom_name_tags_visible(show_tags: bool) -> void:
	if phase == Phase.NIGHT:
		for actor: Node3D in [world.eddington, world.cottingham]:
			for tag: Label3D in actor.find_children("*", "Label3D", false, false):
				tag.visible = show_tags


func _on_dialogue_entry(speaker: String) -> void:
	_set_darkroom_name_tags_visible(speaker.is_empty())
	if phase not in [Phase.PREP, Phase.NIGHT] or speaker not in [Content.E, Content.C]:
		return
	var body: Node3D = world.eddington if speaker == Content.E else world.cottingham
	var pose := body.find_child("WorkingPose", true, false) as World.WorkingPose
	if pose == _speaking_pose:
		return
	if _speaking_pose:
		_speaking_pose.restore_work()
	_speaking_pose = pose
	if pose:
		pose.face_player(player.camera.global_position)


func _on_dialogue_done(results: Dictionary) -> void:
	_set_darkroom_name_tags_visible(true)
	if _speaking_pose:
		_speaking_pose.restore_work()
		_speaking_pose = null
	if phase == Phase.CODA and _camera_turn:
		_camera_turn.kill()
	var purpose := _pending
	_pending = ""
	match purpose:
		"after_totality":
			_begin_night()
		"briefing":
			sim.briefed = true
			ui.show_toast(L.t("目標已更新。"))
		"eddington_prep":
			if results.get("prep", -1) == 0:
				_begin_totality()
				return  # The transition owns the HUD handover under black.
			elif results.get("prep", -1) == 2:
				_begin_rehearsal()
		"night_workbook":
			_departure_workbook_seen = true
			_save_darkroom()
		"rules":
			sim.rule_id = ["strict", "after", "none"][int(results.get("rule", 0))]
			_save_darkroom()
			_refresh_objectives()
			# Conversion arc move A: the bet comes before the plates, once per run.
			_say(Content.bet_prompt(Story.bet if Story.prologue_done else {}), "bet")
		"bet":
			_record_bet(results)
			_save_darkroom()
			_open_viewer()
		"reselect_reason":
			sim.reselect_reason = ["quality", "result", "none"][int(results.get("reselect_reason", 2))]
			sim.reselect_justified_so_far = sim.selection_report().reselect_justified
			sim.reselect_history.append({"reason": sim.reselect_reason,
				"added": sim.reselect_added.duplicate(), "removed": sim.reselect_removed.duplicate()})
			_finish_measurement()
			_open_viewer()
			ui.reselect_btn.grab_focus()
		"verdict":
			_verdict = results.verdict
			_verdict_truth = Judgment.verdict_truth(sim)
			_verdict_class = Judgment.verdict_class(_verdict, _verdict_truth)
			_verdict_hold_s = 1.5
			_verdict_hold_first_frame = true
		"judgment":
			_after_judgment(results)
		"telegram_record":
			_review_telegram()
		"reaction":
			_pressed_eddington = int(results.get("press", -1)) == 0
			if _came_from_departure:
				_begin_coda()
			else:
				_lamp_out_then_ending()
		"coda_opening":
			coda_step = CodaStep.WORKBOOK
			if _departure_workbook_seen:
				# Already written at night: reread it without another required interaction.
				_night_departure_workbook.call("open_workbook")
				_focus_coda(_night_departure_workbook.global_position)
				_say(CodaContent.workbook_again(_night_departure_workbook.kit_line), "coda_workbook")
			else:
				_highlight_coda(_night_departure_workbook.global_position)
		"coda_workbook":
			coda_step = CodaStep.LOUPE
			_highlight_coda(get_node("AshbyLoupeHotspot").global_position)
		"coda_loupe":
			var overclaimed: bool = Judgment.TELEGRAMS[_telegram].id == "confirmed"
			_say(CodaContent.kit_close(Story.bond_tone, Story.kit_choice,
				overclaimed, _grade.fit == 0 and not overclaimed, _grade.clean, Story.sky_promise), "coda_kit")
		"coda_kit":
			Story.kit_first = int(results.get("kit_first", -1))
			var no_mistake: bool = Judgment.TELEGRAMS[_telegram].id != "confirmed" and _grade.fit != 0 and _grade.clean
			_night_departure_workbook.write_kit_line(L.t("給 Kit：%s") % CodaContent.kit_first_reply(Story.kit_first, no_mistake))
			_end_coda()
	_refresh_objectives()
	_sync_player_input()


## Conversion arc A: keep the prediction ledger. Not changing the 1917 entry leaves it
## as written; a 1919 change keeps Ashby's entry and the 1917 confidence.
func _record_bet(results: Dictionary) -> void:
	if results.has("bet_keep"):
		var keep := int(results.bet_keep)
		if keep == 0:
			sim.bet_pick = int(Story.bet.get("pick", -1))
			return
		Story.bet = {"pick": keep - 1, "sure": int(Story.bet.get("sure", 0)),
			"ashby": int(Story.bet.get("ashby", 0)), "year": 1919}
	else:
		Story.bet = {"pick": int(results.get("bet", 0)), "sure": int(results.get("bet_sure", 0)),
			"ashby": 0, "year": 1919}
	sim.bet_pick = int(Story.bet.pick)


func _needs_comparison_fetch() -> bool:
	return Story.prologue_done and not Story.plan.has("comparison") and not _comparison_fetched


func _refresh_objectives() -> void:
	if phase == Phase.PREP:
		var ok := func(b: bool) -> String: return "[color=#9c9]✓[/color]" if b else "□"
		var lines := [L.t("[b]準備（全食之前）[/b]"), L.t("[color=#a99]今天要量的：太陽旁邊的星，有沒有被往外推。[/color]")]
		lines.append(L.t("%s 向 Eddington 報到") % ok.call(sim.briefed))
		lines.append(L.t("%s 從暗房（鐵皮屋頂的木屋）搬底片匣到望遠鏡架（已放 %d／%d，手上 %d）") % [ok.call(sim.plates_delivered >= sim.MAX_EXTRA_PLATES), sim.plates_delivered, sim.MAX_EXTRA_PLATES, sim.plates_carried])
		lines.append(L.t("%s 協助 Cottingham 上發條") % ok.call(sim.drive_wound))
		lines.append(L.t("%s 觀察追蹤、請 Cottingham 微調走速") % ok.call(sim.drive_rate_checked))
		lines.append(L.t("[color=#a99]可選：讀曝光計畫、看牛津比對底片[/color]"))
		if sim.briefed:
			lines.append(L.t("[color=#db8]準備好了就告訴 Eddington，或等倒數結束[/color]"))
		ui.set_objectives("\n".join(lines))
	elif phase == Phase.CODA:
		var objective := ""
		if coda_step == CodaStep.WORKBOOK:
			objective = L.t("再讀工作簿最後一頁") if _departure_workbook_seen else L.t("在工作簿記下你看到的天空")
		elif coda_step == CodaStep.LOUPE:
			objective = L.t("拿起 Ashby 先生給的放大鏡")
		ui.set_objectives(L.t("[b]夜晚・暗房[/b]\n□ %s") % objective if objective != "" else "")
	elif phase == Phase.NIGHT:
		var measure := L.t("□ 到測量桌：先寫下選片規則，再量底片") if sim.rule_id == "" else L.t("□ 在測量桌上檢視並量測底片")
		if _needs_comparison_fetch():
			ui.set_objectives(L.t("[b]夜晚・暗房[/b]\n□ 去拿牛津比對底片\n%s") % measure)
		elif sim.measured:
			ui.set_objectives(L.t("[b]夜晚・暗房[/b]\n□ 向 Eddington 報告你的判斷"))
		else:
			ui.set_objectives(L.t("[b]夜晚・暗房[/b]\n%s") % measure)
	else:
		ui.set_objectives("")


func _totality_aim_point() -> Vector3:
	var vfov := deg_to_rad(player.camera.fov)
	var size := get_viewport().get_visible_rect().size
	var hfov := 2.0 * atan(tan(vfov / 2.0) * size.x / size.y)
	var x := tan(hfov / 2.0) / 3.0
	var y := tan(vfov / 2.0) / 3.0
	var altitude := asin(sim.sun_dir.y)
	# Ultrawide screens can put the horizontal third beyond this solar altitude.
	var yaw_offset := asin(clampf(x / (cos(altitude) * sqrt(1.0 + x * x + y * y)), -1.0, 1.0))
	var yaw := atan2(-sim.sun_dir.x, -sim.sun_dir.z) + yaw_offset
	var pitch := atan2(sin(altitude), cos(altitude) * cos(yaw_offset)) - atan(y)
	var direction := Vector3(-sin(yaw) * cos(pitch), sin(pitch), -cos(yaw) * cos(pitch))
	return player.camera.global_position + direction * 10.0


func _begin_rehearsal() -> void:
	rehearsing = true
	_rehearsal_step = 0
	_rehearsal_time = 0.0
	_rehearsal_exposure = {}
	_rehearsal_roof_visible = world.roof.visible
	_rehearsal_yaw = player.yaw
	_rehearsal_pitch = player.pitch
	_rehearsal_position = player.global_position
	_rehearsal_velocity = player.velocity
	player.global_position = world.station_pos + Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	world.roof.visible = false
	world.eddington.visible = false
	world.cottingham.visible = false
	world.crate_label.hide()
	player.look_at_point(_totality_aim_point())
	sky_mat.set_shader_parameter("practice_cloud", 0.93)
	_sync_player_input()
	ui.set_prompt("")
	ui.set_hold(0.0)
	ui.set_clock("")
	# Reserve space for the shutter hint even while it is hidden during the change.
	ui.tot_panel.custom_minimum_size.y = Settings.fs(100)
	_update_rehearsal_hud()
	ui.show_toast(L.t("Eddington：沒有底片，只練眼睛和口令。看太陽那一塊雲——變薄就按［%s］喊『開始』，變厚之前喊『停』。") % Prompts.key("shutter"), 12.0)


func _rehearsal_cloud(t: float) -> float:
	var thin := smoothstep(2.5, 3.0, t) * (1.0 - smoothstep(9.0, 9.5, t))
	return lerpf(0.93, 0.12, thin)


func _rehearsal_feedback(stopped: bool) -> String:
	var timing := "inside"
	if not stopped:
		timing = "no_stop"
	elif _rehearsal_opened < 3.0:
		timing = "early"
	elif _rehearsal_time >= 9.0:
		timing = "late"
	# develop() uses the current drive preparation and a local RNG; no live exposure is opened.
	var plate: Dictionary = sim.develop(_rehearsal_exposure, 0)
	return Content.rehearsal_feedback(timing, plate.quality)


func _rehearse_shutter() -> void:
	match _rehearsal_step:
		0:
			_sfx("open")
			_rehearsal_opened = _rehearsal_time
			_rehearsal_exposure = {"start": _rehearsal_time * sim.TIME_SCALE, "duration": 0.0, "clear": 0.0, "cloudy": 0.0, "sunlit": false}
			ui.show_toast(L.t("你：『開始！』　Cottingham 移開遮光板（空的）。再按一次喊『停』。"), 7.0)
			_rehearsal_step = 1
			_update_rehearsal_hud()
		1:
			_sfx("close")
			_rehearsal_step = 2
			_show_rehearsal_feedback(_rehearsal_feedback(true))
			_update_rehearsal_hud()
		3:
			ui.show_toast(L.t("Eddington 還在換片……"), 1.5)


func _show_rehearsal_feedback(feedback: String) -> void:
	var message := L.t("Eddington：") + feedback
	if _rehearsal_exposure.is_empty():
		ui.show_toast(message, 7.0)
	else:
		var band := Cues.sky_band(_rehearsal_exposure.clear, _rehearsal_exposure.duration)
		ui.show_toast(message + "\n" + Content.totality_read(band, true), 3.5)


func _change_rehearsal_holder() -> void:
	_rehearsal_step = 3
	_sfx("change")
	ui.show_toast(Content.rehearsal_change().strip_edges(), 3.5)
	_update_rehearsal_hud()
	await _finish_rehearsal()


func _miss_rehearsal(feedback: String) -> void:
	_rehearsal_step = 4
	_show_rehearsal_feedback(feedback)
	_update_rehearsal_hud()
	await _finish_rehearsal()


func _finish_rehearsal() -> void:
	await get_tree().create_timer(sim.PLATE_CHANGE_S / sim.TIME_SCALE, false).timeout
	sky_mat.set_shader_parameter("practice_cloud", -1.0)
	world.roof.visible = _rehearsal_roof_visible
	world.eddington.visible = true
	world.cottingham.visible = true
	world.crate_label.show()
	player.global_position = _rehearsal_position
	player.velocity = _rehearsal_velocity
	player.yaw = _rehearsal_yaw
	player.pitch = _rehearsal_pitch
	rehearsing = false
	ui.set_totality(false)
	ui.tot_panel.custom_minimum_size.y = 0.0
	_sync_player_input()


func _update_rehearsal_hud() -> void:
	var duration: float = _rehearsal_exposure.duration if _rehearsal_step == 1 else -1.0
	var spent := _rehearsal_step == 2
	var changing := _rehearsal_step == 3
	ui.tot_hint.visible = _rehearsal_step < 2
	var status := _holder_change_prompt() if spent else _shutter_status(duration, changing, true)
	ui.set_totality(true, "" if _rehearsal_step == 4 else status)


# -------------------------------------------------------------------- Totality

func _begin_totality() -> void:
	if phase != Phase.PREP:
		return
	_busy = true
	phase = Phase.TOTALITY
	_totality_rate = Sim.TIME_SCALE * 0.5 if Settings.slower_totality else Sim.TIME_SCALE
	ui.lock_totality_pace()
	_quiet_birds()
	create_tween().tween_property(audio_surf, "volume_db", _surf_db + TOTALITY_SURF_DIP_DB, TOTALITY_SURF_DIP_S)
	_sync_player_input()
	# Keep the second-contact delay. The engraving plate cuts directly from
	# the crescent to the corona, with the rolled eave at the edge of the view.
	await ui.fade_to(0.0 if _style != null else 1.0, 0.7).finished
	ui.set_prompt("")
	ui.set_objectives("")
	if sim.plates_carried > 0:
		sim.plates_delivered += sim.plates_carried
		sim.plates_carried = 0
		_update_rack()
	plates_left = sim.plates_available()
	player.velocity = Vector3.ZERO
	if _style != null:
		player.global_position = world.station_pos + Vector3(-1.5, 0.05, 1.9)
		player.yaw = deg_to_rad(31.0)
		player.pitch = deg_to_rad(34.0)
		player.rotation.y = player.yaw
		player.camera.rotation.x = player.pitch
	else:
		player.global_position = world.station_pos + Vector3(0, 0.05, 0)
		player.look_at_point(_totality_aim_point())
	world.eddington.position = Vector3(-0.75, 0, -1.55)
	world.eddington.rotation.y = deg_to_rad(-90)
	world.cottingham.position = Vector3(0.75, 0, -1.3)
	world.cottingham.rotation.y = deg_to_rad(110)
	world.eddington.visible = false
	world.cottingham.visible = false
	world.roof.visible = false
	t_game = 0.0
	_holder_spent = false
	change_left = 0.0
	_ever_exposed = false
	_long_called = false
	_callout_last_plate = false
	_callout_plates_left = false
	_callout_nudged = false
	_was_changing = false
	_apply_light(1.0, 1.0, 0.0, 0.0)
	_update_totality_hud()
	await ui.fade_to(0.0, 1.2).finished
	_busy = false
	_birds_tween.kill()
	audio_birds.stop()
	# Second contact: a near-silent dusk bed, with the score held back.
	audio_insects.volume_db = -60.0
	audio_insects.play()
	_night_bed_tween = create_tween()
	_night_bed_tween.tween_property(audio_insects, "volume_db", _insects_db + TOTALITY_INSECTS_TRIM_DB, TOTALITY_INSECTS_FADE_S)
	_sync_player_input()
	var note := ""
	if not sim.drive_wound:
		note = L.t("\nCottingham 只能自己趕著上發條，來不及對時。")
	elif not sim.drive_rate_checked:
		note = L.t("\n發條上滿了，但走速尚未驗證。")
	ui.show_toast(L.t("帆布遮陽頂已經捲起。第二接觸——全食開始，節拍器開始數秒。\n抬頭看雲：雲薄時按［%s］喊「開始」，雲厚或快結束時再按一次喊「停」。") % Prompts.key("shutter") + note, 7.0)
	if bot:
		bot.on_phase("totality")


func _toggle_shutter() -> void:
	if sim.is_exposing():
		var p: Dictionary = sim.close_shutter(false)
		p.sky_read = Cues.sky_band(p.clear, p.duration)
		_sfx("close")
		plates_left -= 1
		_holder_spent = plates_left > 0
		ui.show_toast(L.t("你：「停！」　Cottingham 蓋上遮光板。第 %d 號底片曝光 %.1f 秒。\n%s") % [p.number, p.duration, Content.totality_read(p.sky_read)], 3.5)
	elif change_left > 0.0:
		ui.show_toast(L.t("Eddington 還在換片……"), 1.5)
	elif plates_left <= 0:
		t_game = maxf(t_game, sim.TOTALITY_S - 3.0)
	elif not _holder_spent:
		sim.open_shutter(t_game)
		_ever_exposed = true
		_long_called = false
		_sfx("open")
		ui.show_toast(L.t("你：「開始！」　Cottingham 移開遮光板。"), 2.0)
	_update_totality_hud()


func _order_plate_change() -> void:
	change_left = sim.PLATE_CHANGE_S
	_was_changing = true
	_sfx("change")
	_update_totality_hud()


func _process_totality(delta: float) -> void:
	if ui.log_open() or get_tree().paused:
		return
	# Only this guarded clock advances totality layers, including contact fades.
	score.advance(delta)
	if _busy or tot_done:
		return
	var previous := t_game
	t_game = minf(previous + delta * _totality_rate, sim.TOTALITY_S)
	var dt := t_game - previous
	var score_start := TOTALITY_SCORE_DELAY_S * _totality_rate
	if previous < score_start and t_game >= score_start:
		# The metronome counts throughout totality. Keep a steady balance around
		# the count so the score and beds don't pulse back up between ticks.
		AudioServer.set_bus_volume_db(_totality_actions_bus, TOTALITY_ACTION_DB)
		score.play("totality_drone", TOTALITY_SCORE_FADE_S)
		score.play("totality_glass", TOTALITY_SCORE_FADE_S)
		_score_exposing = false
	var exposing: bool = sim.is_exposing()
	if exposing != _score_exposing:
		_score_exposing = exposing
		score.set_layer_db("totality_glass", ScorePlayer.SILENCE_DB if exposing else ScorePlayer.Score.level_db("totality_glass"), 0.4 if exposing else 1.2)
	if t_game >= score_start:
		var surf_elapsed := minf((t_game - score_start) / _totality_rate, TOTALITY_SURF_RETURN_S)
		audio_surf.volume_db = Tween.interpolate_value(_surf_db + TOTALITY_SURF_DIP_DB,
			-TOTALITY_SURF_DIP_DB, surf_elapsed, TOTALITY_SURF_RETURN_S, Tween.TRANS_SINE, Tween.EASE_IN_OUT)
		AudioServer.set_bus_volume_db(_totality_ambience_bus, Tween.interpolate_value(0.0,
			TOTALITY_AMBIENCE_DB, surf_elapsed, TOTALITY_SURF_RETURN_S, Tween.TRANS_SINE, Tween.EASE_IN_OUT))
	var dens: float = sim.cloud_over_sun(t_game)
	if exposing:
		# Weight each game-time sample by the exposed part of its interval.
		var cursor := previous
		while cursor < t_game:
			var sample_time := (floorf(cursor / EXPOSURE_STEP_S) + 1.0) * EXPOSURE_STEP_S
			var end := minf(sample_time, t_game)
			sim.accumulate(end - cursor, sim.cloud_over_sun(sample_time))
			cursor = end
	if change_left > 0.0:
		change_left = maxf(change_left - dt, 0.0)
		if change_left == 0.0:
			_holder_spent = false
			plate_changed = true
	_apply_light(1.0, 1.0, t_game, 0.0)
	_tick_acc += dt
	if _tick_acc >= 1.0:
		_tick_acc -= 1.0
		audio_tick.play()
	_totality_callouts()
	# The glance states what the sky is doing, so it waits out a thin patch
	# and is dropped once the third-contact warning has fired.
	if t_game > 150.0 and not _glanced and not _warned_end and dens >= GLANCE_THICK:
		_glanced = true
		ui.set_callout(L.t("Eddington 抬頭看了一眼：「雲還是很厚……繼續。」"), 3.5)
	if t_game > sim.TOTALITY_S - 18.0 and not _warned_end:
		_warned_end = true
		score.play("totality_edge", 3.0)
		ui.set_callout(L.t("太陽西緣開始發亮——第三接觸快到了！"), 3.0)
	_update_totality_hud()
	if t_game >= sim.TOTALITY_S:
		_end_totality()


func _holder_change_prompt() -> String:
	return L.t("［%s］換底片匣") % Prompts.key("interact")


func _shutter_status(duration: float, changing: bool, ready: bool) -> String:
	if duration >= 0.0:
		return L.t("[color=#fd8]● 曝光中 %.1f 秒[/color]") % duration
	if changing:
		return L.t("[color=#aaa]Eddington 換片中…[/color]")
	return L.t("[color=#9c9]底片就緒[/color]") if ready else L.t("[color=#e88]底片用完了[/color]")


func _update_totality_hud() -> void:
	var left := maxf(sim.TOTALITY_S - t_game, 0.0)
	var exposing: bool = sim.is_exposing()
	var changing := change_left > 0.0
	var duration: float = sim._open.duration if exposing else -1.0
	var header := ""
	if left > 0.0 and left <= 10.0:
		header = L.t("[b]全食[/b]　[font_size=%d][color=#e88]%d[/color][/font_size] 秒") % [Settings.fs(42), int(ceil(left))]
	else:
		header = L.t("[b]全食[/b]　剩餘 %d 秒（共 302）") % int(left)
	var waiting_for_order := _holder_spent and not changing
	header += "\n" + (_holder_change_prompt() if waiting_for_order else _shutter_status(duration, changing, plates_left > 0))
	var open_start: float = sim._open.start if exposing else -1.0
	ui.tot_hint.visible = not changing and not waiting_for_order
	ui.set_totality(true, header, Cues.strip_model(t_game, sim.TOTALITY_S, sim.plates, open_start, sim.plates_available()))
	# The strip infers auto-change from the last close. Use the actual holder state here.
	if not exposing and plates_left > 0:
		ui.tot_strip.holder_mark = &"changing" if changing else (&"spent" if waiting_for_order else &"ready")
	var prompt := L.t("底片用完了。［%s］等待第三接觸") if plates_left <= 0 and not exposing else L.t("［%s］開始／停")
	ui.set_prompt("" if changing or waiting_for_order else prompt % Prompts.key("shutter"))
	ui.set_clock("")


## Hindsight-free callouts: facts the observers had, never a hint about the sky ahead.
func _totality_callouts() -> void:
	var exposing: bool = sim.is_exposing()
	if exposing and not _long_called and sim._open.duration >= 20.0:
		_long_called = true
		ui.set_callout(Content.totality_long(sim.drive_rate_checked), 3.5)
	if not _callout_last_plate and _was_changing and change_left <= 0.0 and plates_left == 1:
		_callout_last_plate = true
		ui.set_callout(Content.totality_last_plate(), 3.5)
	_was_changing = change_left > 0.0
	if not _callout_plates_left and t_game >= 200.0 and plates_left >= 2 and not exposing and _since_last_plate() > 60.0:
		_callout_plates_left = true
		ui.set_callout(Content.totality_plates_left(plates_left), 3.5)
	if not _callout_nudged and t_game >= 45.0 and not _ever_exposed:
		_callout_nudged = true
		ui.set_callout(Content.totality_first_nudge(), 4.0)


func _since_last_plate() -> float:
	if sim.plates.is_empty():
		return INF
	var p: Dictionary = sim.plates.back()
	return t_game - (float(p.start) + float(p.duration))


func _end_totality() -> void:
	tot_done = true
	# Let any final count or plate change finish at the totality level.
	var mix_return := create_tween()
	mix_return.tween_method(
		func(db: float) -> void: AudioServer.set_bus_volume_db(_totality_ambience_bus, db),
		AudioServer.get_bus_volume_db(_totality_ambience_bus), 0.0, THIRD_CONTACT_S)
	mix_return.tween_callback(func() -> void: AudioServer.set_bus_volume_db(_totality_actions_bus, 0.0))
	_stop_night_bed()
	ui.set_prompt("")
	for cue in ["totality_drone", "totality_glass", "totality_edge"]:
		score.stop(cue, 1.5)
	var ruined: bool = sim.is_exposing()
	if ruined:
		sim.close_shutter(true)
	ui.set_totality(false)
	_sfx("third")
	ui.show_toast(L.t("第三接觸。陽光像鑽石一樣從月亮邊緣迸出來。") + (L.t("\n快門還開著——最後那張底片曝到了陽光。") if ruined else ""), 5.0)
	var duration := THIRD_CONTACT_S if _style == null else DAY_RETURN_S
	_day_return = create_tween()
	_day_return.tween_method(_update_day_return, 0.0, duration, duration)
	await get_tree().create_timer(THIRD_CONTACT_S + 1.5, false).timeout
	_say(Content.after_totality(sim.plates.size()), "after_totality")


func _update_day_return(elapsed: float) -> void:
	# The contact and its beads keep their authored timing. Only the light
	# continues to recover after that cue and into the post-totality dialogue.
	var v := minf(elapsed / THIRD_CONTACT_S, 1.0)
	var darkness := 1.0 - v * v if _style == null else 1.0 - smoothstep(0.0, DAY_RETURN_S, elapsed)
	sky_mat.set_shader_parameter("third_contact", Cues.third_contact_glint(v))
	_apply_light(1.0 - v * 0.2, darkness, t_game + v * THIRD_CONTACT_CLOUD_S, 0.0, false, true)


# ----------------------------------------------------------------------- Night

func _begin_night() -> void:
	_busy = true
	await ui.fade_to(1.0, 1.2).finished
	_setup_darkroom()
	_save_darkroom()
	await ui.show_caption(L.t("接下來的六個夜晚\n暗房裡，底片一張張沖洗出來（時間壓縮）"), 2.4).finished
	await ui.fade_to(0.0, 1.0).finished
	_busy = false
	player.can_move = true
	_refresh_objectives()
	_say(Content.night_intro(sim.plates.size()), "")
	if bot:
		bot.on_phase("night")


func _save_darkroom() -> void:
	if Checkpoint.enabled():
		Checkpoint.save("darkroom", {
			"seed": sim.run_seed, "sim": Checkpoint.darkroom_state(sim), "from_departure": _came_from_departure,
			"plate_changed": plate_changed, "comparison_fetched": _comparison_fetched,
			"workbook_seen": _departure_workbook_seen,
			"blink_hint_seen": ui.blink_hint_seen,
		})


func _restore_darkroom(data: Dictionary) -> void:
	Checkpoint.restore_darkroom(sim, data.sim)
	plate_changed = data.plate_changed
	_comparison_fetched = data.comparison_fetched
	_departure_workbook_seen = data.workbook_seen
	ui.blink_hint_seen = data.get("blink_hint_seen", false)
	ui.hide_title()
	ui.pause_enabled = true
	ui.hud.visible = true
	_setup_darkroom()
	_refresh_objectives()
	if sim.bet_pick >= 0:
		_open_viewer()
	elif sim.rule_id != "":
		_say(Content.bet_prompt(Story.bet if Story.prologue_done else {}), "bet")
	_sync_player_input()


func _setup_darkroom() -> void:
	if _day_return != null:
		_day_return.kill()
	audio_surf.stop()
	audio_birds.stop()
	_start_night_bed()
	phase = Phase.NIGHT
	world.eddington.visible = true
	world.cottingham.visible = true
	# Tab can hold the outgoing audio ramp while the authored transition continues.
	# At the black handoff, cancel any remaining voices; NIGHT is always unscored.
	for cue in ["totality_drone", "totality_glass", "totality_edge"]:
		score.stop(cue)
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
	World.night_dress(world.eddington, 0.0, Vector3(-0.52, 0.0, 0.09))
	World.night_dress(world.cottingham, -45.0, Vector3.ZERO)
	player.global_position = world.darkroom_spot + Vector3(0, 0.05, 0)
	player.velocity = Vector3.ZERO
	player.look_at_point(world.measure_pos)


func _add_departure_loupe(wb) -> void:
	# The keepsake sits at the table's east edge, clear of the normal center-line
	# ray to the measuring sheet so both interactions remain independently usable.
	var p: Vector3 = world.measure_pos + Vector3(0.40, 0.042, -0.16)
	var loupe: Node3D = wb.model("mentor_loupe", p)
	loupe.name = "AshbyBrassLoupe"
	var hotspot: Node3D = wb.hotspot(Vector3(0.32, 0.40, 0.26), p + Vector3(0, 0.19, 0), "mentor_loupe", L.t("Ashby 先生給的放大鏡。"))
	hotspot.name = "AshbyLoupeHotspot"


func _add_night_workbook() -> void:
	# Keep it on the measuring table and east of the normal sheet aim point.
	var position: Vector3 = world.measure_pos + Vector3(0.43, 0.03, 0.23)
	_night_departure_workbook = DepartureWorkbook.new()
	_night_departure_workbook.field_ledger = true
	_night_departure_workbook.name = "PríncipeDepartureWorkbook"
	_night_departure_workbook.position = position
	add_child(_night_departure_workbook)
	var hotspot: Node3D = World.new(self).hotspot(Vector3(0.42, 0.24, 0.42), position + Vector3(0, 0.10, 0), "departure_workbook", L.t("在工作簿記下你看到的天空"))
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
	if phase != Phase.CODA and not (_coda_transition and _coda_transition.is_valid()):
		return
	for tw in [_camera_turn, _coda_transition]:
		if tw and tw.is_valid():
			if open:
				tw.pause()
			else:
				tw.play()


func _end_coda() -> void:
	_stop_night_bed()
	coda_step = CodaStep.FADING
	_coda_highlight.light_energy = 0.0
	await _lamp_out_then_ending()


func _epilogue_due() -> bool:
	return _came_from_departure and Story.departure_done and not Story.epilogue_done


func _lamp_out_then_ending() -> void:
	# The epilogue plays the resolution cue at its own ending; a scene change would cut it here.
	if not _epilogue_due():
		_play_resolution()
	_busy = true
	# Lamp out, a breath of darkness, then the ending. Esc and Tab hold this beat.
	_coda_transition = create_tween().set_parallel(true).set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	_coda_transition.tween_property(world.lamp, "light_energy", 0.0, 0.7)
	_coda_transition.tween_property(world.safelight, "light_energy", 0.0, 0.7)
	_coda_transition.chain().tween_interval(0.6)
	_coda_transition.chain().tween_property(ui.fade, "color:a", 1.0, 1.3)
	await _coda_transition.finished
	if phase == Phase.CODA and OS.get_cmdline_user_args().has("--journey"):
		_paired_cables = load("res://scripts/cambridge/sundy.gd").new()
		add_child(_paired_cables)
		await _paired_cables.play_cables(ui)
		_paired_cables.queue_free()
		_paired_cables = null
	_busy = false
	if _epilogue_due():
		_stop_night_bed()
		_record_run()
		var plate := _ending_plate()
		Story.ending_plate = plate[0]
		Story.ending_plate_caption = plate[1]
		Story.epilogue_done = true
		Checkpoint.save("epilogue")
		get_tree().change_scene_to_file("res://scenes/epilogue.tscn")
		return
	_show_ending()


func _open_viewer() -> void:
	ui.comparison_recall = Content.comparison_recall(Story.plan, Story.prologue_done)
	ui.drive_note = Content.drive_note(Story.plan, Story.prologue_done, sim.drive_rate_checked)
	ui.loupe_start = Vector2(PlateRender.SIZE, PlateRender.SIZE) * 0.5 + sim.star_offsets[0] * PlateRender.SUN_PX
	ui.measurement_of = Callable(sim, "measurement")
	ui.open_viewer(sim.plates, comparison_tex, plate_textures, sim.measured)
	_sync_player_input()
	_refresh_viewer()


func _on_reading_set(i: int, px: float) -> void:
	if i < 0 or i >= sim.plates.size():
		return
	if sim.measured and sim.plates[i].get("read", false):
		return
	sim.plates[i].reading = px
	sim.plates[i].read = true
	if sim.measured and not sim.reselected_after_seeing:
		sim.first_result = sim.combined()
	_save_darkroom()
	_refresh_viewer()
	ui._select_plate(i, plate_textures[i], false)


func _refresh_viewer() -> void:
	var rows := []
	for p in sim.included_usable():
		var m: Dictionary = sim.measurement(p)
		rows.append({"label": L.t("第%d號") % p.number, "value": m.value, "sigma": m.sigma, "weak": p.quality != "good"})
	ui.chart.set_data(rows, sim.combined(), sim.measured)
	var ledger := []
	var original: int = Story.bet_1917.get("pick", -1)
	if original >= 0:
		ledger.append({"pick": original, "kind": "original", "tag":
			L.t("1917 年押的：說不準") if original == 3 else L.t("1917 年押的")})
	if sim.bet_pick >= 0:
		var tag: String
		if original == sim.bet_pick:
			ledger.clear()
			tag = L.t("押的（1917 年至今沒改）：說不準") if sim.bet_pick == 3 else L.t("押的（1917 年至今沒改）")
		elif original < 0:
			tag = L.t("1919 年押的：說不準") if sim.bet_pick == 3 else L.t("1919 年押的")
		else:
			tag = L.t("現在押的：說不準") if sim.bet_pick == 3 else L.t("現在押的")
		ledger.append({"pick": sim.bet_pick, "kind": "current", "tag": tag})
	ui.chart.set_ledger(ledger)
	var sel: int = sim.plates.filter(func(p): return p.included).size()
	var note := L.t("共 %d 張，已勾選 %d 張。\n星像要自己看：星點夠不夠五顆、有沒有拖長、有沒有被雲霧蓋住。") % [sim.plates.size(), sel]
	if sim.measured:
		var good: int = sim.count_quality("good")
		var poor: int = sim.count_quality("poor")
		var bad: int = sim.count_quality("unusable")
		note = L.t("共 %d 張：星像清楚 %d、可量但有瑕疵 %d、星不足五顆 %d。\n已勾選 %d 張。") % [sim.plates.size(), good, poor, bad, sel]
		var c: Dictionary = sim.combined()
		if c.n > 0:
			var b: Dictionary = Judgment.interval_bounds(sim)
			note += L.t("\n[color=#fd8]合併：%.2f″ ± %.2f″（兩倍誤差 %.2f–%.2f″）[/color]") % [c.value, c.sigma, b.lo, b.hi]
			note += L.t("\n細線是兩倍誤差：Eddington 的判準是，兩倍誤差之內容得下哪個預測、又排除了哪個。")
	if sim.first_result != null and sim.reselected_after_seeing:
		if sim.first_result.n > 0:
			note += L.t("\n第一次量：%.2f″ ± %.2f″") % [sim.first_result.value, sim.first_result.sigma]
		else:
			note += L.t("\n第一次量：沒有量出任何數值。")
	if sim.measured:
		var recall := Content.calibration_recall(Story.plan, Story.prologue_done)
		if recall != "":
			note += "\n" + recall
	for p in sim.plates:
		if p.included and p.usable and not p.get("read", false):
			note += L.t("\n第%d號還沒讀數，不會算進去。") % p.number
	var rule_index := ["strict", "after", "none"].find(sim.rule_id)
	ui.viewer_rule.text = L.t("你寫下的規則：%s") % Content.rules_prompt(false)[-1].choices[rule_index] if rule_index >= 0 else ""
	ui.set_viewer_note(note)
	ui.refresh_thumbs()


func _on_plate_toggled(i: int, on: bool) -> void:
	if sim.measured:
		return
	sim.plates[i].included = on
	_save_darkroom()
	_refresh_viewer()


func _on_measure() -> void:
	var sel: Array = sim.plates.filter(func(p): return p.included).map(func(p): return p.number)
	if sim.first_result == null:
		sim.first_result = sim.combined()
	if sim.measured_selection != null and sel != sim.measured_selection:
		sim.reselected_after_seeing = true
		sim.reselect_added = sel.filter(func(n): return n not in sim.measured_selection)
		sim.reselect_removed = sim.measured_selection.filter(func(n): return n not in sel)
		ui.close_viewer()
		_say([{"s": Content.E, "t": L.t("你改了選片。寫下來：為什麼？"), "key": "reselect_reason",
			"choices": [L.t("星像品質：它拖長、起霧或星不夠"), L.t("第一次的數字不合我的預期"), L.t("說不上來")]}], "reselect_reason")
		return
	if sim.measured_readings != null:
		for p in sim.plates:
			if sim.measured_readings.has(p.number) and p.reading != sim.measured_readings[p.number]:
				sim.reselected_after_seeing = true
				break
	_finish_measurement()


func _finish_measurement() -> void:
	sim.measured_selection = sim.plates.filter(func(p): return p.included).map(func(p): return p.number)
	sim.measured_readings = {}
	for p in sim.plates:
		if p.get("read", false):
			sim.measured_readings[p.number] = p.reading
	sim.measured = true
	ui.set_viewer_locked(true)
	if not sim.reselected_after_seeing:
		sim.first_result = sim.combined()
	_save_darkroom()
	_refresh_viewer()
	_refresh_objectives()


func _on_reselect() -> void:
	sim.measured = false
	_save_darkroom()
	ui.set_viewer_locked(false)
	_refresh_viewer()
	_refresh_objectives()


func _on_viewer_closed() -> void:
	ui.close_viewer()
	_sync_player_input()


func _on_report() -> void:
	if sim.plates.any(func(p): return p.included and p.usable) and sim.included_usable().is_empty():
		ui.set_viewer_note(L.t("一張都還沒讀。選中的底片要用測微器讀過，才有數字可以報告。"))
		return
	ui.set_viewer_report(true)
	_refresh_viewer()
	_start_judgment()


var _grade: Dictionary
var _verdict := -1
var _verdict_truth := -1
var _verdict_class := ""
var _verdict_hold_s := 0.0
var _verdict_hold_first_frame := false
var _pressed_eddington := false
var _telegram := 0
var _reason := 0
var _reasons: Array = []


func _offer_telegram() -> void:
	var tele := Judgment.telegram_choices()
	var rea := _reasons.map(func(r): return L.t(r.text))
	var seq := Content.judgment_prompt(tele, rea)
	if _verdict >= 0 and sim.bet_pick >= 0:
		seq.push_front(Content.dispatch_thought(sim.bet_pick))
	_say(seq, "judgment")


func _start_judgment() -> void:
	_reasons = Judgment.reasons_for(sim)
	var c: Dictionary = sim.combined()
	if c.n > 0:
		var bounds := Judgment.interval_bounds(sim)
		var interval := L.t("%.2f″ ± %.2f″，兩倍誤差是 %.2f″ 到 %.2f″") % [c.value, c.sigma, bounds.lo, bounds.hi]
		_say(Content.verdict_prompt(interval), "verdict")
	else:
		_offer_telegram()


func _after_judgment(results: Dictionary) -> void:
	ui.close_viewer()
	_telegram = results.get("telegram", 1)
	_reason = results.get("reason", 1)
	_grade = Judgment.grade(sim, Judgment.TELEGRAMS[_telegram].id, _reasons[_reason].id)
	_say([Content.telegram_record(_verdict, Judgment.telegram_choices()[_telegram],
		L.t(_reasons[_reason].text))], "telegram_record")


func _review_telegram() -> void:
	var seq := []
	if _verdict >= 0:
		var bounds := Judgment.interval_bounds(sim)
		seq.append({"s": Content.E, "t": Content.verdict_feedback(_verdict, _verdict_truth, bounds)})
		if sim.bet_pick >= 0:
			seq.append({"s": Content.E, "t": Content.bet_vs_plates(sim.bet_pick, bounds)})
	for l in _grade.presentation:
		seq.append({"s": Content.E, "t": l})
	seq.append({"s": Content.C, "t": Content.cottingham_coda(sim)})
	if _verdict >= 0 and sim.bet_pick >= 0:
		seq.append_array(Content.press_eddington(sim.bet_pick))
	_say(seq, "reaction")


func _play_resolution() -> void:
	if not _resolution_started:
		_resolution_started = true
		score.play("coda_resolution", 0.6)


## Conversion arc D1: the run snapshot the ending reads, kept out of _show_ending().
func _record_run() -> void:
	if _run_record_index >= 0:
		return
	var c: Dictionary = sim.combined()
	var reasons: Array = Judgment.REASONS if _reasons.is_empty() else _reasons
	var exposures: Array = []
	for p in sim.plates:
		exposures.append({"number": p.number, "start": p.start, "duration": p.duration,
			"included": p.included, "usable": p.usable, "quality": p.quality,
			"read": p.get("read", false),
			"reading": p.reading if p.get("read", false) else null})
	var departure_kit: bool = _came_from_departure and Story.kit_first >= 0
	_run_record_index = Story.runs.size()
	Story.runs.append({"seed": sim.run_seed, "exposures": exposures, "combined": c,
		"rule_id": sim.rule_id, "bet": Story.bet.duplicate(true), "bet_pick": sim.bet_pick,
		"verdict": _verdict, "verdict_truth": _verdict_truth, "verdict_class": _verdict_class,
		"telegram_id": Judgment.TELEGRAMS[_telegram].id,
		"reason_id": reasons[_reason].id, "reason_text": reasons[_reason].text,
		"score": _grade.get("score", 0), "clean": _grade.clean,
		"grade": _grade.duplicate(true),
		"first_result": sim.first_result.duplicate(true) if sim.first_result != null else null,
		"reselected_after_seeing": sim.reselected_after_seeing,
		"drive_rate_checked": sim.drive_rate_checked, "drive_wound": sim.drive_wound,
		"drive_error": sim.drive_error,
		"plate_total": sim.plates.size(), "plates_available": sim.plates_available(),
		"plate_counts": {"good": sim.count_quality("good"), "poor": sim.count_quality("poor"),
			"unusable": sim.count_quality("unusable")},
		"bounds": Judgment.interval_bounds(sim) if c.n > 0 else {},
		"departure_kit": departure_kit,
		"kit_line": _night_departure_workbook.kit_line if departure_kit else ""}.duplicate(true))


## The best plate the ending shows, as [texture, caption].
func _ending_plate() -> Array:
	var best := -1
	if sim.measured:
		for i in sim.plates.size():
			var p: Dictionary = sim.plates[i]
			if p.included and p.usable and (best < 0 or p.stars > sim.plates[best].stars or (p.stars == sim.plates[best].stars and p.number < sim.plates[best].number)):
				best = i
	var ending_texture: Texture2D
	var plate_caption := L.t("牛津比對底片")
	if best >= 0:
		if best >= plate_textures.size() or plate_textures[best] == null:
			plate_textures.resize(sim.plates.size())
			plate_textures[best] = PlateRender.render(sim, sim.plates[best])
		ending_texture = plate_textures[best]
		plate_caption = L.t("第 %d 號底片") % sim.plates[best].number
	else:
		if comparison_tex == null:
			comparison_tex = PlateRender.render(sim, null)
		ending_texture = comparison_tex
	return [ending_texture, plate_caption]


func _show_ending() -> void:
	_stop_night_bed()
	_play_resolution()
	phase = Phase.ENDING
	if _came_from_departure:
		Checkpoint.clear()
	else:
		Checkpoint.complete_standalone_darkroom()
	ui.pause_enabled = false
	ui.hud.visible = false
	player.can_move = false
	player.can_look = false
	ui.fade.color.a = 0.0
	_record_run()
	var ending: Dictionary = Ending.build(Story.runs[_run_record_index], Ending.story_view(Story))
	var plate := _ending_plate()
	ui.show_ending(ending.title, ending.body, ending.history, ending.review, ending.telegram, plate[0], plate[1])
	if bot:
		bot.on_phase("ending")
