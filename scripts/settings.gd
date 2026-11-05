class_name GameSettings
extends RefCounted

const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const LOOK_SPEEDS := [0.6, 1.0, 1.5]
const TEXT_SCALES := [0.85, 1.0, 1.2]

const VOLUME_KEYS := {"Master": "master_db", "Music": "music_db", "SFX": "sfx_db"}

static var volumes := {"Master": 1.0, "Music": 1.0, "SFX": 1.0}
static var quality := "standard"
static var text_scale := 1.0
static var look_speed := 1.0
static var invert_y := false
static var reduced_motion := false
static var fullscreen := false
static var video_apply_count := 0
static var video_call: Callable = _window_call
static var _video_applied := false


static func settings_path() -> String:
	return ScorePlayer.settings_path()


static func fs(px: int) -> int:
	return roundi(px * text_scale)


static func track_font(node: Control, px: int) -> void:
	node.set_meta("base_font_size", px)
	node.add_to_group("scaled_text")
	_apply_font(node)


static func _apply_font(node: Control) -> void:
	var size := fs(int(node.get_meta("base_font_size")))
	if node is RichTextLabel:
		for key in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
			node.add_theme_font_size_override(key, size)
	else:
		node.add_theme_font_size_override("font_size", size)


static func refresh_fonts(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("scaled_text"):
		if is_instance_valid(node):
			_apply_font(node)


static func ensure_sfx_bus() -> int:
	var index := AudioServer.get_bus_index("SFX")
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, "SFX")
		AudioServer.set_bus_send(index, "Master")
	return index


static func load_settings(path := settings_path()) -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)
	for bus in VOLUME_KEYS:
		volumes[bus] = clampf(float(cfg.get_value("audio", VOLUME_KEYS[bus], 1.0)), 0.0, 1.0)
	quality = str(cfg.get_value("video", "quality", "standard"))
	if quality not in ["low", "standard"]:
		quality = "standard"
	fullscreen = bool(cfg.get_value("video", "fullscreen", false))
	look_speed = float(cfg.get_value("input", "look_speed", 1.0))
	if look_speed not in LOOK_SPEEDS:
		look_speed = 1.0
	invert_y = bool(cfg.get_value("input", "invert_y", false))
	reduced_motion = bool(cfg.get_value("ui", "reduced_motion", false))
	text_scale = float(cfg.get_value("ui", "text_scale", 1.0))
	if text_scale not in TEXT_SCALES:
		text_scale = 1.0


static func save_settings(path := settings_path()) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path)
	for bus in VOLUME_KEYS:
		cfg.set_value("audio", VOLUME_KEYS[bus], volumes[bus])
	cfg.set_value("video", "quality", quality)
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("ui", "text_scale", text_scale)
	cfg.set_value("ui", "reduced_motion", reduced_motion)
	cfg.set_value("input", "look_speed", look_speed)
	cfg.set_value("input", "invert_y", invert_y)
	return cfg.save(path)


static func apply_startup() -> void:
	apply_audio()
	apply_quality(Engine.get_main_loop() as SceneTree)
	if not _video_applied:
		apply_video()
		_video_applied = true


static func apply_audio() -> void:
	ScorePlayer.ensure_bus()
	ensure_sfx_bus()
	for bus in VOLUME_KEYS:
		var index := AudioServer.get_bus_index(bus)
		var volume: float = volumes[bus]
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))
		AudioServer.set_bus_mute(index, volume == 0.0 or (bus == "Music" and not ScorePlayer.music_enabled()))


static func apply_video() -> void:
	video_apply_count += 1
	video_call.call(&"window_set_mode", [DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED])
	if not fullscreen:
		video_call.call(&"window_set_flag", [DisplayServer.WINDOW_FLAG_BORDERLESS, false])


static func _window_call(method: StringName, arguments: Array) -> void:
	if DisplayServer.get_name() != "headless":
		DisplayServer.callv(method, arguments)


static func sync_fullscreen() -> void:
	if DisplayServer.get_name() != "headless":
		fullscreen = DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN, DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]


static func set_volume(bus: String, value: float, path := settings_path()) -> Error:
	volumes[bus] = clampf(value, 0.0, 1.0)
	apply_audio()
	return save_settings(path)


static func toggle_fullscreen(path := settings_path()) -> Error:
	sync_fullscreen()
	fullscreen = not fullscreen
	apply_video()
	return save_settings(path)


static func cycle_text_scale(path := settings_path()) -> Error:
	text_scale = TEXT_SCALES[(TEXT_SCALES.find(text_scale) + 1) % TEXT_SCALES.size()]
	return save_settings(path)


static func cycle_look_speed(path := settings_path()) -> Error:
	look_speed = LOOK_SPEEDS[(LOOK_SPEEDS.find(look_speed) + 1) % LOOK_SPEEDS.size()]
	return save_settings(path)


static func toggle_invert_y(path := settings_path()) -> Error:
	invert_y = not invert_y
	return save_settings(path)


static func toggle_reduced_motion(path := settings_path()) -> Error:
	reduced_motion = not reduced_motion
	return save_settings(path)


static func cycle_quality(path := settings_path()) -> Error:
	quality = "low" if quality == "standard" else "standard"
	return save_settings(path)


static func apply_quality(tree: SceneTree) -> void:
	var low := quality == "low"
	tree.root.scaling_3d_scale = 0.75 if low else 1.0
	tree.root.msaa_3d = Viewport.MSAA_DISABLED if low else ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d")
	for node in tree.get_nodes_in_group("quality_env"):
		node.environment.ssao_enabled = false if low else node.get_meta("standard_ssao")
	for light in tree.get_nodes_in_group("quality_shadow"):
		light.shadow_enabled = false if low else light.get_meta("standard_shadow")
