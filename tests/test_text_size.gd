extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const UI := preload("res://scripts/ui.gd")
const Content := preload("res://scripts/content.gd")
const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Checklist := preload("res://scripts/cambridge/departure_checklist.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
const C17 := preload("res://scripts/cambridge/content_1917.gd")
const TEST_PATH := "user://test_text_size.cfg"
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _press_a() -> void:
	var event := InputEventJoypadButton.new()
	event.button_index = JOY_BUTTON_A
	event.pressed = true
	root.push_input(event)
	await process_frame
	event.pressed = false
	root.push_input(event)
	await process_frame


func _run() -> void:
	var had_settings := FileAccess.file_exists(Settings.SETTINGS_PATH)
	var original := FileAccess.get_file_as_bytes(Settings.SETTINGS_PATH) if had_settings else PackedByteArray()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	Settings.load_settings(TEST_PATH)
	check(Settings.text_scale == 1.0, "missing setting defaults to standard")
	for scale in Settings.TEXT_SCALES:
		Settings.text_scale = scale
		check(Settings.save_settings(TEST_PATH) == OK, "save text scale %s" % scale)
		Settings.text_scale = 0.0
		Settings.load_settings(TEST_PATH)
		check(Settings.text_scale == scale, "text scale %s roundtrips" % scale)
	var cfg := ConfigFile.new()
	cfg.load(TEST_PATH)
	check(cfg.get_value("ui", "text_scale") == 1.2, "persisted key is ui/text_scale")
	cfg.set_value("ui", "text_scale", -1.0)
	cfg.save(TEST_PATH)
	Settings.load_settings(TEST_PATH)
	check(Settings.text_scale == 1.0, "invalid stored scale defaults to standard")
	Settings.load_settings()
	Settings.text_scale = 1.0
	Settings.save_settings()
	load("res://scripts/main.gd")._ensure_inputs()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var ui := UI.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(ui)
	await process_frame
	var overlay := Overlay.new()
	root.add_child(overlay)
	var checklist := Checklist.new()
	root.add_child(checklist)
	checklist.open()
	var slip_value: RichTextLabel = checklist._smudge.get_parent()
	var hand := slip_value.get_theme_font("normal_font")
	var standard_smudge_position := checklist._smudge.position
	var standard_smudge_size := checklist._smudge.size
	check(absf(standard_smudge_position.x - (hand.get_string_size("x 41.27　y ", HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x - 4)) <= 0.5, "standard smudge aligns with 25 px prefix")
	ui.hide_title()
	ui.set_objectives("測量底片")
	ui.play([C17.trial_task()[3]])
	for frame in 4:
		await process_frame
	check(root.get_visible_rect().size == Vector2(1280, 720), "layout runs at 1280×720")
	check(ui.text_label.get_theme_font_size("normal_font_size") == 21, "standard dialogue is 21 px")
	ui.toggle_pause()
	var focus := root.gui_get_focus_owner() as Control
	for step in 10:
		if focus == ui.text_size_button:
			break
		focus = focus.find_next_valid_focus()
	check(focus == ui.text_size_button and focus.focus_mode == Control.FOCUS_ALL,
		"pause focus order reaches text size button")
	ui.text_size_button.grab_focus()
	await _press_a()
	check(Settings.text_scale == 1.2 and ui.text_size_button.text == "文字大小：大", "gamepad A cycles standard to large once")
	check(overlay.buttons.flip.get_theme_font_size("font_size") == 22, "large overlay button scales from 18 to 22 px")
	check(checklist.plate_lines[0].get_theme_font_size("font_size") == 22 and checklist.values[0].get_theme_font_size("bold_font_size") == 30, "large checklist label and rich text scale")
	check(absf(checklist._smudge.position.x - (hand.get_string_size("x 41.27　y ", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x - 4)) <= 0.5, "large smudge aligns with 30 px prefix")
	check(absf(checklist._smudge.size.x - (hand.get_string_size("16.83", HORIZONTAL_ALIGNMENT_LEFT, -1, 30).x + 8)) <= 0.5 and checklist._smudge.size.x > standard_smudge_size.x and checklist._smudge.size.y == 36, "large smudge scales with number")
	check(ui.theme_res.default_font_size == 25, "large theme is 25 px")
	check(ui.text_label.get_theme_font_size("normal_font_size") == 25, "visible dialogue updates to 25 px")
	check(ui.objectives.get_theme_font_size("normal_font_size") == 22, "visible objectives scale from 18 to 22 px")
	check(ui.clock_label.get_theme_font_size("font_size") == 29, "HUD clock scales from 24 to 29 px")
	check(ui.log_text.get_theme_font_size("normal_font_size") == 25, "history inherits scaled theme")
	check(ui.viewer_note.get_theme_font_size("normal_font_size") == 18, "viewer note scales")
	check(ui.ending_title.get_theme_font_size("font_size") == 53
		and ui.ending_text.get_theme_font_size("normal_font_size") == 23, "ending scales")
	var credits := ui.credits_scroll.find_children("*", "RichTextLabel", true, false)[0] as RichTextLabel
	check(credits.get_theme_font_size("normal_font_size") == 22, "credits scale")
	for frame in 4:
		await process_frame
	for button in ui.pause_panel.find_children("*", "Button", true, false):
		check(root.get_visible_rect().encloses(button.get_global_rect()), "large pause button fits: " + button.text)
	ui.toggle_pause()
	var entries := [C17.trial_task()[3], Content.rules_prompt(true)[-1]]
	entries.append_array(Content.judgment_prompt([
		"ECLIPSE SPLENDID. EINSTEIN CONFIRMED.", "THROUGH CLOUD. HOPEFUL.",
		"THROUGH CLOUD. STARS FEW. RESULT UNDECIDED.", "CLOUD. NO RESULTS."
	], []).slice(0, 2))
	for entry in entries:
		ui.play([entry])
		for frame in 4:
			await process_frame
		for button in ui._choice_buttons:
			check(button.get_theme_font_size("font_size") == 24, "new choices use large font")
			check(root.get_visible_rect().encloses(button.get_global_rect()),
				"large choice fits 1280×720: %s %s" % [button.text, button.get_global_rect()])
	ui.toggle_pause()
	ui.text_size_button.grab_focus()
	await _press_a()
	check(Settings.text_scale == 0.85 and ui.text_size_button.text == "文字大小：小", "large cycles to small")
	check(ui.text_label.get_theme_font_size("normal_font_size") == 18, "small dialogue rounds to 18 px")
	await _press_a()
	check(Settings.text_scale == 1.0 and ui.text_size_button.text == "文字大小：標準", "small cycles back to standard")
	check(ui.theme_res.default_font_size == 21 and ui.text_label.get_theme_font_size("normal_font_size") == 21,
		"revert-check restores theme and dialogue to 21 px")
	check(ui.clock_label.get_theme_font_size("font_size") == 24
		and ui.objectives.get_theme_font_size("normal_font_size") == 18, "revert-check restores HUD sizes without compounding")
	check(overlay.buttons.flip.get_theme_font_size("font_size") == 18 and checklist.plate_lines[0].get_theme_font_size("font_size") == 18 and checklist.values[0].get_theme_font_size("normal_font_size") == 25, "revert-check restores chapter panel sizes")
	check(checklist._smudge.position.is_equal_approx(standard_smudge_position) and checklist._smudge.size.is_equal_approx(standard_smudge_size), "revert-check restores smudge position and size")
	Settings.text_scale = 0.0
	Settings.load_settings()
	check(Settings.text_scale == 1.0, "pause cycle saves immediately")
	ui.toggle_pause()
	ui.free()
	overlay.free()
	checklist.free()
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(1919)
	game.phase = game.Phase.TOTALITY
	game.t_game = game.sim.TOTALITY_S - 5.0
	game.plates_left = game.sim.plates_available()
	Settings.text_scale = 1.2
	game._process_totality(0.0)
	check(game.ui.tot_label.text.contains("font_size=50"), "large totality header uses 50 px BBCode")
	game.free()
	if had_settings:
		var file := FileAccess.open(Settings.SETTINGS_PATH, FileAccess.WRITE)
		file.store_buffer(original)
		file.close()
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(Settings.SETTINGS_PATH))
	Settings.load_settings()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH))
	print("test_text_size: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
