extends SceneTree
## Procedural footsteps follow the existing bob cadence and selected ground.
const Player := preload("res://scripts/player.gd")
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
	check(player.step_surface == "wood", "Cambridge defaults to wood")
	check(is_equal_approx(player._step_player.volume_db, -6.8), "footsteps play at the mixed -6.8 dB")
	for surface in ["wood", "earth"]:
		check(player._steps[surface].size() == 3, "%s has three variants" % surface)
		for stream in player._steps[surface]:
			check(stream is AudioStreamWAV, "%s variant is a WAV" % surface)
			if not stream is AudioStreamWAV:
				continue
			check(stream.mix_rate == 22050 and not stream.stereo, "%s variant is 22050 Hz mono" % surface)
			check(stream.get_length() >= 0.1 and stream.get_length() <= 0.25, "%s variant lasts 0.1-0.25 s" % surface)
			var peak := 0.0
			var data: PackedByteArray = stream.data
			for i in range(0, data.size(), 2):
				peak = maxf(peak, absf(float(data.decode_s16(i)) / 32768.0))
			check(peak > 0.0 and peak <= 0.8, "%s variant has nonzero peak <= 0.8" % surface)
	# Register the floor and settle the character before walking.
	for frame in 3:
		await physics_frame
	Input.action_press("move_forward")
	for frame in 180:
		await physics_frame
	Input.action_release("move_forward")
	# 3 * WALK * 2.2 / PI = 7.14: the unchanged bob crosses seven half cycles.
	check(player.steps_taken == 7, "three seconds walking produces seven bob-timed steps")
	var walking_steps: int = player.steps_taken
	for frame in 120:
		await physics_frame
	check(player.steps_taken == walking_steps, "standing still adds no steps")
	player.can_move = false
	Input.action_press("move_forward")
	for frame in 120:
		await physics_frame
	check(player.steps_taken == walking_steps, "disabled movement adds no steps with forward held")
	player.step_surface = "earth"
	player.can_move = true
	for frame in 30:
		await physics_frame
	Input.action_release("move_forward")
	check(player.steps_taken > walking_steps and player._step_player.stream in player._steps.earth, "the next step plays an earth variant")
	player.free()
	floor_body.free()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
