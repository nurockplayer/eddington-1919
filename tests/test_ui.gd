extends SceneTree

const UI := preload("res://scripts/ui.gd")
const L := preload("res://scripts/l10n.gd")
const Settings := preload("res://scripts/settings.gd")

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func press(use_pad: bool, key: Key, button: JoyButton) -> void:
	var event: InputEvent
	if use_pad:
		var pad_event := InputEventJoypadButton.new()
		pad_event.button_index = button
		event = pad_event
	else:
		var key_event := InputEventKey.new()
		key_event.keycode = key
		key_event.physical_keycode = key
		event = key_event
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _open_title_settings(ui: UI, use_pad: bool, route: String) -> int:
	var steps := ui._title_row.get_children().find(ui._settings_button)
	for step in steps:
		await press(use_pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
	check(ui._settings_button.has_focus(), route + " reaches Settings")
	await press(use_pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui.pause_panel.visible and ui._resume_button.has_focus(), route + " opens Settings on Back")
	return steps


func _title_route(saved: bool, use_pad: bool) -> void:
	var route := "%s title / %s" % ["saved" if saved else "fresh", "pad" if use_pad else "keyboard"]
	var ui := UI.new()
	root.add_child(ui)
	for frame in 4:
		await process_frame
	var entry := ui.continue_btn if saved else ui.prologue_btn
	var selected: Array[Button] = []
	ui.prologue_pressed.connect(func(): selected.append(ui.prologue_btn))
	ui.continue_pressed.connect(func(): selected.append(ui.continue_btn))
	check(root.gui_get_focus_owner() == entry, route + " starts on the expected entry")
	var steps := await _open_title_settings(ui, use_pad, route)
	for step in 16:
		await press(use_pad, KEY_DOWN, JOY_BUTTON_DPAD_DOWN)
		var focused := root.gui_get_focus_owner() as Button
		if focused and focused.text == L.t("操作說明"):
			break
	var help_trigger := root.gui_get_focus_owner()
	await press(use_pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui.help_panel.visible, route + " opens Controls from Settings")
	await press(use_pad, KEY_ESCAPE, JOY_BUTTON_B)
	check(not ui.help_panel.visible and ui.pause_panel.visible
		and root.gui_get_focus_owner() == help_trigger, route + " first Back returns to Controls")
	await press(use_pad, KEY_ESCAPE, JOY_BUTTON_B)
	check(not ui.pause_panel.visible and ui._settings_button.has_focus(),
		route + " second Back returns to Settings on title")
	for step in steps:
		await press(use_pad, KEY_LEFT, JOY_BUTTON_DPAD_LEFT)
	await press(use_pad, KEY_ENTER, JOY_BUTTON_A)
	check(selected == [entry], route + " selects the expected entry")
	ui.queue_free()
	await process_frame


func _ending_route(use_pad: bool) -> void:
	var route := "ending / %s" % ("pad" if use_pad else "keyboard")
	var ui := UI.new()
	root.add_child(ui)
	ui.hide_title()
	ui.show_ending("Ending", "Narrative", "History", "Review")
	for frame in 4:
		await process_frame
	for section: Array in [[ui.ending_review_toggle, ui.ending_review], [ui.ending_history_toggle, ui.ending_history]]:
		var trigger: Button = section[0]
		var text: RichTextLabel = section[1]
		await press(use_pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
		await press(use_pad, KEY_ENTER, JOY_BUTTON_A)
		check(text.visible and trigger.has_focus(), route + " opens the section on its trigger")
		await press(use_pad, KEY_ESCAPE, JOY_BUTTON_B)
		check(not text.visible and trigger.has_focus(), route + " closes the section on its trigger")
	ui.queue_free()
	await process_frame


func _settings_route(locale: String, use_pad: bool, settings_path: String) -> void:
	var route := "%s / %s" % [locale, "pad" if use_pad else "keyboard"]
	L.apply(locale)
	var config := ConfigFile.new()
	config.set_value("ui", "text_scale", 1.2)
	check(config.save(settings_path) == OK, route + " starts with isolated max-text settings")
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	var ui: UI = game.ui
	for frame in 4:
		await process_frame
	await _open_title_settings(ui, use_pad, route)
	var targets := {
		ui.hold_button: "hold",
		ui.totality_pace_button: "pace",
		ui.text_size_button: "text scale",
	}
	for button: Button in ui.pause_scroll.find_children("*", "Button", true, false):
		if button.text == L.t("減少晃動：關"):
			targets[button] = "reduced motion"
		elif button.text == L.t("測微器大十字線：關"):
			targets[button] = "large crosshair"
	var changed: Array[String] = []
	for step in 16:
		await press(use_pad, KEY_DOWN, JOY_BUTTON_DPAD_DOWN)
		var row := root.gui_get_focus_owner()
		if targets.has(row):
			var setting: String = targets[row]
			var presses := Settings.TEXT_SCALES.size() if row == ui.text_size_button else 1
			for i in presses:
				await press(use_pad, KEY_ENTER, JOY_BUTTON_A)
				check(row.has_focus() and ui.pause_scroll.get_global_rect().grow(1).encloses(row.get_global_rect()),
					"%s keeps changed %s row focused and visible" % [route, setting])
				if row == ui.text_size_button:
					check(Settings.text_scale == Settings.TEXT_SCALES[i], route + " changes text size")
			changed.append(setting)
		if row == ui.language_button:
			break
	check(changed.size() == 5, route + " changes all five settings with Down and Accept")
	check(ui.language_button.has_focus()
		and ui.pause_scroll.get_global_rect().grow(1).encloses(ui.language_button.get_global_rect()),
		route + " reaches the end of the scroll")
	await press(use_pad, KEY_ESCAPE, JOY_BUTTON_B)
	await press(use_pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui.pause_panel.visible and ui._resume_button.has_focus(), route + " reopens on Back")
	check(_settings_retained(), route + " values survive reopening")
	await press(use_pad, KEY_ESCAPE, JOY_BUTTON_B)
	for step in 2:
		await press(use_pad, KEY_LEFT, JOY_BUTTON_DPAD_LEFT)
	await press(use_pad, KEY_ENTER, JOY_BUTTON_A)
	await create_timer(0.5).timeout
	check(not ui.title_panel.visible and ui.pause_enabled, route + " enters play from the title")
	Settings.load_settings()
	check(_settings_retained(), route + " values persist on disk")
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _settings_retained() -> bool:
	return Settings.text_scale == 1.2 and Settings.slower_totality and Settings.reduced_motion \
		and Settings.hold_toggle and Settings.mic_large_cross


func _run() -> void:
	var dir := "user://test-ui-%d" % OS.get_process_id()
	var settings_path := dir.path_join("settings.cfg")
	check(DirAccess.make_dir_absolute(dir) == OK, "test settings directory opens")
	OS.set_environment("EDD_SETTINGS_PATH", settings_path)
	var config := ConfigFile.new()
	config.set_value("ui", "text_scale", 1.2)
	check(config.save(settings_path) == OK, "test settings are written")
	L.apply("en")
	var main := load("res://scripts/main.gd")
	main._ensure_inputs()
	root.size = Vector2i(1280, 720)
	for locale in L.LOCALES:
		for use_pad in [false, true]:
			await _settings_route(locale, use_pad, settings_path)
	L.apply("en")
	Checkpoint.force_enabled = true
	for saved in [false, true]:
		if saved:
			Checkpoint.save("departure")
		for use_pad in [false, true]:
			await _title_route(saved, use_pad)
	for use_pad in [false, true]:
		await _ending_route(use_pad)
	Checkpoint.clear()
	DirAccess.remove_absolute(settings_path)
	DirAccess.remove_absolute(dir)
	print("test_ui: %d/%d checks passed" % [checks - failures, checks])
	quit(1 if failures else 0)
