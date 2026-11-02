extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const TEST_PATH := "user://test_settings.cfg"
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	Settings.load_settings(TEST_PATH)
	check(Settings.volumes == {"Master": 1.0, "Music": 1.0, "SFX": 1.0} and not Settings.fullscreen,
		"missing settings default to full volume and windowed")
	ScorePlayer.set_music_enabled(false, TEST_PATH)
	Settings.volumes = {"Master": 0.5, "Music": 0.25, "SFX": 0.0}
	Settings.fullscreen = true
	check(Settings.save_settings(TEST_PATH) == OK, "settings save to a separate test path")
	Settings.volumes = {"Master": 1.0, "Music": 1.0, "SFX": 1.0}
	Settings.fullscreen = false
	Settings.load_settings(TEST_PATH)
	check(Settings.volumes == {"Master": 0.5, "Music": 0.25, "SFX": 0.0} and Settings.fullscreen,
		"all settings roundtrip")
	var cfg := ConfigFile.new()
	cfg.load(TEST_PATH)
	check(cfg.get_value("audio", "master_db") == 0.5 and cfg.get_value("audio", "music_db") == 0.25
		and cfg.get_value("audio", "sfx_db") == 0.0, "audio keys store linear values")
	check(not cfg.get_value("audio", "music_enabled"), "volume save preserves the music toggle")
	Settings.apply()
	var sfx := AudioServer.get_bus_index("SFX")
	check(sfx >= 0 and AudioServer.get_bus_send(sfx) == "Master", "SFX exists and sends to Master")
	var bus_count := AudioServer.bus_count
	Settings.ensure_sfx_bus()
	check(AudioServer.bus_count == bus_count, "SFX creation is idempotent")
	for bus in ["Master", "Music", "SFX"]:
		Settings.set_volume(bus, 0.5, TEST_PATH)
		var index := AudioServer.get_bus_index(bus)
		check(absf(AudioServer.get_bus_volume_db(index) + 6.0206) < 0.01, bus + " half volume is about -6 dB")
		Settings.set_volume(bus, 0.0, TEST_PATH)
		check(AudioServer.is_bus_mute(index), bus + " zero volume mutes")
		Settings.set_volume(bus, 1.0, TEST_PATH)
		check(AudioServer.is_bus_mute(index) == (bus == "Music"), bus + " restored volume respects music toggle")
	Settings.set_volume("Music", 0.0, TEST_PATH)
	ScorePlayer.set_music_enabled(true, TEST_PATH)
	check(AudioServer.is_bus_mute(ScorePlayer.ensure_bus()), "enabling music preserves zero volume mute")
	Settings.set_volume("Music", 0.5, TEST_PATH)
	check(not AudioServer.is_bus_mute(ScorePlayer.ensure_bus()), "raising enabled music volume unmutes")
	ScorePlayer.set_music_enabled(false, TEST_PATH)
	check(AudioServer.is_bus_mute(ScorePlayer.ensure_bus()), "disabling music mutes over a nonzero volume")
	Settings.toggle_fullscreen(TEST_PATH)
	Settings.load_settings(TEST_PATH)
	check(not Settings.fullscreen, "fullscreen toggle persists and applies safely headless")
	_check_routes("res://scripts")
	await _check_pause_menu()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("test_settings: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check_routes(path: String) -> void:
	var pattern := RegEx.new()
	pattern.compile("(\\w+)\\s*:?= AudioStreamPlayer(?:2D|3D)?\\.new\\(\\)")
	for file in DirAccess.get_files_at(path):
		if not file.ends_with(".gd") or file == "score_player.gd":
			continue
		var lines := FileAccess.get_file_as_string(path.path_join(file)).split("\n")
		for i in lines.size():
			var found := pattern.search(lines[i])
			if found:
				check(i + 1 < lines.size() and lines[i + 1].strip_edges() == found.get_string(1) + '.bus = "SFX"',
					"%s:%d routes its new player to SFX" % [file, i + 1])
	for directory in DirAccess.get_directories_at(path):
		_check_routes(path.path_join(directory))


func _check_pause_menu() -> void:
	# Exercise real input and persistence while preserving the user's settings bytes.
	var had_settings := FileAccess.file_exists(Settings.SETTINGS_PATH)
	var original := FileAccess.get_file_as_bytes(Settings.SETTINGS_PATH) if had_settings else PackedByteArray()
	var main = load("res://scripts/main.gd").new()
	root.add_child(main)
	await process_frame
	var ui = main.ui
	ui.toggle_pause()
	await process_frame
	var sliders: Array[Node] = ui.pause_panel.find_children("*", "HSlider", true, false)
	check(sliders.size() == 3, "real pause menu has three sliders")
	var focus: Control = root.gui_get_focus_owner()
	check(focus is Button and focus.text == "繼續", "opening pause focuses Continue")
	check(focus.find_next_valid_focus().find_next_valid_focus() == sliders[0], "keyboard/gamepad focus reaches the sliders")
	for i in sliders.size():
		var slider: HSlider = sliders[i]
		check(slider.focus_mode == Control.FOCUS_ALL and slider.min_value == 0.0
			and slider.max_value == 1.0 and slider.step == 0.05, "slider range, step and focus")
		slider.value = 0.5
		slider.grab_focus()
		var right := InputEventKey.new()
		right.keycode = KEY_RIGHT
		right.pressed = true
		root.push_input(right)
		await process_frame
		var bus: String = ["Master", "Music", "SFX"][i]
		cfg_reload_check(bus, slider.value)
		check(is_equal_approx(slider.value, 0.55), "right arrow adjusts " + bus)
	var left := InputEventJoypadButton.new()
	left.button_index = JOY_BUTTON_DPAD_LEFT
	left.pressed = true
	Input.parse_input_event(left)
	await process_frame
	await process_frame
	left.pressed = false
	Input.parse_input_event(left)
	check(is_equal_approx(sliders[2].value, 0.5), "gamepad left adjusts the focused slider")
	var before: bool = Settings.fullscreen
	var f11 := InputEventKey.new()
	f11.physical_keycode = KEY_F11
	f11.pressed = true
	root.push_input(f11)
	await process_frame
	check(Settings.fullscreen != before, "F11 toggles while paused")
	check(ui.fullscreen_button.text == ("全螢幕：開" if Settings.fullscreen else "全螢幕：關"), "F11 updates the button")
	ui.fullscreen_button.pressed.emit()
	check(Settings.fullscreen == before, "fullscreen button toggles back")
	ui.toggle_pause()
	main.free()
	if had_settings:
		var file := FileAccess.open(Settings.SETTINGS_PATH, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.SETTINGS_PATH))
	ScorePlayer.load_settings()
	Settings.load_settings()
	Settings.apply()


func cfg_reload_check(bus: String, value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(Settings.SETTINGS_PATH)
	check(is_equal_approx(cfg.get_value("audio", Settings.VOLUME_KEYS[bus]), value), bus + " UI saves immediately")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)) - linear_to_db(value)) < 0.01,
		bus + " UI applies immediately")
