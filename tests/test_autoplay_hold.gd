extends SceneTree
## Exercise the real aiming/hold path at low FPS: wind, rate-check, and collect
## all eight plate holders. Also covers the hold-as-single-press setting.
## Run with --headless --script this file.

const Settings := preload("res://scripts/settings.gd")
const Content := preload("res://scripts/content.gd")

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
	var failures := await _hold_toggle_checks(game)
	Engine.time_scale = 2.0
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
	game.stop_all_audio()
	await create_timer(0.1).timeout
	bot.queue_free()
	game.queue_free()
	await process_frame
	print("3 autoplay hold checks, %d failures" % failures)
	quit(1 if failures > 0 else 0)


func _aim_drive(game) -> bool:
	game.player.global_position = Vector3(0.85, 0.05, -5.65)
	game.player.velocity = Vector3.ZERO
	await physics_frame
	await physics_frame
	game.player.look_at_point(Vector3(0.62, 0.92, -6.6))
	await physics_frame
	await physics_frame
	var aimed: Node = game.player.aimed_interactable()
	return aimed != null and aimed.get_meta("interact_id") == "drive"


## Hold interact for exactly one engine frame; main's own _process runs _process_interaction.
func _press_frame() -> void:
	Input.action_press("interact")
	await process_frame
	Input.action_release("interact")


## The real _process_interaction, one programmatic press, then frames advanced by hand.
func _hold_toggle_checks(game) -> int:
	var failures := 0
	var aimed := await _aim_drive(game)
	if not aimed:
		print("hold toggle: drive not aimed")
		return 1
	Settings.hold_toggle = true
	await process_frame
	await _press_frame()
	await process_frame
	for i in 32:
		game._process_interaction(0.1)
	var wound_once: bool = game.sim.drive_wound
	print("hold toggle, one press: wound=%s" % wound_once)
	if not wound_once:
		failures += 1
	# A second press cancels the latch and rewinds the timer.
	game.sim.drive_wound = false
	game.hold_t = 0.0
	game._hold_latched = false
	await process_frame
	await _press_frame()
	await process_frame
	for i in 9:
		game._process_interaction(0.1)
	var progressed: float = game.hold_t
	await _press_frame()
	await process_frame
	var cancelled: bool = not game._hold_latched and is_zero_approx(game.hold_t)
	for i in 32:
		game._process_interaction(0.1)
	var still_unwound: bool = not game.sim.drive_wound
	print("hold toggle, second press: progressed=%.1f cancelled=%s unwound=%s" % [progressed, cancelled, still_unwound])
	if progressed <= 0.0 or not cancelled or not still_unwound:
		failures += 1
	# Off: the same single press does not wind.
	Settings.hold_toggle = false
	game.sim.drive_wound = false
	game.hold_t = 0.0
	game._hold_latched = false
	await process_frame
	await _press_frame()
	await process_frame
	for i in 32:
		game._process_interaction(0.1)
	var unwound: bool = not game.sim.drive_wound
	print("hold toggle off, one press: unwound=%s" % unwound)
	if not unwound:
		failures += 1

	# Pause cancels a latched hold, and unpausing does not resume it.
	Settings.hold_toggle = true
	game.sim.drive_wound = false
	game._hold_latched = false
	game.hold_t = 0.0
	await process_frame
	await _press_frame()
	await process_frame
	for i in 9:
		game._process_interaction(0.1)
	var latched_before_pause: bool = game._hold_latched and game.hold_t > 0.0
	game.ui.toggle_pause()
	await process_frame
	var cancelled_by_pause: bool = not game._hold_latched and is_zero_approx(game.hold_t)
	game.ui.toggle_pause()
	await process_frame
	for i in 40:
		game._process_interaction(0.1)
	var unwound_after_pause: bool = not game.sim.drive_wound and is_zero_approx(game.hold_t)
	print("pause cancels hold: latched=%s cancelled=%s unwound=%s" % [latched_before_pause, cancelled_by_pause, unwound_after_pause])
	if not latched_before_pause or not cancelled_by_pause or not unwound_after_pause:
		failures += 1

	# The press that closes the pause must not latch a hold (toggle on).
	game.sim.drive_wound = false
	game._hold_latched = false
	game.hold_t = 0.0
	Input.action_release("interact")
	await process_frame
	game.ui.toggle_pause()
	await process_frame
	Input.action_press("interact")
	game.ui.toggle_pause()
	game._process_interaction(0.1)
	var close_press_latched: bool = game._hold_latched or not is_zero_approx(game.hold_t)
	for i in 5:
		await process_frame
	Input.action_release("interact")
	await process_frame
	var held_through_close: bool = game._hold_latched or not is_zero_approx(game.hold_t)
	await _press_frame()
	await process_frame
	var latched_after_release: bool = game._hold_latched
	print("pause-close press (toggle): latched=%s held=%s relatched=%s" % [close_press_latched, held_through_close, latched_after_release])
	if close_press_latched or held_through_close or not latched_after_release:
		failures += 1
	Input.action_release("interact")
	game._hold_latched = false
	game.hold_t = 0.0

	# Same in holding mode: a held interact must be released before it counts.
	Settings.hold_toggle = false
	game.sim.drive_wound = false
	game.hold_t = 0.0
	await process_frame
	game.ui.toggle_pause()
	await process_frame
	Input.action_press("interact")
	game.ui.toggle_pause()
	for i in 5:
		game._process_interaction(0.1)
	var hold_blocked: bool = is_zero_approx(game.hold_t)
	Input.action_release("interact")
	await process_frame
	await process_frame
	Input.action_press("interact")
	for i in 5:
		game._process_interaction(0.1)
	var hold_resumed: bool = game.hold_t > 0.0
	Input.action_release("interact")
	print("pause-close press (hold): blocked=%s resumed=%s" % [hold_blocked, hold_resumed])
	if not hold_blocked or not hold_resumed:
		failures += 1

	# Dialogue wording follows the setting.
	Settings.hold_toggle = true
	var toggle_line: String = Content.cottingham_first()[2]["t"]
	Settings.hold_toggle = false
	var hold_line: String = Content.cottingham_first()[2]["t"]
	print("hold phrase: toggle=%s hold=%s" % [toggle_line, hold_line])
	if not toggle_line.contains("按一下") or toggle_line.contains("按住"):
		failures += 1
	if not hold_line.contains("按住") or hold_line.contains("按一下"):
		failures += 1

	# Hand the drive back unwound to the holding loop below.
	game.sim.drive_wound = false
	game.hold_t = 0.0
	game._hold_latched = false
	return failures
