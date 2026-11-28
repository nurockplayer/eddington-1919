extends SceneTree

const UI := preload("res://scripts/ui.gd")
const Main := preload("res://scripts/main.gd")
const L := preload("res://scripts/l10n.gd")

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
	var buttons := ui._title_row.get_children()
	var steps := buttons.find(ui._settings_button)
	for step in steps:
		await press(use_pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
	check(ui._settings_button.has_focus(), route + " reaches Settings")
	await press(use_pad, KEY_ENTER, JOY_BUTTON_A)
	check(ui.pause_panel.visible and ui._resume_button.has_focus(), route + " opens Settings on Back")
	await press(use_pad, KEY_RIGHT, JOY_BUTTON_DPAD_RIGHT)
	for step in 3:
		await press(use_pad, KEY_DOWN, JOY_BUTTON_DPAD_DOWN)
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


func _run() -> void:
	var dir := "user://test-ui-%d" % OS.get_process_id()
	var settings_path := dir.path_join("settings.cfg")
	check(DirAccess.make_dir_absolute(dir) == OK, "test settings directory opens")
	OS.set_environment("EDD_SETTINGS_PATH", settings_path)
	var config := ConfigFile.new()
	config.set_value("ui", "text_scale", 1.2)
	check(config.save(settings_path) == OK, "test settings are written")
	L.apply("en")
	Main._ensure_inputs()
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
