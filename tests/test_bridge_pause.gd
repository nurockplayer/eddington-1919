extends SceneTree
## Regression (astra M2 review P2): pausing during the 1918 bridge captions must hold the
## transition; M2 must never load paused behind a black fade with no pause panel.
## Windowed: godot --path . --always-on-top --script res://tests/test_bridge_pause.gd
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", label)

func _initialize() -> void:
	run.call_deferred()

func frames(n := 3) -> void:
	for i in n:
		await process_frame

func tap(code: Key) -> void:
	for down in [true, false]:
		var e := InputEventKey.new()
		e.keycode = code
		e.physical_keycode = code
		e.pressed = down
		Input.parse_input_event(e)
		await frames()

func run() -> void:
	root.size = Vector2i(1600, 900)
	change_scene_to_file("res://scenes/cambridge.tscn")
	await frames()
	var chapter = current_scene
	while chapter._busy:
		await frames()
	while chapter.ui.dialog_active():
		var e: Dictionary = chapter.ui._seq[chapter.ui._seq_i]
		await tap(KEY_1 if e.has("choices") else KEY_E)
	chapter._montage()
	await create_timer(1.5).timeout
	await tap(KEY_ESCAPE)
	check(paused and chapter.ui.pause_panel.visible, "Esc during bridge pauses with panel")
	await create_timer(16.0, true, false, true).timeout
	check(current_scene == chapter, "bridge holds while paused (no scene change)")
	if current_scene != chapter:
		print("%d bridge pause checks, %d failures" % [checks, failures])
		quit(1)
		return
	check(chapter.ui.pause_panel.visible, "pause panel still visible after waiting")
	await tap(KEY_ESCAPE)
	var waited := 0.0
	while current_scene == chapter and waited < 30.0:
		await create_timer(0.5).timeout
		waited += 0.5
	check(current_scene != null and current_scene.scene_file_path == "res://scenes/departure.tscn", "bridge resumes into departure")
	check(not paused, "departure starts unpaused")
	await create_timer(3.0).timeout
	check(current_scene.ui.fade.color.a < 0.5, "departure fades in (not stuck black)")
	print("%d bridge pause checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
