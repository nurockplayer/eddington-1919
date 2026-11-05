extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
var test_path := Settings.settings_path() + ".test_settings"
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
	_check_settings_path()
	Settings.load_settings(test_path)
	check(Settings.volumes == {"Master": 1.0, "Music": 1.0, "SFX": 1.0} and not Settings.fullscreen,
		"missing settings default to full volume and windowed")
	Settings.apply_startup()
	AudioServer.set_bus_volume_db(0, -12.0)
	Settings.apply_startup()
	check(Settings.video_apply_count == 1, "two startup calls apply video only once per process")
	check(is_zero_approx(AudioServer.get_bus_volume_db(0)), "later startup still applies audio")
	_check_video_calls()
	ScorePlayer.set_music_enabled(false, test_path)
	Settings.volumes = {"Master": 0.5, "Music": 0.25, "SFX": 0.0}
	Settings.fullscreen = true
	Settings.look_speed = 1.5
	Settings.invert_y = true
	check(Settings.save_settings(test_path) == OK, "settings save to a separate test path")
	Settings.volumes = {"Master": 1.0, "Music": 1.0, "SFX": 1.0}
	Settings.fullscreen = false
	Settings.look_speed = 1.0
	Settings.invert_y = false
	Settings.load_settings(test_path)
	check(Settings.volumes == {"Master": 0.5, "Music": 0.25, "SFX": 0.0} and Settings.fullscreen,
		"all settings roundtrip")
	check(Settings.look_speed == 1.5 and Settings.invert_y, "look settings roundtrip")
	Settings.look_speed = 1.0
	for expected in [1.5, 0.6, 1.0]:
		Settings.cycle_look_speed(test_path)
		check(Settings.look_speed == expected, "look speed cycles to %s" % expected)
	Settings.toggle_invert_y(test_path)
	check(not Settings.invert_y, "invert Y toggles")
	var cfg := ConfigFile.new()
	cfg.load(test_path)
	cfg.set_value("input", "look_speed", 9.0)
	cfg.save(test_path)
	Settings.load_settings(test_path)
	check(Settings.look_speed == 1.0, "invalid look speed resets")
	check(cfg.get_value("audio", "master_db") == 0.5 and cfg.get_value("audio", "music_db") == 0.25
		and cfg.get_value("audio", "sfx_db") == 0.0, "audio keys store linear values")
	check(not cfg.get_value("audio", "music_enabled"), "volume save preserves the music toggle")
	var video_calls := Settings.video_apply_count
	Settings.apply_audio()
	check(Settings.video_apply_count == video_calls, "apply_audio never enters the video path")
	var sfx := AudioServer.get_bus_index("SFX")
	check(sfx >= 0 and AudioServer.get_bus_send(sfx) == "Master", "SFX exists and sends to Master")
	var bus_count := AudioServer.bus_count
	Settings.ensure_sfx_bus()
	check(AudioServer.bus_count == bus_count, "SFX creation is idempotent")
	for bus in ["Master", "Music", "SFX"]:
		video_calls = Settings.video_apply_count
		Settings.set_volume(bus, 0.5, test_path)
		check(Settings.video_apply_count == video_calls, bus + " volume change never enters the video path")
		var index := AudioServer.get_bus_index(bus)
		check(absf(AudioServer.get_bus_volume_db(index) + 6.0206) < 0.01, bus + " half volume is about -6 dB")
		Settings.set_volume(bus, 0.0, test_path)
		check(AudioServer.is_bus_mute(index), bus + " zero volume mutes")
		Settings.set_volume(bus, 1.0, test_path)
		check(AudioServer.is_bus_mute(index) == (bus == "Music"), bus + " restored volume respects music toggle")
	Settings.set_volume("Music", 0.0, test_path)
	ScorePlayer.set_music_enabled(true, test_path)
	check(AudioServer.is_bus_mute(ScorePlayer.ensure_bus()), "enabling music preserves zero volume mute")
	Settings.set_volume("Music", 0.5, test_path)
	check(not AudioServer.is_bus_mute(ScorePlayer.ensure_bus()), "raising enabled music volume unmutes")
	ScorePlayer.set_music_enabled(false, test_path)
	check(AudioServer.is_bus_mute(ScorePlayer.ensure_bus()), "disabling music mutes over a nonzero volume")
	video_calls = Settings.video_apply_count
	Settings.toggle_fullscreen(test_path)
	check(Settings.video_apply_count == video_calls + 1, "fullscreen toggle applies video once")
	Settings.load_settings(test_path)
	check(not Settings.fullscreen, "fullscreen toggle persists and applies safely headless")
	# The Music row is only editable while music is on; the arrow check needs it live.
	check(ScorePlayer.set_music_enabled(true, test_path) == OK, "pause menu test enables music")
	await _check_pause_menu()
	await _check_chapter_routes()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	print("test_settings: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check_settings_path() -> void:
	var had_override := OS.has_environment("EDD_SETTINGS_PATH")
	var previous_path := OS.get_environment("EDD_SETTINGS_PATH")
	var shared_path := "user://settings.cfg"
	var shared_exists := FileAccess.file_exists(shared_path)
	var shared_bytes := FileAccess.get_file_as_bytes(shared_path) if shared_exists else PackedByteArray()
	var shared_mtime := FileAccess.get_modified_time(shared_path) if shared_exists else 0
	var override_path := ProjectSettings.globalize_path("res://.godot/settings-override-%d.cfg" % OS.get_process_id())
	OS.set_environment("EDD_SETTINGS_PATH", override_path)
	check(Settings.settings_path() == override_path and ScorePlayer.settings_path() == override_path,
		"settings and score resolve the environment override")
	Settings.text_scale = 1.2
	check(Settings.save_settings() == OK, "default save uses the environment override")
	check(ScorePlayer.set_music_enabled(false) == OK, "default music save uses the environment override")
	var cfg := ConfigFile.new()
	check(cfg.load(override_path) == OK and cfg.get_value("ui", "text_scale", 0.0) == 1.2
		and not cfg.get_value("audio", "music_enabled", true), "both writers preserve settings in the override file")
	Settings.text_scale = 0.85
	Settings.load_settings()
	check(Settings.text_scale == 1.2, "default load reads the environment override")
	cfg.set_value("audio", "music_enabled", true)
	cfg.save(override_path)
	ScorePlayer.load_settings()
	check(ScorePlayer.music_enabled(), "default music load reads the environment override")
	OS.unset_environment("EDD_SETTINGS_PATH")
	check(Settings.settings_path() == shared_path and ScorePlayer.settings_path() == shared_path,
		"without an override the shipped settings path is unchanged")
	OS.set_environment("EDD_SETTINGS_PATH", "")
	check(Settings.settings_path() == shared_path, "an empty override uses the shipped settings path")
	check(FileAccess.file_exists(shared_path) == shared_exists, "override leaves shared settings existence unchanged")
	if shared_exists:
		check(FileAccess.get_file_as_bytes(shared_path) == shared_bytes
			and FileAccess.get_modified_time(shared_path) == shared_mtime,
			"override leaves shared settings bytes and modification time unchanged")
	if had_override:
		OS.set_environment("EDD_SETTINGS_PATH", previous_path)
	else:
		OS.unset_environment("EDD_SETTINGS_PATH")
	DirAccess.remove_absolute(override_path)
	ScorePlayer.load_settings()


func _check_video_calls() -> void:
	var previous_call := Settings.video_call
	var previous_fullscreen := Settings.fullscreen
	var calls: Array = []
	Settings.video_call = func(method: StringName, arguments: Array): calls.append([method, arguments])
	Settings.fullscreen = false
	Settings.apply_video()
	check(calls == [[&"window_set_mode", [DisplayServer.WINDOW_MODE_WINDOWED]],
		[&"window_set_flag", [DisplayServer.WINDOW_FLAG_BORDERLESS, false]]],
		"windowed video sets mode then clears borderless")
	calls.clear()
	Settings.fullscreen = true
	Settings.apply_video()
	check(calls == [[&"window_set_mode", [DisplayServer.WINDOW_MODE_FULLSCREEN]]],
		"fullscreen video sets mode without clearing borderless")
	Settings.video_call = previous_call
	Settings.fullscreen = previous_fullscreen


func _check_routes(node: Node, gramophone: Node = null) -> int:
	var count := 0
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		var expected := "Music" if node == gramophone or node.get_parent() is ScorePlayer else "SFX"
		check(node.bus == expected, "%s final bus is %s (got %s)" % [node.get_path(), expected, node.bus])
		count += 1
	for child in node.get_children():
		count += _check_routes(child, gramophone)
	return count


func _check_chapter_routes() -> void:
	for script in ["director.gd", "departure_director.gd"]:
		var video_calls := Settings.video_apply_count
		var chapter = load("res://scripts/cambridge/" + script).new()
		root.add_child(chapter)
		await process_frame
		check(Settings.video_apply_count == video_calls, script + " startup does not reapply video")
		check(chapter.is_node_ready(), script + " ready before routing checks")
		var gramophone: Node = null
		if script == "director.gd":
			chapter._gramophone_start()
			await process_frame
			gramophone = chapter._gramophone
			check(is_instance_valid(gramophone), "gramophone exists before live routing check")
			Settings.set_volume("Music", 0.5, test_path)
			var music_bus := AudioServer.get_bus_index(gramophone.bus)
			check(absf(AudioServer.get_bus_volume_db(music_bus) + 6.0206) < 0.01, "music slider controls the gramophone bus")
			ScorePlayer.set_music_enabled(false, test_path)
			check(AudioServer.is_bus_mute(music_bus), "music off mutes the gramophone bus")
			ScorePlayer.set_music_enabled(true, test_path)
			check(not AudioServer.is_bus_mute(music_bus), "music on restores the gramophone bus")
		check(_check_routes(chapter, gramophone) > 0, script + " has live audio players")
		chapter.free()
	ScorePlayer.load_settings()
	Settings.load_settings()
	Settings.apply_audio()


func _check_pause_menu() -> void:
	# Exercise real input and persistence while preserving the user's settings bytes.
	var had_settings := FileAccess.file_exists(Settings.settings_path())
	var original := FileAccess.get_file_as_bytes(Settings.settings_path()) if had_settings else PackedByteArray()
	var startup_video_calls := Settings.video_apply_count
	var main = load("res://scripts/main.gd").new()
	root.add_child(main)
	await process_frame
	check(Settings.video_apply_count == startup_video_calls, "1919 startup does not reapply video")
	check(main.is_node_ready() and _check_routes(main) > 0, "1919 has live audio players after ready")
	var ui = main.ui
	var video_calls := Settings.video_apply_count
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
	check(Settings.video_apply_count == video_calls, "pause sliders never enter the video path")
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
	check(Settings.video_apply_count == video_calls + 1, "F11 applies video once")
	check(ui.fullscreen_button.text == ("全螢幕：開" if Settings.fullscreen else "全螢幕：關"), "F11 updates the button")
	ui.fullscreen_button.pressed.emit()
	check(Settings.fullscreen == before, "fullscreen button toggles back")
	check(Settings.video_apply_count == video_calls + 2, "fullscreen button applies video once")
	ui.toggle_pause()
	ui.fullscreen_button.text = "stale"
	ui.toggle_pause()
	check(ui.fullscreen_button.text == ("全螢幕：開" if Settings.fullscreen else "全螢幕：關"), "opening pause refreshes the fullscreen button")
	ui.toggle_pause()
	main.free()
	if had_settings:
		var file := FileAccess.open(Settings.settings_path(), FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.settings_path()))
	ScorePlayer.load_settings()
	Settings.load_settings()
	Settings.apply_audio()
	Settings.apply_video()


func cfg_reload_check(bus: String, value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(Settings.settings_path())
	check(is_equal_approx(cfg.get_value("audio", Settings.VOLUME_KEYS[bus]), value), bus + " UI saves immediately")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)) - linear_to_db(value)) < 0.01,
		bus + " UI applies immediately")
