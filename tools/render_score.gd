extends SceneTree
## Render the procedural score to auditionable PCM WAV files and report signal metrics.
## Run: godot --headless --path . --script res://tools/render_score.gd -- --out=/private/tmp/score

const Score := preload("res://scripts/audio/score.gd")

const TICK_HZ := 1900.0
const QUIET_FRAME_RMS := 0.001
const FRAME_SECONDS := 0.1


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var output_dir := "user://score"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			output_dir = arg.trim_prefix("--out=")
	if output_dir.begins_with("user://"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	else:
		DirAccess.make_dir_recursive_absolute(output_dir)

	print("score render: output=%s rate=%d" % [output_dir, Score.RATE])
	for cue in Score.CUES:
		var thread := Thread.new()
		var started := Time.get_ticks_usec()
		var err := thread.start(Callable(Score, "render").bind(str(cue)))
		if err != OK:
			push_error("Could not start score render thread for %s: %s" % [cue, err])
			quit(1)
			return
		var samples: PackedFloat32Array = thread.wait_to_finish()
		var elapsed_ms := float(Time.get_ticks_usec() - started) / 1000.0
		var wav := _wav(samples, Score.RATE, bool(Score.is_loop(str(cue))))
		var file_path := output_dir.path_join("%s.wav" % cue)
		var save_error: Error = wav.save_to_wav(file_path)
		if save_error != OK:
			push_error("Could not write %s: %s" % [file_path, save_error])
			quit(1)
			return
		var metrics := _metrics(samples, Score.RATE)
		print("%s: %.3fs render_worker_ms=%.3f peak=%.6f rms=%.6f silent=%.2f%% 1900hz_ratio=%.8f file=%s" % [
			cue, float(samples.size()) / Score.RATE, elapsed_ms, metrics.peak, metrics.rms,
			metrics.silent_fraction * 100.0, metrics.tick_ratio, file_path,
		])
	quit(0)


func _wav(samples: PackedFloat32Array, rate: int, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	if loop:
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_end = samples.size()
	return wav


func _metrics(samples: PackedFloat32Array, rate: int) -> Dictionary:
	var peak := 0.0
	var sum_sq := 0.0
	for sample in samples:
		peak = maxf(peak, absf(sample))
		sum_sq += sample * sample
	var frames := 0
	var quiet_frames := 0
	var frame_size := maxi(1, roundi(rate * FRAME_SECONDS))
	for start in range(0, samples.size(), frame_size):
		var frame_sq := 0.0
		var frame_end := mini(start + frame_size, samples.size())
		for i in range(start, frame_end):
			frame_sq += samples[i] * samples[i]
		var frame_rms := sqrt(frame_sq / maxf(1.0, float(frame_end - start)))
		frames += 1
		if frame_rms <= QUIET_FRAME_RMS:
			quiet_frames += 1
	return {
		"peak": peak,
		"rms": sqrt(sum_sq / maxf(1.0, float(samples.size()))),
		"silent_fraction": float(quiet_frames) / maxf(1.0, float(frames)),
		"tick_ratio": _goertzel_ratio(samples, rate, TICK_HZ),
	}


func _goertzel_ratio(samples: PackedFloat32Array, rate: int, frequency: float) -> float:
	if samples.is_empty():
		return 0.0
	var omega := TAU * frequency / rate
	var coeff := 2.0 * cos(omega)
	var s1 := 0.0
	var s2 := 0.0
	var sum_sq := 0.0
	for i in samples.size():
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
