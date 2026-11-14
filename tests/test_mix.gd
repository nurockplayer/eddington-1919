extends SceneTree

const Score := preload("res://scripts/audio/score.gd")
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)

func metrics(wav: AudioStreamWAV) -> Vector2:
	var data := wav.data
	var sum_sq := 0.0
	var peak := 0.0
	for i in range(0, data.size(), 2):
		var sample := data.decode_s16(i) / 32768.0
		sum_sq += sample * sample
		peak = maxf(peak, absf(sample))
	return Vector2(linear_to_db(sqrt(sum_sq / (data.size() / 2))), linear_to_db(peak))

func band(label: String, value: float, low: float, high: float) -> void:
	print("mix: %s %.2f dBFS" % [label, value])
	check(value >= low and value <= high, "%s %.2f outside %.1f to %.1f" % [label, value, low, high])

func ogg_rms_db(stream: AudioStream) -> float:
	var pb := stream.instantiate_playback()
	pb.start(0.0)
	var remaining := int(ceil(stream.get_length() * 44100.0))
	var sum_sq := 0.0
	var count := 0
	while remaining > 0:
		var block: PackedVector2Array = pb.mix_audio(1.0, mini(4096, remaining))
		for frame in block:
			sum_sq += frame.x * frame.x + frame.y * frame.y
		count += block.size() * 2
		remaining -= block.size()
		if block.size() < mini(4096, remaining + block.size()):
			break
	return linear_to_db(sqrt(sum_sq / count))

func check_playing_players(node: Node, allowed: Array) -> void:
	if (node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D) and node.playing:
		check(node in allowed, "unexpected playing audio player: " + str(node.get_path()))
	for child in node.get_children():
		check_playing_players(child, allowed)

func _run() -> void:
	for cue in Score.SAMPLED_RMS_DB:
		if Score.is_sampled(cue):
			var stream := Score._sampled(cue)
			stream.loop = false
			var measured := ogg_rms_db(stream)
			check(absf(measured - Score.SAMPLED_RMS_DB[cue]) <= 0.75, "%s measured %.2f vs table %.2f" % [cue, measured, Score.SAMPLED_RMS_DB[cue]])
			band(cue, measured + Score.level_db(cue), -26.0, -22.0)
		var fallback := Score._wav(Score.render(cue), Score.RATE, Score.is_loop(cue))
		# The synthesized fallback has its own level when the OGG is absent.
		band(cue + " fallback", metrics(fallback).x + Score.SYNTH_DB[cue], -26.0, -22.0)
	var layers := []
	for cue in ["totality_drone", "totality_glass", "totality_edge"]:
		layers.append(Score.stream(cue).data)
	var sum_sq := 0.0
	for i in range(0, layers[0].size(), 2):
		var sample := 0.0
		for j in 3:
			sample += layers[j].decode_s16(i) / 32768.0 * db_to_linear(Score.level_db(["totality_drone", "totality_glass", "totality_edge"][j]))
		sum_sq += sample * sample
	band("totality sum", linear_to_db(sqrt(sum_sq / (layers[0].size() / 2))), -26.0, -22.0)
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(not "audio_amb" in game, "no audio_amb property")
	check(game.find_child("audio_amb", true, false) == null, "no audio_amb node")
	for name in ["audio_insects", "audio_surf", "audio_birds"]:
		var p: AudioStreamPlayer = game.get(name)
		band(name, metrics(p.stream).x + p.volume_db, -44.0, -38.0)
	for name in ["audio_tick", "audio_click", "audio_open", "audio_change", "audio_third"]:
		var p: AudioStreamPlayer = game.get(name)
		band(name, metrics(p.stream).y + p.volume_db, -18.0, -10.0)
	for surface in game.player._steps:
		for wav in game.player._steps[surface]:
			band("step " + surface, metrics(wav).y + game.player._step_player.volume_db, -18.0, -10.0)
	game.ui._build_viewer_sfx()
	for name in game.ui._viewer_sfx:
		var p: AudioStreamPlayer = game.ui._viewer_sfx[name]
		band("viewer " + name, metrics(p.stream).y + p.volume_db, -18.0, -10.0)
	game._start_night_bed()
	await create_timer(3.2).timeout
	band("insects tween", metrics(game.audio_insects.stream).x + game.audio_insects.volume_db, -44.0, -38.0)
	var allowed := []
	for property in game.get_property_list():
		if property.name.begins_with("audio_"):
			allowed.append(game.get(property.name))
	for layer in game.score.layers.values():
		allowed.append(layer.player)
	check_playing_players(game, allowed)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	print("test_mix: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
