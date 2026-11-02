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
		Settings.set_volume(bus, 0.5, TEST_PATH)
		check(Settings.video_apply_count == video_calls, bus + " volume change never enters the video path")
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
	video_calls = Settings.video_apply_count
	Settings.toggle_fullscreen(TEST_PATH)
	check(Settings.video_apply_count == video_calls + 1, "fullscreen toggle applies video once")
	Settings.load_settings(TEST_PATH)
	check(not Settings.fullscreen, "fullscreen toggle persists and applies safely headless")
	await _check_pause_menu()
	await _check_chapter_routes()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("test_settings: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


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
		var chapter = load("res://scripts/cambridge/" + script).new()
		root.add_child(chapter)
		await process_frame
		check(chapter.is_node_ready(), script + " ready before routing checks")
		var gramophone: Node = null
		if script == "director.gd":
			chapter._gramophone_start()
			await process_frame
			gramophone = chapter._gramophone
			check(is_instance_valid(gramophone), "gramophone exists before live routing check")
			Settings.set_volume("Music", 0.5, TEST_PATH)
			var music_bus := AudioServer.get_bus_index(gramophone.bus)
			check(absf(AudioServer.get_bus_volume_db(music_bus) + 6.0206) < 0.01, "music slider controls the gramophone bus")
			ScorePlayer.set_music_enabled(false, TEST_PATH)
			check(AudioServer.is_bus_mute(music_bus), "music off mutes the gramophone bus")
			ScorePlayer.set_music_enabled(true, TEST_PATH)
			check(not AudioServer.is_bus_mute(music_bus), "music on restores the gramophone bus")
		check(_check_routes(chapter, gramophone) > 0, script + " has live audio players")
		chapter.free()
	ScorePlayer.load_settings()
	Settings.load_settings()
	Settings.apply_audio()


func _check_pause_menu() -> void:
	# Exercise real input and persistence while preserving the user's settings bytes.
	var had_settings := FileAccess.file_exists(Settings.SETTINGS_PATH)
	var original := FileAccess.get_file_as_bytes(Settings.SETTINGS_PATH) if had_settings else PackedByteArray()
	var main = load("res://scripts/main.gd").new()
	root.add_child(main)
	await process_frame
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
		var file := FileAccess.open(Settings.SETTINGS_PATH, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.SETTINGS_PATH))
	ScorePlayer.load_settings()
	Settings.load_settings()
	Settings.apply_audio()
	Settings.apply_video()


func cfg_reload_check(bus: String, value: float) -> void:
	var cfg := ConfigFile.new()
	cfg.load(Settings.SETTINGS_PATH)
	check(is_equal_approx(cfg.get_value("audio", Settings.VOLUME_KEYS[bus]), value), bus + " UI saves immediately")
	check(absf(AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus)) - linear_to_db(value)) < 0.01,
		bus + " UI applies immediately")
