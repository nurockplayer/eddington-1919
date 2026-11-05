extends SceneTree
## 減少晃動 keeps the walking camera level and halves the blink comparison rate.
const Player := preload("res://scripts/player.gd")
const UI := preload("res://scripts/ui.gd")
const Settings := preload("res://scripts/settings.gd")
const Render := preload("res://scripts/plate_render.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
const STEP := 1.0 / 60.0
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
	await _check_walk()
	await _check_blink()
	print("test_reduced_motion: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check_walk() -> void:
	for action in ["move_left", "move_right", "move_forward", "move_back", "look_left", "look_right", "look_down", "look_up", "run"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(20.0, 0.2, 20.0)
	collision.shape = box
	floor_body.add_child(collision)
	floor_body.position.y = -0.1
	root.add_child(floor_body)
	var player := Player.new()
	player.position.z = 5.0
	root.add_child(player)
	for frame in 3:
		await physics_frame
	# Drive the real _physics_process with a fixed delta so the bob phase is deterministic.
	player.set_physics_process(false)

	# Revert-check: without 減少晃動 the walking camera moves off eye height.
	Settings.reduced_motion = false
	var steps_before: int = player.steps_taken
	var bobbed := false
	Input.action_press("move_forward")
	for frame in 60:
		player._physics_process(STEP)
		await physics_frame
		if not is_equal_approx(player.camera.position.y, 1.62):
			bobbed = true
	Input.action_release("move_forward")
	check(bobbed and player.steps_taken > steps_before, "walking without 減少晃動 bobs the camera")

	Settings.reduced_motion = true
	player._bob = 0.0
	player.can_move = true
	steps_before = player.steps_taken
	var level := true
	Input.action_press("move_forward")
	for frame in 60:
		player._physics_process(STEP)
		await physics_frame
		# Camera positions are 32-bit floats, so compare at that precision.
		level = level and is_equal_approx(player.camera.position.y, 1.62)
	Input.action_release("move_forward")
	check(level, "減少晃動 keeps the walking camera at 1.62")
	check(player.steps_taken > steps_before, "減少晃動 still counts footsteps")
	Settings.reduced_motion = false
	player.free()
	floor_body.free()


func _check_blink() -> void:
	Settings.reduced_motion = false
	var ui := UI.new()
	ui.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(ui)
	await process_frame
	# The engine would call _process with a frame-dependent delta; step it by hand instead.
	ui.set_process(false)
	var sim := Sim.new(1919)
	var plate := {"index": 0, "number": 1, "start": 10.0, "duration": 6.0, "sunlit": false,
		"fog": 0.0, "trail": 0.0, "stars": 12, "included": true, "usable": true, "value": 1.1, "sigma": 0.2}
	var eclipse := Render.render(sim, plate)
	var oxford := Render.render(sim, null)
	ui.open_viewer([plate], oxford, [eclipse], false)
	await process_frame
	ui.blink_btn.button_pressed = true

	# Revert-check: the default comparison flips twice a second.
	ui._blink_elapsed = 0.0
	ui._blink_oxford = false
	ui._process(0.5)
	check(ui._blink_oxford, "default blink flips after 0.5 s")

	Settings.reduced_motion = true
	ui._blink_elapsed = 0.0
	ui._blink_oxford = false
	ui._process(0.5)
	check(not ui._blink_oxford, "減少晃動 holds the first blink frame past 0.5 s")
	ui._process(0.49)
	check(not ui._blink_oxford, "減少晃動 still holds at 0.99 s")
	ui._process(0.01)
	check(ui._blink_oxford, "減少晃動 flips once at 1.0 s")
	ui._process(0.5)
	check(ui._blink_oxford, "減少晃動 does not flip again after 1.5 s")
	Settings.reduced_motion = false
	ui.free()
