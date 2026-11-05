extends SceneTree
## Pause-menu 操作說明 panel and the 回到標題 return path.
## Headless: godot --headless --path . --script res://tests/test_pause_help.gd

const MAIN := "res://scenes/main.tscn"

var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func settle(frames := 4) -> void:
	for i in frames:
		await process_frame


func find_button(node: Node, label: String) -> Button:
	if node is Button and node.text == label:
		return node
	for child in node.get_children():
		var found: Button = find_button(child, label)
		if found:
			return found
	return null


func press_escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.physical_keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await settle(2)


func _run() -> void:
	var story := root.get_node("Story")
	check(change_scene_to_file(MAIN) == OK, "load main scene")
	await settle()
	var main := current_scene
	var main_id: int = main.get_instance_id()
	var ui = main.ui
	main.set_process(false)
	ui.pause_enabled = true
	ui.toggle_pause()
	check(paused and ui.pause_panel.visible, "Start opens the pause menu")
	var help := find_button(ui.pause_panel, "操作說明")
	check(help != null, "pause menu offers 操作說明")
	help.grab_focus()
	help.pressed.emit()
	await settle()
	check(ui.help_panel.visible, "操作說明 opens its panel")
	check(ui.help_content.text.contains(ui.title_controls.text), "help repeats the live control text")
	var back := find_button(ui.help_panel, "返回")
	check(back != null and root.gui_get_focus_owner() == back, "help focuses 返回")
	check(ui.blocks_world_input(), "help blocks world input")
	check(paused and ui.pause_panel.visible, "pause menu stays underneath help")
	await press_escape()
	check(not ui.help_panel.visible, "Esc closes help")
	check(ui.pause_panel.visible and paused, "Esc returns to the pause menu")
	check(root.gui_get_focus_owner() == help, "help restores 操作說明 focus")
	var to_title := find_button(ui.pause_panel, "回到標題")
	check(to_title != null, "pause menu offers 回到標題")
	to_title.pressed.emit()
	await settle()
	check(to_title.text == "再按一次：回到標題", "first press arms 回到標題")
	check(current_scene.get_instance_id() == main_id and paused, "armed 回到標題 keeps playing")
	ui.toggle_pause()
	check(not ui.pause_panel.visible and to_title.text == "回到標題", "closing the pause menu disarms 回到標題")
	ui.toggle_pause()
	story.prologue_done = true
	story.from_prologue = true
	story.clues = {"residual": true}
	story.runs.append({"grade": "probe"})
	load("res://scripts/main.gd").replay_from_prologue = true
	load("res://scripts/main.gd").next_seed = 4242
	load("res://scripts/ui.gd").history.append("old dialogue")
	to_title.pressed.emit()
	check(to_title.text == "再按一次：回到標題" and current_scene.get_instance_id() == main_id, "reopened 回到標題 needs arming again")
	to_title.pressed.emit()
	await settle()
	var fresh = current_scene
	check(fresh.get_instance_id() != main_id, "回到標題 changes scene")
	check(fresh.scene_file_path == MAIN, "回到標題 returns to the main scene")
	check(not paused and not fresh.ui.pause_panel.visible, "回到標題 leaves the tree unpaused")
	check(fresh.ui.title_panel.visible, "title screen is visible")
	check(root.gui_get_focus_owner() == fresh.ui.prologue_btn, "prologue button holds focus")
	check(not story.from_prologue and not story.prologue_done and story.clues.is_empty() and story.runs.is_empty(),
		"回到標題 resets Story")
	check(not load("res://scripts/main.gd").replay_from_prologue, "回到標題 clears the replay origin flag")
	check(load("res://scripts/main.gd").next_seed == -1, "回到標題 clears the replay seed")
	check(load("res://scripts/ui.gd").history.is_empty(), "回到標題 clears the dialogue log")
	print("test_pause_help: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
