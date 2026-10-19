extends SceneTree
## Exercise the real aiming/hold path at low FPS: wind, rate-check, and collect
## all eight plate holders. Run with --headless --script this file.

class HoldBot extends "res://tests/autoplay_bot.gd":
	func _ready() -> void:
		pass  # Only the input primitive is needed, not the full autoplay.


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	var bot := HoldBot.new()
	bot.main = game
	root.add_child(bot)
	Engine.time_scale = 2.0
	var failures := 0
	for target in [
		["drive", Vector3(0.85, 0.05, -5.65), Vector3(0.62, 0.92, -6.6), 3.5, 2],
		["chronometer", Vector3(-1.8, 0.05, -2.45), Vector3(-1.65, 0.89, -3.45), 4.5, 2],
		["plate_box", Vector3(10.7, 0.05, 2.3), Vector3(11.65, 1.18, 2.25), 10.2, 12],
	]:
		Engine.max_fps = target[4]
		game.player.global_position = target[1]
		game.player.velocity = Vector3.ZERO
		await physics_frame
		await physics_frame
		game.player.look_at_point(target[2])
		await physics_frame
		await physics_frame
		var aimed: Node = game.player.aimed_interactable()
		var reachable: bool = aimed != null and aimed.get_meta("interact_id") == target[0]
		await bot._hold(KEY_E, target[3])
		var completed: bool = game.sim.drive_wound if target[0] == "drive" else game.sim.drive_rate_checked
		if target[0] == "plate_box":
			completed = game.sim.plates_carried == game.sim.MAX_EXTRA_PLATES
			print("plate holders carried=%d/%d" % [game.sim.plates_carried, game.sim.MAX_EXTRA_PLATES])
		print("%s at %d FPS, speed=2: reachable=%s completed=%s" % [target[0], target[4], reachable, completed])
		if not reachable or not completed:
			failures += 1
	Engine.max_fps = 60
	Engine.time_scale = 1.0
	# Let the audio thread release the ambient loop before tearing down the scene.
	game.audio_amb.stop()
	game.audio_click.stop()
	game.audio_tick.stop()
	await create_timer(0.1).timeout
	bot.queue_free()
	game.queue_free()
	await process_frame
	print("3 autoplay hold checks, %d failures" % failures)
	quit(1 if failures > 0 else 0)
