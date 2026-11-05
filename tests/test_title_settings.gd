extends SceneTree

const Settings := preload("res://scripts/settings.gd")
var checks := 0
var failures := 0
var pause_events := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func settle() -> void:
	for i in 4:
		await process_frame

func find_button(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found := find_button(child, label)
		if found:
			return found
	return null

func cancel() -> void:
	var event := InputEventAction.new()
	event.action = "ui_cancel"
	event.pressed = true
	root.push_input(event)
	await settle()

func _run() -> void:
	check(change_scene_to_file("res://scenes/main.tscn") == OK, "load main")
	await settle()
	var main := current_scene
	main.set_process(false)
	var ui = main.ui
	ui.pause_toggled.connect(func(_p): pause_events += 1)
	var settings := find_button(ui.title_panel, "設定")
	check(settings != null, "title offers settings")
	settings.grab_focus()
	settings.pressed.emit()
	await settle()
	check(ui.pause_panel.visible and not paused and pause_events == 0, "settings opens without pausing or emitting")
	check(find_button(ui.pause_panel, "返回").is_visible_in_tree(), "return replaces continue")
	for label in ["回到標題", "從頭開始", "離開遊戲"]:
		check(not find_button(ui.pause_panel, label).is_visible_in_tree(), label + " hidden")
	var look: Button
	for b in ui.pause_panel.find_children("*", "Button", true, false):
		if b.text.begins_with("視角靈敏度："):
			look = b
	var previous := Settings.look_speed
	look.pressed.emit()
	check(Settings.look_speed != previous, "look speed changes")
	var saved := ConfigFile.new()
	check(saved.load(Settings.settings_path()) == OK and is_equal_approx(float(saved.get_value("input", "look_speed", -1)), Settings.look_speed), "look speed saved")
	ui.toggle_pause()
	check(not paused and ui.pause_panel.visible and pause_events == 0, "toggle_pause guarded in settings")
	var help := find_button(ui.pause_panel, "操作說明")
	help.pressed.emit()
	await settle()
	check(ui.help_panel.visible, "help opens")
	await cancel()
	check(not ui.help_panel.visible and ui.pause_panel.visible and not paused, "help returns to settings")
	await cancel()
	check(not ui.pause_panel.visible and root.gui_get_focus_owner() == settings and not paused, "cancel closes and restores focus")
	ui.pause_enabled = true
	ui.toggle_pause()
	check(paused and ui._pause_heading.text == "暫停", "normal pause restored")
	for label in ["繼續", "回到標題", "從頭開始", "離開遊戲"]:
		check(find_button(ui.pause_panel, label).is_visible_in_tree(), label + " visible")
	ui.toggle_pause()
	print("test_title_settings: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
