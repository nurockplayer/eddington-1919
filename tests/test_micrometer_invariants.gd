extends SceneTree
## FUN_PLAN F8: real input, neutral ticks, and the cost of misaligning a reading.

const Sim := preload("res://scripts/eclipse_sim.gd")
const Render := preload("res://scripts/plate_render.gd")
const Judgment := preload("res://scripts/judgment.gd")
const Settings := preload("res://scripts/settings.gd")

var checks := 0
var failures := 0
var near_steps := 0
var far_steps := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func press(code: int) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.pressed = true
	root.push_input(event)
	event.pressed = false
	root.push_input(event)
	await process_frame


func activate(control: Control) -> void:
	control.grab_focus()
	await press(KEY_ENTER)


func step(ui, direction: int, truth_px: float, context: String) -> void:
	# The throttle uses wall time, whereas SceneTree timers use frame delta.
	# Space actual input events by 60 ms without changing the game clock.
	OS.delay_msec(60)
	var before: float = ui.micrometer_px
	ui.viewer_sfx_log.clear()
	var event := InputEventKey.new()
	event.keycode = KEY_RIGHT if direction > 0 else KEY_LEFT
	event.pressed = true
	root.push_input(event)
	var tick: AudioStreamPlayer = ui._viewer_sfx["tick"]
	check(is_equal_approx(ui.micrometer_px, before + direction * 0.25),
		context + ": arrow input moves exactly one step")
	check(ui.viewer_sfx_log == ["tick"] and tick.playing
		and tick.stream == ui._viewer_sfx["mark"].stream
		and tick.pitch_scale == 1.0 and tick.volume_db == -11.0,
		context + ": each step plays the same stream, pitch and volume (events=%s playing=%s pitch=%s volume=%s)"
		% [ui.viewer_sfx_log, tick.playing, tick.pitch_scale, tick.volume_db])
	var distance: float = absf(ui.micrometer_px - truth_px)
	if distance <= 0.25:
		near_steps += 1
	if distance >= 0.75:
		far_steps += 1
	event.pressed = false
	root.push_input(event)
	await process_frame


func measure(run_seed: int, cloudy: bool, careless: bool) -> Dictionary:
	var context := "seed=%d cloudy=%s careless=%s" % [run_seed, cloudy, careless]
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(run_seed)
	game.phase = game.Phase.NIGHT
	game.sim.rule_id = "strict"
	game.sim.drive_rate_checked = not cloudy
	game.sim.drive_wound = true
	game.plate_textures.clear()
	# Generate actual plates. Cloudy/trailed exposures keep a wide interval.
	for i in (1 if cloudy else 2):
		game.sim.open_shutter(20.0 * i)
		game.sim.accumulate(20.0 if cloudy else 8.0, 0.3 if cloudy else 0.0)
		var plate: Dictionary = game.sim.close_shutter()
		check(plate.usable, context + ": exposure provides a measurable plate")
		game.plate_textures.append(Render.render(game.sim, plate))
	game.comparison_tex = Render.render(game.sim, null)
	var ui = game.ui
	ui.hide_title()
	game._open_viewer()
	await process_frame
	for i in game.sim.plates.size():
		await activate(ui.thumbs.get_child(i + 1))
		await activate(ui.include_box)
		if not ui.micrometer_on:
			await activate(ui.mic_btn)
		var plate: Dictionary = game.sim.plates[i]
		var truth_px: float = game.sim.reading_for_value(plate.value)
		var target := maxi(1, roundi(truth_px / 0.25)) + (8 if careless else 0)
		# Overshoot and return: both directions, near and far from the star.
		for n in target + 2:
			await step(ui, 1, truth_px, context)
		for n in 2:
			await step(ui, -1, truth_px, context)
		await press(KEY_ENTER)
		check(plate.read and is_equal_approx(plate.reading, target * 0.25),
			context + ": Enter records the player's actual crosshair")
		check(game.sim.measured_sigma(plate) > float(plate.sigma),
			context + ": recording retains the setting uncertainty")
		await press(KEY_ESCAPE)
	await activate(ui.measure_btn)
	var combined: Dictionary = game.sim.combined()
	check(game.sim.measured and combined.n == game.sim.plates.size(),
		context + ": all selected readings reach the combined result")
	var plate_error := 0.0
	for plate in game.sim.plates:
		plate_error += absf(game.sim.reading_value(plate) - float(plate.value))
	plate_error /= game.sim.plates.size()
	await activate(ui.report_btn)
	check(game._pending == "verdict" and ui._choice_buttons.size() == 4,
		context + ": report offers all four verdicts")
	var verdict := Judgment.verdict_truth(game.sim)
	if cloudy and not careless:
		check(verdict == 3, context + ": wide evidence reaches inconclusive")
	# The numbered choice is the player's real dialogue input path.
	await press(KEY_1 + verdict)
	check(game._verdict == verdict and game._verdict_class == "consistent"
		and game._pending == "judgment", context + ": verdict is recorded and continues")
	print("F8 %s: alignment_error=%.6f truth_error=%.6f sigma=%.6f verdict=%d"
		% [context, plate_error, absf(combined.value - Sim.EINSTEIN), combined.sigma, verdict])
	var result := {"alignment_error": plate_error,
		"truth_error": absf(combined.value - Sim.EINSTEIN)}
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	return result


func _run() -> void:
	load("res://scripts/main.gd")._ensure_inputs()
	var saved_step := Settings.mic_step
	Settings.mic_step = 1.0
	for run_seed in [1919, 1929]:
		for cloudy in [false, true]:
			var careful := await measure(run_seed, cloudy, false)
			var careless := await measure(run_seed, cloudy, true)
			check(careful.alignment_error < 0.2,
				"seed=%d cloudy=%s: careful alignment stays within one half-step" % [run_seed, cloudy])
			check(careless.alignment_error > careful.alignment_error + 1.0,
				"seed=%d cloudy=%s: careless measuring adds alignment error" % [run_seed, cloudy])
	check(near_steps > 0 and far_steps > 0, "tick checks exercise both near and far readings")
	Settings.mic_step = saved_step
	print("F8: %d near steps, %d far steps" % [near_steps, far_steps])
	print("test_micrometer_invariants: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
