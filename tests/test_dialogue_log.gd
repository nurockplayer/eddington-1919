extends SceneTree
## Dialogue log: toasts land in history and the log scrolls with a gamepad.
## Headless: godot --headless --path . --script res://tests/test_dialogue_log.gd

const MAIN := "res://scenes/main.tscn"
const Prompts := preload("res://scripts/prompts.gd")
const Content := preload("res://scripts/content.gd")

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


func press_action(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await settle(2)


func _run() -> void:
	var story := root.get_node("Story")
	check(change_scene_to_file(MAIN) == OK, "load main scene")
	await settle()
	var main := current_scene
	var ui = main.ui
	main.set_process(false)
	var history: Array = load("res://scripts/ui.gd").history
	history.clear()

	ui.show_toast("看雲：變薄就喊開始。", 7.0)
	check(history.size() == 1 and history.back() == "・看雲：變薄就喊開始。", "a toast lands in history")
	ui.show_toast("看雲：變薄就喊開始。", 7.0)
	check(history.size() == 1, "a repeated toast is not logged twice")

	history.clear()
	for i in 40:
		history.append("第 %d 行：全食的說明。" % i)
	ui.toggle_log()
	await settle(4)
	check(ui.log_panel.visible, "log opens")
	var bar: VScrollBar = ui.log_scroll.get_v_scroll_bar()
	check(bar.max_value > 0.0, "40 lines overflow the log")
	check(ui.log_scroll.scroll_vertical > 0 and ui.log_scroll.scroll_vertical == int(bar.max_value - bar.page),
		"the log opens scrolled to the bottom")
	var bottom: int = ui.log_scroll.scroll_vertical
	await press_action("ui_up")
	check(ui.log_scroll.scroll_vertical == bottom - 80, "D-pad up scrolls the log")

	Prompts.joypad = true
	ui._refresh_hints()
	check(ui.log_title.text.contains("Back"), "the log header follows the joypad prompt")
	check(ui.log_back.text.contains("Back"), "the log close button follows the joypad prompt")
	Prompts.joypad = false
	ui._refresh_hints()
	check(ui.log_title.text.contains("Tab"), "the log header returns to Tab")
	ui.toggle_log()
	await settle(2)
	check(not ui.log_panel.visible, "log closes")
	check(not story.from_prologue, "sanity: main scene stayed on the opening chapter")

	var eddington: Label3D = main.world.eddington.find_children("*", "Label3D", false, false)[0]
	var cottingham: Label3D = main.world.cottingham.find_children("*", "Label3D", false, false)[0]
	main._start_game()
	main._say([Content.eddington_prep(2, false, false, 0)[0]], "")
	check(eddington.visible and cottingham.visible, "daylight dialogue keeps both name tags")
	ui._advance()

	main._setup_darkroom()
	check(eddington.visible and cottingham.visible, "darkroom keeps name tags before dialogue")
	main._say([Content.night_intro(2)[0], {"t": "An unnamed line"}, Content.night_intro(2)[1]], "")
	check(ui.speaker_label.text == L.t(Content.E) and not eddington.visible and not cottingham.visible,
		"the named darkroom slip replaces the wall tags")
	ui._advance()
	check(eddington.visible and cottingham.visible, "an unnamed darkroom line restores both name tags")
	ui._advance()
	check(not eddington.visible and not cottingham.visible, "the next named line hides both tags again")
	ui._advance()
	check(eddington.visible and cottingham.visible, "closing darkroom dialogue restores both name tags")

	print("test_dialogue_log: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
