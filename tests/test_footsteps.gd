extends SceneTree
## Footstep events on the existing wood and earth routes.
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
	var chapter = load("res://scenes/cambridge.tscn").instantiate()
	root.add_child(chapter)
	while chapter._busy:
		await process_frame
	while chapter.ui.dialog_active():
		chapter.ui._advance()
	await _test_surface(chapter.player, "wood")
	await _test_blocked(chapter.player)
	_test_variants(chapter.player)
	chapter.free()

	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await game._start_from_title()
	await _test_surface(game.player, "earth")
	game.free()

	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_surface(player: Player, surface: String) -> void:
	check(player.step_surface == surface, "%s scene uses its existing surface tag" % surface)
	# Both routes use a clear stretch from z=4 to z=7; reverse to stay on it.
	var cadence: Array[float] = []
	for running in [false, true]:
		player.position = Vector3(0.0 if surface == "wood" else 2.6, 0.0, 4.2)
		player.yaw = 0.0
		for frame in 3:
			await physics_frame
		if running:
			Input.action_press("run")
		var label := "%s %s (10 s)" % [surface, "run" if running else "walk"]
		var result := await _sample(player, surface, 600, "move_back")
		Input.action_release("run")
		check(result.distance > 30.0, "%s covers the route" % label)
		check(result.events > 0 and result.matches >= 0.95 * result.events, "%s matches its surface on at least 95%% of events" % label)
		check(absf(result.events - result.distance / 1.4) < 1.0, "%s cadence follows measured distance" % label)
		cadence.append(result.events / 10.0)
		print("%s: %.2f m/s, %.2f steps/s, %d/%d surface matches" % [
			label, result.distance / 10.0, cadence.back(), result.matches, result.events])

		var yaw_before := player.yaw
		var stopped := await _sample(player, surface, 30)
		Input.action_press("look_right")
		var turning := await _sample(player, surface, 30)
		Input.action_release("look_right")
		check(stopped.events == 0 and turning.events == 0, "%s adds no steps after release or during a turn in place" % label)
		check(not is_equal_approx(player.yaw, yaw_before), "%s turns in place" % label)
		print("%s stop / turn: %d / %d steps" % [label, stopped.events, turning.events])
	check(cadence[1] > cadence[0], "%s running has a faster cadence than walking" % surface)


func _test_blocked(player: Player) -> void:
	# Settle against the corridor's closed end, then keep the movement input held.
	player.position = Vector3(0.0, 0.0, 7.2)
	player.yaw = 0.0
	Input.action_press("move_back")
	for frame in 30:
		await physics_frame
	var blocked := await _sample(player, "wood", 120)
	check(blocked.distance < 0.01 and blocked.events == 0, "holding movement at the Cambridge wall adds no steps")
	print("wood blocked (2 s): %.4f m travelled, %d steps" % [blocked.distance, blocked.events])
	player.can_move = false
	var disabled := await _sample(player, "wood", 120)
	check(disabled.events == 0, "disabled movement adds no steps with input held")
	Input.action_release("move_back")


func _sample(player: Player, surface: String, frames: int, shuttle := "") -> Dictionary:
	var distance := 0.0
	var events := 0
	var matches := 0
	for frame in frames:
		if not shuttle.is_empty():
			if player.position.z >= 7.0:
				Input.action_release(shuttle)
				shuttle = "move_forward"
			elif player.position.z <= 4.0:
				Input.action_release(shuttle)
				shuttle = "move_back"
			Input.action_press(shuttle)
		var start := player.position
		var steps := player.steps_taken
		await physics_frame
		var moved := player.position - start
		distance += Vector2(moved.x, moved.z).length()
		var emitted := player.steps_taken - steps
		events += emitted
		if emitted > 0 and player._step_player.stream in player._steps[surface]:
			matches += emitted
	if not shuttle.is_empty():
		Input.action_release(shuttle)
	return {"distance": distance, "events": events, "matches": matches}


func _test_variants(player: Player) -> void:
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
