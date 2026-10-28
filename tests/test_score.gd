extends SceneTree
## Headless signal and score-player checks for the M4 procedural score.
## Run: godot --headless --path . --script res://tests/test_score.gd

const Score := preload("res://scripts/audio/score.gd")
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
## Wall-clock budget for _end_totality to reach NIGHT with the Tab log held open.
const HANDOFF_BUDGET_MS := 7500  # authored ≈5.6 s; measured 5.7 s at load avg 8

const EXPECTED_CUES := [
	"cambridge_rain",
	"departure_motif",
	"totality_drone",
	"totality_glass",
	"totality_edge",
	"coda_resolution",
]
const FRAME_SECONDS := 0.1
const QUIET_FRAME_RMS := 0.001
const TICK_RATIO_LIMIT := 0.01

var checks := 0
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	check(Score.CUES == EXPECTED_CUES, "score exposes the six specified cues in order")
	check(Score.RATE == 22050, "score renders at 22050 Hz")
	_check_global_rng_untouched()
	var renders := {}
	for cue in EXPECTED_CUES:
		var samples: PackedFloat32Array = Score.render(cue)
		var repeated: PackedFloat32Array = Score.render(cue)
		check(samples.size() == repeated.size() and samples == repeated, "%s renders deterministically" % cue)
		renders[cue] = samples
		_check_duration(cue, samples.size())
		_check_signal(cue, samples)
	_check_rain_silence(renders["cambridge_rain"])
	_check_motif_placement(renders)
	_check_totality_loop_envelopes(renders)
	_check_music_toggle()
	_check_player_log_and_fades()
	await _check_async_worker_lifecycle()
	await _check_totality_black_handoff()
	print("test_score: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check_global_rng_untouched() -> void:
	seed(1234)
	var expected := PackedFloat64Array([randf(), randf(), randf()])
	seed(1234)
	for cue in EXPECTED_CUES:
		Score.render(str(cue))
	var actual := PackedFloat64Array([randf(), randf(), randf()])
	check(expected == actual, "rendering every cue leaves the global RNG sequence untouched")


func _check_duration(cue: String, sample_count: int) -> void:
	var duration := float(sample_count) / Score.RATE
	var limits := {
		"cambridge_rain": Vector2(48.0, 64.0),
		"departure_motif": Vector2(8.0, 10.0),
		"totality_drone": Vector2(20.0, 30.0),
		"totality_glass": Vector2(20.0, 30.0),
		"totality_edge": Vector2(20.0, 30.0),
		"coda_resolution": Vector2(14.0, 18.0),
	}
	var expected: Vector2 = limits[cue]
	check(duration >= expected.x and duration <= expected.y,
		"%s duration %.3fs is within %.0f–%.0fs" % [cue, duration, expected.x, expected.y])


func _check_signal(cue: String, samples: PackedFloat32Array) -> void:
	var peak := 0.0
	var sum_sq := 0.0
	for sample in samples:
		peak = maxf(peak, absf(sample))
		sum_sq += sample * sample
	var rms := sqrt(sum_sq / maxf(1.0, float(samples.size())))
	check(peak <= 0.5, "%s peak %.6f stays below 0.5" % [cue, peak])
	check(rms < 0.15, "%s pre-bus RMS %.6f retains headroom" % [cue, rms])
	var tick_ratio := _goertzel_ratio(samples, Score.RATE, 1900.0)
	check(tick_ratio < TICK_RATIO_LIMIT,
		"%s 1900 Hz Goertzel/RMS ratio %.7f stays below %.3f" % [cue, tick_ratio, TICK_RATIO_LIMIT])
	if Score.is_loop(cue):
		var seam := absf(samples[0] - samples[samples.size() - 1])
		var differences := PackedFloat32Array()
		for i in range(1, samples.size()):
			differences.append(absf(samples[i] - samples[i - 1]))
		differences.sort()
		var p99_index := mini(differences.size() - 1, floori((differences.size() - 1) * 0.99))
		var p99 := differences[p99_index]
		check(seam <= p99 + 0.000001,
			"%s loop seam %.8f is no larger than internal 99th percentile %.8f" % [cue, seam, p99])


func _check_rain_silence(samples: PackedFloat32Array) -> void:
	var frame_size := roundi(Score.RATE * FRAME_SECONDS)
	var frame_count := 0
	var silent_count := 0
	for start in range(0, samples.size(), frame_size):
		var end := mini(start + frame_size, samples.size())
		var sum_sq := 0.0
		for i in range(start, end):
			sum_sq += samples[i] * samples[i]
		var frame_rms := sqrt(sum_sq / maxf(1.0, float(end - start)))
		frame_count += 1
		if frame_rms <= QUIET_FRAME_RMS:
			silent_count += 1
	var silent_fraction := float(silent_count) / maxf(1.0, float(frame_count))
	check(silent_fraction >= 0.4,
		"cambridge_rain has %.1f%% near-silent 100 ms frames" % (silent_fraction * 100.0))


func _check_motif_placement(renders: Dictionary) -> void:
	var probes := {
		"cambridge_rain": Vector2(15.2, 16.2),
		"departure_motif": Vector2(5.55, 6.4),
		"totality_drone": Vector2(4.0, 20.0),
		"totality_glass": Vector2(4.0, 18.0),
		"totality_edge": Vector2(4.0, 18.0),
	}
	for cue in probes:
		var samples: PackedFloat32Array = renders[cue]
		var region: Vector2 = probes[cue]
		var fs_ratio := _goertzel_slice_ratio(samples, region.x, region.y, 369.99)
		check(fs_ratio < 0.02, "%s has no F#4 resolution energy (ratio %.6f)" % [cue, fs_ratio])
	var departure: PackedFloat32Array = renders["departure_motif"]
	var coda: PackedFloat32Array = renders["coda_resolution"]
	# Probe stable interiors of each final motif note so neighboring note tails
	# cannot masquerade as the changed third through finite-window leakage.
	var departure_f := _goertzel_slice_ratio(departure, 5.55, 6.4, 349.23)
	var departure_fs := _goertzel_slice_ratio(departure, 5.55, 6.4, 369.99)
	var coda_f := _goertzel_slice_ratio(coda, 8.0, 12.0, 349.23)
	var coda_fs := _goertzel_slice_ratio(coda, 8.0, 12.0, 369.99)
	var coda_motif_f := _goertzel_slice_ratio(coda, 5.55, 6.3, 349.23)
	var coda_motif_fs := _goertzel_slice_ratio(coda, 5.55, 6.3, 369.99)
	check(departure_f > departure_fs * 1.25,
		"departure motif states F natural above F sharp (F=%.6f F#=%.6f)" % [departure_f, departure_fs])
	check(coda_fs > coda_f * 1.25,
		"coda answer favors F sharp over F natural (F=%.6f F#=%.6f)" % [coda_f, coda_fs])
	check(coda_motif_fs > coda_motif_f * 1.25,
		"coda's fourth motif note is F sharp near 5.5 s (F=%.6f F#=%.6f)" % [coda_motif_f, coda_motif_fs])


func _check_totality_loop_envelopes(renders: Dictionary) -> void:
	for cue in ["totality_drone", "totality_glass", "totality_edge"]:
		var samples: PackedFloat32Array = renders[cue]
		var early_rms := _window_rms(samples, 0.1, 0.4)
		var active_rms := 0.0
		for start in [0.4, 0.7, 1.0, 1.3, 1.6, 1.9, 2.2]:
			active_rms = maxf(active_rms, _window_rms(samples, start, start + 0.3))
		# The loop buffer itself must begin at playing level. A player-level
		# entrance fade is applied once; a repeated 0.7/1.2 s synth attack would
		# make this first window much quieter on every 24 s wrap.
		check(early_rms > active_rms * 0.5,
			"%s loop has no repeated attack envelope (first=%.6f active=%.6f)" % [cue, early_rms, active_rms])


func _window_rms(samples: PackedFloat32Array, start_s: float, end_s: float) -> float:
	var first := clampi(roundi(start_s * Score.RATE), 0, samples.size())
	var last := clampi(roundi(end_s * Score.RATE), first, samples.size())
	var sum_sq := 0.0
	for i in range(first, last):
		sum_sq += samples[i] * samples[i]
	return sqrt(sum_sq / maxf(1.0, float(last - first)))


func _check_music_toggle() -> void:
	const TEST_SETTINGS := "user://test_score_settings.cfg"
	var prior := ScorePlayer.music_enabled()
	ScorePlayer.ensure_bus()
	var disable_error: Error = ScorePlayer.set_music_enabled(false, TEST_SETTINGS)
	check(disable_error == OK, "music toggle writes disabled value to test ConfigFile")
	check(AudioServer.is_bus_mute(ScorePlayer.ensure_bus()), "music toggle mutes Music bus")
	ScorePlayer.load_settings(TEST_SETTINGS)
	check(not ScorePlayer.music_enabled() and AudioServer.is_bus_mute(ScorePlayer.ensure_bus()),
		"music toggle reload keeps Music muted from test ConfigFile")
	var restore_error: Error = ScorePlayer.set_music_enabled(prior, TEST_SETTINGS)
	check(restore_error == OK and ScorePlayer.music_enabled() == prior,
		"music bus restored to its original state")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_SETTINGS))


func _check_player_log_and_fades() -> void:
	var player = ScorePlayer.new()
	player.playback_enabled = false
	root.add_child(player)
	player.play("totality_drone", 0.0)
	player.play("totality_glass", 0.0)
	player.advance(0.0)
	player.set_layer_db("totality_glass", -80.0, 0.4)
	player.advance(0.2)
	var half_duck := float(player.layers["totality_glass"].db)
	player.set_log_open(true)
	player.advance(0.2)
	var paused_duck := float(player.layers["totality_glass"].db)
	check(is_equal_approx(half_duck, paused_duck), "totality layer fade freezes while pause log is open")
	player.set_log_open(false)
	player.advance(0.2)
	check(is_equal_approx(float(player.layers["totality_glass"].db), -80.0),
		"totality glass reaches silence after the 0.4 s exposure duck")
	player.set_layer_db("totality_glass", -34.0, 1.2)
	player.advance(0.6)
	var half_return := float(player.layers["totality_glass"].db)
	player.set_log_open(true)
	player.advance(0.3)
	check(is_equal_approx(float(player.layers["totality_glass"].db), half_return),
		"totality glass return fade freezes while pause log is open")
	player.set_log_open(false)
	player.advance(0.3)
	check(float(player.layers["totality_glass"].db) > half_return,
		"totality glass resumes its 1.2 s return after pause log closes")
	player.stop("totality_drone", 1.5)
	player.stop("totality_glass", 1.5)
	player.advance(1.5)
	var saw_drone_start := false
	var saw_glass_start := false
	var saw_duck := false
	var saw_return := false
	var saw_stop := false
	var saw_drone_stop_fade := false
	var saw_glass_stop_fade := false
	var drone_start_order := -1
	var duck_order := -1
	var return_order := -1
	var drone_stop_order := -1
	for i in ScorePlayer.cue_log.size():
		var event: Dictionary = ScorePlayer.cue_log[i]
		if event.get("event", "") == "start" and event.get("cue", "") == "totality_drone":
			saw_drone_start = true
			drone_start_order = i
		if event.get("event", "") == "start" and event.get("cue", "") == "totality_glass":
			saw_glass_start = true
		if event.get("event", "") == "layer" and event.get("cue", "") == "totality_glass":
			if is_equal_approx(float(event.get("db", 0.0)), -80.0) and is_equal_approx(float(event.get("fade", 0.0)), 0.4):
				saw_duck = true
				duck_order = i
			if is_equal_approx(float(event.get("db", 0.0)), -34.0) and is_equal_approx(float(event.get("fade", 0.0)), 1.2):
				saw_return = true
				return_order = i
		if event.get("event", "") in ["stop", "stopped"] and event.get("cue", "") == "totality_drone":
			saw_stop = true
		if event.get("event", "") == "stop" and event.get("cue", "") == "totality_drone" and is_equal_approx(float(event.get("fade", 0.0)), 1.5):
			saw_drone_stop_fade = true
			drone_stop_order = i
		if event.get("event", "") == "stop" and event.get("cue", "") == "totality_glass" and is_equal_approx(float(event.get("fade", 0.0)), 1.5):
			saw_glass_stop_fade = true
	check(saw_drone_start and saw_glass_start and saw_duck and saw_return and saw_stop,
		"cue log records totality starts, exposure duck/return and stop")
	check(saw_drone_stop_fade and saw_glass_stop_fade and drone_start_order < duck_order \
		and duck_order < return_order and return_order < drone_stop_order,
		"cue log orders exposure response before 1.5 s totality fades")
	player.queue_free()


func _check_async_worker_lifecycle() -> void:
	var starts_before := 0
	for entry in ScorePlayer.cue_log:
		if entry.get("event", "") == "start" and entry.get("cue", "") == "coda_resolution":
			starts_before += 1
	var stopped_early := ScorePlayer.new()
	stopped_early.playback_enabled = true
	root.add_child(stopped_early)
	stopped_early.play("coda_resolution", 0.0)
	stopped_early.stop("coda_resolution", 0.0)
	var deadline := Time.get_ticks_msec() + 10000
	while not ScorePlayer._rendered.has("coda_resolution") and Time.get_ticks_msec() < deadline:
		await process_frame
	check(ScorePlayer._rendered.has("coda_resolution"), "async coda worker completes before deadline")
	await process_frame
	check(not stopped_early.layers["coda_resolution"].playing,
		"stop-before-ready prevents a late worker result from resurrecting the cue")
	var starts_after_cancel := 0
	for entry in ScorePlayer.cue_log:
		if entry.get("event", "") == "start" and entry.get("cue", "") == "coda_resolution":
			starts_after_cancel += 1
	check(starts_after_cancel == starts_before,
		"cancelled async coda never records a start")
	stopped_early.queue_free()
	await process_frame

	var replay := ScorePlayer.new()
	replay.playback_enabled = true
	root.add_child(replay)
	replay.play("coda_resolution", 0.0)
	deadline = Time.get_ticks_msec() + 1000
	while not replay.layers["coda_resolution"].playing and Time.get_ticks_msec() < deadline:
		await process_frame
	check(replay.layers["coda_resolution"].playing,
		"a second player starts the rendered cue from the shared cache")
	check(not ScorePlayer._jobs.has("coda_resolution"),
		"cached replay does not enqueue another worker task")
	replay.stop("coda_resolution", 0.0)
	await process_frame # Release the child AudioStreamPlayer queued by stop().
	replay.queue_free()
	await process_frame

	# Hold the synthesis mutex indirectly by running a long, uncached cue on a
	# worker, then read a cached stream from the main thread while it is active.
	var render_thread := Thread.new()
	var thread_error: Error = render_thread.start(Callable(Score, "stream").bind("cambridge_rain"))
	check(thread_error == OK, "unrelated cue render starts on a worker thread")
	var render_busy := false
	deadline = Time.get_ticks_msec() + 5000
	while not render_busy and Time.get_ticks_msec() < deadline:
		if Score._table_mutex.try_lock():
			Score._table_mutex.unlock()
		else:
			render_busy = true
			break
		await process_frame
	check(render_busy, "worker reaches synthesis while cached cue remains available")
	var cache_read_started := Time.get_ticks_usec()
	var cached_stream: AudioStreamWAV = Score.stream("coda_resolution")
	var cache_read_ms := float(Time.get_ticks_usec() - cache_read_started) / 1000.0
	print("score cache contention: render_busy=%s cached_main_ms=%.3f" % [render_busy, cache_read_ms])
	check(cached_stream != null and cache_read_ms <= 30.0,
		"main-thread cached stream lookup takes %.3f ms during unrelated synthesis" % cache_read_ms)
	if thread_error == OK:
		render_thread.wait_to_finish()


func _check_totality_black_handoff() -> void:
	var started_at := Time.get_ticks_msec()
	var main_script: Script = load("res://scripts/main.gd")
	var main = main_script.new()
	root.add_child(main)
	await process_frame
	var score = main.score
	score.playback_enabled = true
	var cues := ["totality_drone", "totality_glass", "totality_edge"]
	for cue in cues:
		score.play(cue, 0.0)
	var start_deadline := Time.get_ticks_msec() + 4000
	var all_started := false
	while not all_started and Time.get_ticks_msec() < start_deadline:
		all_started = true
		for cue in cues:
			all_started = all_started and bool(score.layers.get(cue, {}).get("playing", false))
		if not all_started:
			await process_frame
	check(all_started, "actual 1919 scene starts all three totality AudioStreamPlayers")
	for cue in cues:
		var layer: Dictionary = score.layers.get(cue, {})
		check(is_instance_valid(layer.get("player")), "%s has a live AudioStreamPlayer before handoff" % cue)

	main.phase = main.Phase.TOTALITY
	main.tot_done = false
	await create_timer(0.65).timeout # Let the real entrance ramps reach audible levels.
	check(float(score.layers["totality_drone"].db) > -31.0,
		"totality drone entrance ramp reaches audible level before handoff")
	# Time the handoff itself: loading main.gd above is host load, not the cue.
	var handoff_started := Time.get_ticks_msec()
	main._end_totality()
	await create_timer(0.25).timeout
	main.ui.toggle_log() # Tab opens the real dialogue-history panel during the 1.5s audio fade.
	check(main.ui.log_open(), "Tab log remains open during the real totality handoff")
	var held_db := float(score.layers["totality_drone"].db)
	await create_timer(0.3).timeout
	check(is_equal_approx(float(score.layers["totality_drone"].db), held_db),
		"Tab log freezes the real outgoing totality fade mid-ramp")
	var transition_deadline := Time.get_ticks_msec() + 7600
	while main.phase != main.Phase.NIGHT and Time.get_ticks_msec() < transition_deadline:
		await process_frame
	check(main.phase == main.Phase.NIGHT, "real _end_totality reaches NIGHT while Tab log stays open")
	var handoff_ms := Time.get_ticks_msec() - handoff_started
	check(handoff_ms <= HANDOFF_BUDGET_MS,
		"real Tab-held totality handoff completes within %d ms (%d ms)" % [HANDOFF_BUDGET_MS, handoff_ms])
	print("score black handoff: handoff_ms=%d setup_ms=%d phase=%s" % [handoff_ms, handoff_started - started_at, main.Phase.keys()[main.phase]])
	for cue in cues:
		var layer: Dictionary = score.layers.get(cue, {})
		check(not bool(layer.get("wanted", true)) and not bool(layer.get("playing", true)),
			"%s layer is stopped at NIGHT black handoff" % cue)
		check(layer.get("player") == null or not is_instance_valid(layer.get("player")),
			"%s AudioStreamPlayer is freed at NIGHT black handoff" % cue)

	var starts_at_night := _cue_start_count(cues)
	main.ui.toggle_log()
	await process_frame
	await process_frame
	check(not main.ui.log_open(), "Tab closes the real history panel after NIGHT")
	check(_cue_start_count(cues) == starts_at_night,
		"closing Tab after NIGHT does not resurrect totality score players")
	# The production night caption/fade is not part of this audio regression.
	# Finish those real scene tweens promptly so no suspended transition objects
	# remain when this headless scene fixture is freed.
	for tween in get_root().get_tree().get_processed_tweens():
		tween.set_speed_scale(100.0)
	var settle_deadline := Time.get_ticks_msec() + 1000
	while main._busy and Time.get_ticks_msec() < settle_deadline:
		await process_frame
	for audio_player in [main.audio_amb, main.audio_click, main.audio_tick]:
		if is_instance_valid(audio_player):
			audio_player.stop()
	await create_timer(0.1).timeout # Drain headless audio callbacks before freeing the real scene.
	main.queue_free()
	await process_frame
	await process_frame


func _cue_start_count(cues: Array) -> int:
	var count := 0
	for entry in ScorePlayer.cue_log:
		if entry.get("event", "") == "start" and entry.get("cue", "") in cues:
			count += 1
	return count


func _goertzel_ratio(samples: PackedFloat32Array, rate: int, frequency: float) -> float:
	if samples.is_empty():
		return 0.0
	var omega := TAU * frequency / rate
	var coeff := 2.0 * cos(omega)
	var s1 := 0.0
	var s2 := 0.0
	var sum_sq := 0.0
	for i in samples.size():
		# Hann weighting limits leakage from notes just outside the probe bin.
		var window := 0.5 - 0.5 * cos(TAU * float(i) / float(samples.size() - 1))
		var weighted := samples[i] * window
		var s := weighted + coeff * s1 - s2
		s2 = s1
		s1 = s
		sum_sq += weighted * weighted
	var power := maxf(0.0, s1 * s1 + s2 * s2 - coeff * s1 * s2)
	var amplitude := sqrt(2.0 * power) / samples.size()
	var rms := sqrt(sum_sq / samples.size())
	return amplitude / maxf(rms, 0.0000001)


func _goertzel_slice_ratio(samples: PackedFloat32Array, start_s: float, end_s: float, frequency: float) -> float:
	var first := maxi(0, roundi(start_s * Score.RATE))
	var last := mini(samples.size(), roundi(end_s * Score.RATE))
	var slice := PackedFloat32Array()
	slice.resize(last - first)
	for i in slice.size():
		slice[i] = samples[first + i]
	return _goertzel_ratio(slice, Score.RATE, frequency)
