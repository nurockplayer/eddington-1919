extends SceneTree
## The Príncipe beds follow the real phase changes: the birds fall quiet when
## totality begins, dusk insects enter before the score, the surf dips through the
## quiet gap after second contact, and night keeps its bed.
const BEDS := ["birds", "insects", "surf"]
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
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	check(game.audio_birds.playing and game.audio_surf.playing, "the day beds play before totality")
	var apparatus := [game.audio_open, game.audio_click, game.audio_change, game.audio_tick]
	var apparatus_db: Array = apparatus.map(func(p): return p.volume_db)
	var sfx_bus := AudioServer.get_bus_index("SFX")
	var sfx_db := AudioServer.get_bus_volume_db(sfx_bus)
	game.phase = game.Phase.PREP
	await game._begin_totality()
	check(game.phase == game.Phase.TOTALITY and "birds_quiet" in game._sfx_log, "beginning totality quiets the birds")
	check(game.audio_surf.playing, "the surf goes on through totality")
	check(game.audio_insects.playing and game.audio_insects.bus == "SFX" and game.audio_insects.volume_db <= -59.0,
		"second contact starts the dusk insect player near silence on SFX")
	check(not game.audio_birds.playing, "second contact has no remaining bird calls")
	check(not game.score.layers.get("totality_drone", {}).get("playing", false)
		and not game.score.layers.get("totality_glass", {}).get("playing", false),
		"second contact holds both music layers silent")
	game._process_totality(1.9)
	check(not game.score.layers.get("totality_drone", {}).get("playing", false)
		and not game.score.layers.get("totality_glass", {}).get("playing", false),
		"both music layers remain silent at 1.9 real seconds")
	game._toggle_shutter()
	game._process_totality(0.11)
	check(game.score.layers.get("totality_drone", {}).get("playing", false), "drone starts just after two real seconds")
	game._process_totality(1.3)
	check(game.score.layers["totality_drone"].db > -60.0
		and game.score.layers["totality_glass"].db <= -79.0, "drone fades in while exposure keeps glass ducked")
	game._toggle_shutter()
	game._process_totality(0.01)
	game._process_totality(1.3)
	check(game.score.layers["totality_glass"].db > -60.0, "glass returns after the exposure")
	await create_timer(3.2).timeout
	check(is_equal_approx(game.audio_insects.volume_db, game._insects_db - 6.0),
		"totality insects fade to six dB below the normal night bed")
	check(apparatus.map(func(p): return p.volume_db) == apparatus_db
		and is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), sfx_db),
		"shutter, exposure apparatus and SFX bus retain their pre-totality levels")
	game._end_totality()
	game._process_totality(1.6)
	await create_timer(4.6).timeout
	check(not game.audio_insects.playing, "third contact fades and stops the dusk insects")
	check(not game.score.layers["totality_drone"].playing and not game.score.layers["totality_glass"].playing,
		"third contact finishes the score fades")
	game._begin_night()
	await create_timer(4.5).timeout
	check(not game.audio_surf.playing and not game.audio_birds.playing, "night stops the surf and the birds")
	check(game.audio_insects.playing and "insects" in game._sfx_log, "night starts the insects")
	check(is_equal_approx(game.audio_insects.volume_db, game._insects_db), "night restores its original insect level")
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	await _second_contact_gap()
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


## Combined bed level in dBFS: each playing bed's measured RMS plus its player volume.
func ambience_db(game: Node) -> float:
	var power := 0.0
	for name in BEDS:
		var p: AudioStreamPlayer = game.get("audio_" + name)
		if p.playing:
			power += pow(db_to_linear(p.volume_db + game.BED_RMS_DB[name]), 2.0)
	return linear_to_db(sqrt(power))


## F6 on the real timeline: from second contact until the first score cue the beds sit
## at least 12 dB under the pre-contact mix, then the surf swells back without a step.
func _second_contact_gap() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	for name in BEDS:
		check(game._bed_sampled(name), name + " is a sampled bed, measured in BED_RMS_DB")
	var surf_db: float = game.audio_surf.volume_db
	var open_db: float = game.audio_open.volume_db
	var sfx_bus := AudioServer.get_bus_index("SFX")
	var sfx_db := AudioServer.get_bus_volume_db(sfx_bus)
	game.phase = game.Phase.PREP
	var before := ambience_db(game)
	await game._begin_totality()
	# Second contact: the totality view is revealed and the game's own clock takes over.
	var contact := Time.get_ticks_usec()
	game.set_process(true)
	var gap_max := ambience_db(game)
	var insects_db: float = game.audio_insects.volume_db
	var insects_start := insects_db
	var insects_rising := true
	var insects_ramp_error := 0.0
	var exposed := false
	var closed := false
	var score_s := -1.0
	while true:
		await process_frame
		var t := (Time.get_ticks_usec() - contact) / 1e6
		if game.score.layers.has("totality_drone") or game.score.layers.has("totality_glass"):
			score_s = t
			break
		if t > 3.0:
			break
		gap_max = maxf(gap_max, ambience_db(game))
		insects_rising = insects_rising and game.audio_insects.volume_db >= insects_db
		insects_db = game.audio_insects.volume_db
		var expected_insects := lerpf(-60.0, game._insects_db + game.TOTALITY_INSECTS_TRIM_DB, t / game.TOTALITY_INSECTS_FADE_S)
		insects_ramp_error = maxf(insects_ramp_error, absf(insects_db - expected_insects))
		if t >= 1.0 and not exposed:
			exposed = true
			var shutter := InputEventAction.new()
			shutter.action = "shutter"
			shutter.pressed = true
			root.push_input(shutter)
			check(game.sim.is_exposing() and game._sfx_log.back() == "open" and game.audio_open.playing,
				"the shutter opens an exposure and sounds inside the quiet gap")
		if t >= 1.5 and exposed and not closed:
			closed = true
			var shutter := InputEventAction.new()
			shutter.action = "shutter"
			shutter.pressed = true
			root.push_input(shutter)
			check(not game.sim.is_exposing() and "close" in game._sfx_log and game.audio_click.playing,
				"the shutter closes the exposure and sounds inside the quiet gap")
	check(score_s >= 1.8 and score_s <= 2.5, "the first score cue enters 1.8-2.5 s after second contact (%.2f s)" % score_s)
	check(exposed and closed, "both shutter actions ran during the quiet gap")
	check(gap_max <= before - 12.0,
		"the gap ambience sits >= 12 dB under the pre-contact mix (%.1f vs %.1f dBFS)" % [gap_max, before])
	check(insects_start <= -59.0 and insects_rising and insects_ramp_error < 1.0,
		"the dusk insects rise from silence through the gap without a jump")
	check(is_equal_approx(game.audio_open.volume_db, open_db) and is_equal_approx(AudioServer.get_bus_volume_db(sfx_bus), sfx_db),
		"the shutter and the SFX bus keep their levels")
	# After the cue the surf comes back on its own swell, never in a step.
	var surf_prev: float = game.audio_surf.volume_db
	var surf_rising := true
	var max_step := 0.0
	var near_s := -1.0
	while (Time.get_ticks_usec() - contact) / 1e6 < score_s + 10.0:
		await process_frame
		var surf: float = game.audio_surf.volume_db
		surf_rising = surf_rising and surf >= surf_prev
		max_step = maxf(max_step, surf - surf_prev)
		surf_prev = surf
		if near_s < 0.0 and surf >= surf_db - 1.0:
			near_s = (Time.get_ticks_usec() - contact) / 1e6 - score_s
	check(surf_rising and max_step <= 2.0, "the surf swells back without an audible step (largest frame step %.2f dB)" % max_step)
	check(near_s >= 2.0, "the surf takes more than two seconds to come back (%.2f s)" % near_s)
	check(game.audio_surf.playing and is_equal_approx(game.audio_surf.volume_db, surf_db),
		"the surf is back at its pre-totality level within 10 s of the cue, long before third contact")
	print("F6: pre-contact %.2f dBFS; gap maximum %.2f dBFS; reduction %.2f dB; first score %.2f s; insect ramp error %.2f dB; surf maximum step %.2f dB" % [before, gap_max, before - gap_max, score_s, insects_ramp_error, max_step])
	game.set_process(false)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
