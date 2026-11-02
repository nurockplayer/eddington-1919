class_name GameSettings
extends RefCounted

const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const SETTINGS_PATH := ScorePlayer.SETTINGS_PATH
const VOLUME_KEYS := {"Master": "master_db", "Music": "music_db", "SFX": "sfx_db"}

static var volumes := {"Master": 1.0, "Music": 1.0, "SFX": 1.0}
static var fullscreen := false


static func ensure_sfx_bus() -> int:
	var index := AudioServer.get_bus_index("SFX")
	if index < 0:
		AudioServer.add_bus()
		index = AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, "SFX")
		AudioServer.set_bus_send(index, "Master")
	return index


static func load_settings(path := SETTINGS_PATH) -> void:
	var cfg := ConfigFile.new()
	cfg.load(path)
	for bus in VOLUME_KEYS:
		volumes[bus] = clampf(float(cfg.get_value("audio", VOLUME_KEYS[bus], 1.0)), 0.0, 1.0)
	fullscreen = bool(cfg.get_value("video", "fullscreen", false))


static func save_settings(path := SETTINGS_PATH) -> Error:
	var cfg := ConfigFile.new()
	cfg.load(path)
	for bus in VOLUME_KEYS:
		cfg.set_value("audio", VOLUME_KEYS[bus], volumes[bus])
	cfg.set_value("video", "fullscreen", fullscreen)
	return cfg.save(path)


static func apply() -> void:
	ScorePlayer.ensure_bus()
	ensure_sfx_bus()
	for bus in VOLUME_KEYS:
		var index := AudioServer.get_bus_index(bus)
		var volume: float = volumes[bus]
		AudioServer.set_bus_volume_db(index, linear_to_db(volume))
		AudioServer.set_bus_mute(index, volume == 0.0 or (bus == "Music" and not ScorePlayer.music_enabled()))
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


static func set_volume(bus: String, value: float, path := SETTINGS_PATH) -> Error:
	volumes[bus] = clampf(value, 0.0, 1.0)
	apply()
	return save_settings(path)


static func toggle_fullscreen(path := SETTINGS_PATH) -> Error:
	fullscreen = not fullscreen
	apply()
	return save_settings(path)
