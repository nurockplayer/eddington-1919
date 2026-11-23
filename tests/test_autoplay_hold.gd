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
	failures += await _trim_checks(game)
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


func _event(code: int, pressed: bool, pad := false) -> void:
	var event
	if pad:
		event = InputEventJoypadButton.new()
		event.button_index = code
	else:
		event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()
	await process_frame


func _trim_checks(game) -> int:
	var failures := 0
	game.set_process(false)
	game.player.set_physics_process(false)
	var trails := []
	var images := []
	var partial_residual := 0.0
	failures += await _trim_sheet_checks()
	for mode in ["success", "partial", "abandoned", "gamepad", "reduced", "zero", "opposite"]:
		game.sim = load("res://scripts/eclipse_sim.gd").new(77)
		game.sim.drive_wound = true
		if mode == "zero":
			game.sim.drive_error = 0.0
		elif mode == "opposite":
			game.sim.drive_error = -partial_residual
		game.phase = game.Phase.PREP
		game.prep_left = 100.0
		game._interact_needs_release = false
		Settings.reduced_motion = mode == "reduced"
		game._interact("drive")
		var panel = game.calibration
		if not panel.visible or game.player.can_move or game.player.can_look:
			failures += 1
		if mode == "zero":
			game._process_prep(2.9)
			if game.sim.drive_rate_checked:
				failures += 1
			game._process_prep(0.1)
			if not game.sim.drive_rate_checked:
				failures += 1
		else:
			game._process_prep(1.0)
		var before: float = game.prep_left
		await _event(KEY_ESCAPE, true)
		await _event(KEY_ESCAPE, false)
		if not paused:
			failures += 1
		# The real scene tree stops main; explicit panel advancement must also freeze.
		var elapsed: float = panel.elapsed
		panel.advance(2.0)
		game._process_prep(2.0)
		await process_frame
		if game.prep_left != before or panel.elapsed != elapsed:
			failures += 1
		await _event(JOY_BUTTON_START, true, true)
		await _event(JOY_BUTTON_START, false, true)
		if paused:
			failures += 1
		var pad: bool = mode == "gamepad"
		if mode in ["success", "gamepad", "reduced", "partial"]:
			var trimming := false
			var trim_code: int = JOY_BUTTON_DPAD_LEFT if pad else KEY_LEFT
			for step in 400:
				# Only the displayed movement controls the correction.
				var should_trim: bool = absf(panel.measured_drift) > (12.0 if mode == "partial" else 0.65)
				if should_trim != trimming:
					await _event(trim_code, should_trim, pad)
					trimming = should_trim
				# Fine input through Shift / the gamepad's actual LT axis.
				var fine: bool = absf(panel.measured_drift) < 5.0
				if pad:
					var trigger := InputEventJoypadMotion.new()
					trigger.axis = JOY_AXIS_TRIGGER_LEFT
					trigger.axis_value = 1.0 if fine else 0.0
					Input.parse_input_event(trigger)
					Input.flush_buffered_events()
				else:
					Input.action_press("trim_fine") if fine else Input.action_release("trim_fine")
				game._process_prep(0.1)
				if game.sim.drive_rate_checked or (mode == "partial" and not should_trim):
					break
			await _event(trim_code, false, pad)
			Input.action_release("trim_fine")
			var trigger := InputEventJoypadMotion.new()
			trigger.axis = JOY_AXIS_TRIGGER_LEFT
			Input.parse_input_event(trigger)
			Input.flush_buffered_events()
		if mode == "reduced":
			var mark: float = panel.now_mark
			game._process_prep(0.1)
			if panel.now_mark != mark or panel.previous_mark != 0.0:
				failures += 1
		if mode in ["success", "gamepad", "reduced"] and not game.sim.drive_rate_checked:
			failures += 1
		if mode == "partial":
			partial_residual = game.sim.drive_error
			if game.sim.drive_rate_checked:
				failures += 1
		if mode == "abandoned":
			# Hint after ten active seconds, no automatic correction; expiry closes.
			game._process_prep(9.0)
			if not panel.hinted or game.sim.drive_error != 1.0:
				failures += 1
			# Slower and faster change the sampled drift in the corresponding direction.
			await _event(KEY_LEFT, true)
			game._process_prep(5.0)
			await _event(KEY_LEFT, false)
			var slower: float = panel.measured_drift
			await _event(KEY_RIGHT, true)
			game._process_prep(1.0)
			await _event(KEY_RIGHT, false)
			if not (slower < 24.0 and panel.measured_drift > slower):
				failures += 1
			var residual: float = game.sim.drive_error
			game.prep_left = 0.1
			game._process_prep(0.1)
			if panel.visible or game.phase != game.Phase.TOTALITY or game.sim.drive_error != residual:
				failures += 1
			await create_timer(2.1).timeout
		else:
			await _event(JOY_BUTTON_A if pad else KEY_ENTER, true, pad)
			await _event(JOY_BUTTON_A if pad else KEY_ENTER, false, pad)
			if panel.visible:
				failures += 1
		# Real director shutter input, same seed/cloud/duration; develop and render.
		game.phase = game.Phase.TOTALITY
		game._busy = false
		game.tot_done = false
		game.change_left = 0.0
		game.plates_left = 4
		game.t_game = 220.0
		await _event(KEY_SPACE, true)
		await _event(KEY_SPACE, false)
		for frame in 100:
			game._process_totality(0.1 / game.sim.TIME_SCALE)
		await _event(KEY_SPACE, true)
		await _event(KEY_SPACE, false)
		if game.sim.plates.size() != 1:
			failures += 1
		else:
			var plate: Dictionary = game.sim.plates[0]
			trails.append(plate.trail)
			images.append(load("res://scripts/plate_render.gd").render(game.sim, plate).get_image().get_data())
		print("trim %s: verified=%s residual=%.4f trail=%s" % [mode, game.sim.drive_rate_checked, game.sim.drive_error, trails.back() if not trails.is_empty() else -1])
	if trails.size() != 7 or not (trails[0] < trails[1] and trails[1] < trails[2]):
		print("FAIL: successful trim < partial trim < abandoned in developed-plate trail: ", trails)
		failures += 1
	if images.size() != 7 or images[0] == images[1] or images[1] == images[2]:
		failures += 1
	# Equal opposite residuals keep magnitude but reverse the rendered extension.
	if trails.size() == 7:
		if not is_equal_approx(trails[1], trails[6]) or not is_equal_approx(trails[5], 0.12) or images[1] == images[6]:
			print("FAIL: zero/opposite residual trail magnitude/direction")
			failures += 1
	# Attempt cap and both leave bindings preserve the current setting.
	for leave in [KEY_B, JOY_BUTTON_B, -1]:
		game.phase = game.Phase.PREP
		game.prep_left = 100.0
		game.sim.drive_error = -0.5
		game._interact_needs_release = false
		game._interact("drive")
		if leave == -1:
			game._process_prep(45.0)
		else:
			await _event(leave, true, leave == JOY_BUTTON_B)
			await _event(leave, false, leave == JOY_BUTTON_B)
		if game.calibration.visible or game.sim.drive_error != -0.5:
			failures += 1
	Settings.reduced_motion = false
	print("input trim → shutter → developed/rendered plate: %d failures" % failures)
	return failures


func _trim_sheet_checks() -> int:
	var failures := 0
	var language := L.current()
	var scale := Settings.text_scale
	var window := root.size
	var content_size := root.content_scale_size
	root.content_scale_size = Vector2i.ZERO
	Settings.text_scale = 1.2
	const Print := preload("res://scripts/styles/engraving.gd")
	var contrast := (Print.PAPER.srgb_to_linear().get_luminance() + 0.05) / (Print.INK.srgb_to_linear().get_luminance() + 0.05)
	if contrast < 4.5:
		failures += 1
	for locale in ["en", "ja", "zh_TW", "ko"]:
		L.apply(locale)
		for viewport in [Vector2i(1280, 720), Vector2i(2560, 1440)]:
			root.size = viewport
			var panel := preload("res://scripts/coelostat_calibration.gd").new()
			root.add_child(panel)
			panel.open(load("res://scripts/eclipse_sim.gd").new(77))
			for frame in 5:
				await process_frame
			var paper: StyleBoxFlat = panel.sheet.get_theme_stylebox("panel")
			if paper.bg_color != Print.PAPER or paper.border_color != Print.INK:
				failures += 1
			for label in [panel.caption, panel.status, panel.hint, panel.controls]:
				if not panel.sheet.get_global_rect().encloses(label.get_global_rect()) or label.get_theme_color("font_color") != Print.INK:
					print("FAIL: trim sheet fit/ink ", locale, " ", viewport, " ", label.text)
					failures += 1
			if panel.diagram.size.y < 180:
				failures += 1
			panel.queue_free()
			await process_frame
	L.apply(language)
	Settings.text_scale = scale
	root.content_scale_size = content_size
	root.size = window
	print("trim sheet: 8 max-text layouts, contrast %.2f:1, %d failures" % [contrast, failures])
	return failures
