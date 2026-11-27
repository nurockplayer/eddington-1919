extends SceneTree
## The Príncipe beds follow the real phase changes: the birds fall quiet when
## totality begins, dusk insects enter before the score, the surf dips through the
## quiet gap after second contact, and night keeps its bed.
const BEDS := ["birds", "insects", "surf"]
const STEP_S := 0.02
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
	check(game.audio_insects.playing and game.audio_insects.volume_db <= -59.0,
		"second contact starts the dusk insect player near silence")
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
	check(AudioServer.get_bus_volume_db(game._totality_actions_bus) > 0.0,
		"third contact keeps action priority through the final cue tails")
	game._process_totality(1.6)
	await create_timer(4.6).timeout
	check(not game.audio_insects.playing, "third contact fades and stops the dusk insects")
	check(not game.score.layers["totality_drone"].playing and not game.score.layers["totality_glass"].playing,
		"third contact finishes the score fades")
	check(is_zero_approx(AudioServer.get_bus_volume_db(game._totality_actions_bus))
		and is_zero_approx(AudioServer.get_bus_volume_db(game._totality_ambience_bus)),
		"third contact releases the action priority and ambience trim")
	game._begin_night()
	await create_timer(4.5).timeout
	check(not game.audio_surf.playing and not game.audio_birds.playing, "night stops the surf and the birds")
	check(game.audio_insects.playing and "insects" in game._sfx_log, "night starts the insects")
	check(is_equal_approx(game.audio_insects.volume_db, game._insects_db), "night restores its original insect level")
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	await _second_contact_gap()
	await _second_contact_gap(true)
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


## Combined bed level in dBFS: each playing bed's measured RMS plus its player volume.
func ambience_db(game: Node) -> float:
	var power := 0.0
	for name in BEDS:
		var p: AudioStreamPlayer = game.get("audio_" + name)
		if p.playing:
			var bus_db := AudioServer.get_bus_volume_db(AudioServer.get_bus_index(p.bus))
			power += pow(db_to_linear(bus_db + p.volume_db + game.BED_RMS_DB[name]), 2.0)
	return linear_to_db(sqrt(power))


func _capture_tweens(driven: Array[Tween]) -> void:
	for tween in get_processed_tweens():
		if tween.is_valid() and not driven.has(tween):
			tween.pause()
			driven.append(tween)


func _step_totality(game: Node, driven: Array[Tween]) -> void:
	game._process_totality(STEP_S)
	_capture_tweens(driven)
	for tween in driven:
		if tween.is_valid():
			tween.custom_step(STEP_S)


## F6 on the real timeline: from second contact until the first score cue the beds sit
## at least 12 dB under the pre-contact mix, then the surf swells back without a step.
func _second_contact_gap(hold_log := false) -> void:
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
	game._start_game()
	var before := ambience_db(game)
	await game._begin_totality()
	# Leave the fade's finished callback before manually stepping scene tweens.
	await process_frame
	# Second contact: drive the real timeline and tweens with real-second deltas,
	# excluding host scheduling stalls and preventing automatic double advancement.
	var driven: Array[Tween] = []
	_capture_tweens(driven)
	var gap_max := ambience_db(game)
	var insects_db: float = game.audio_insects.volume_db
	var insects_start := insects_db
	var insects_rising := true
	var insects_ramp_error := 0.0
	var exposed := false
	var closed := false
	var score_s := -1.0
	for step in range(150):
		_step_totality(game, driven)
		var t: float = game.t_game / game.sim.TIME_SCALE
		if game.score.layers.has("totality_drone") or game.score.layers.has("totality_glass"):
			score_s = t
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
	var action_bus := AudioServer.get_bus_index("Totality Actions")
	var ambience_bus := AudioServer.get_bus_index("Totality Ambience")
	var music_bus := AudioServer.get_bus_index("Totality Music")
	check(AudioServer.get_bus_send(action_bus) == &"SFX" and AudioServer.get_bus_send(ambience_bus) == &"SFX"
		and AudioServer.get_bus_send(music_bus) == &"Music", "totality submixes follow the player's audio controls")
	check(AudioServer.get_bus_volume_db(music_bus) < 0.0, "the totality score plays under its normal level")
	# After the cue the surf comes back on its own swell, never in a step.
	var surf_prev: float = game.audio_surf.volume_db
	var surf_rising := true
	var max_step := 0.0
	var near_s := -1.0
	for step in range(500):
		if hold_log and step == 200:
			# Start a real exposure fade so score progress is observable at the hold.
			game._toggle_shutter()
		_step_totality(game, driven)
		if step == 200:
			if hold_log:
				check(game.sim.is_exposing() and game.audio_open.playing and game.audio_open.bus == &"Totality Actions",
					"a scored exposure sends the shutter to the action submix")
			else:
				game._toggle_shutter()
				game._toggle_shutter()
				game._order_plate_change()
				check(game.change_left > 0.0 and game.audio_click.playing and game.audio_change.playing
					and game.audio_click.bus == &"Totality Actions" and game.audio_change.bus == &"Totality Actions",
					"closing a scored exposure and ordering a change puts both cues on the action submix")
			check(game.audio_tick.playing and game.audio_tick.bus == &"Totality Actions",
				"the metronome counts on the action submix over the score")
			check(AudioServer.get_bus_volume_db(action_bus) > 0.0
				and AudioServer.get_bus_volume_db(ambience_bus) < 0.0,
				"scored totality raises actions and lowers ambience")
		if hold_log and step == 200:
			var held_surf: float = game.audio_surf.volume_db
			var held_time: float = game.t_game
			var held_score: Dictionary = game.score.layers.duplicate(true)
			var tab := InputEventKey.new()
			tab.physical_keycode = KEY_TAB
			tab.pressed = true
			root.push_input(tab)
			check(game.ui.log_open(), "Tab opens the log midway through surf recovery")
			for held_step in range(500):
				_step_totality(game, driven)
			check(is_equal_approx(game.audio_surf.volume_db, held_surf), "the log holds the surf level for ten real seconds")
			check(game.t_game == held_time and game.score.layers == held_score,
				"the log holds totality time and score fade progress alongside the surf")
			root.push_input(tab)
			check(not game.ui.log_open() and is_equal_approx(game.audio_surf.volume_db, held_surf),
				"closing Tab resumes recovery without an immediate jump")
		if hold_log and step == 201:
			check(is_equal_approx(game.score.layers["totality_glass"].elapsed, STEP_S),
				"score fade progress resumes with the surf after closing the log")
		if hold_log and step == 300:
			check(game.audio_surf.volume_db < surf_db - 1.0,
				"two seconds after closing the log the surf still has recovery remaining")
		var surf: float = game.audio_surf.volume_db
		surf_rising = surf_rising and surf >= surf_prev
		max_step = maxf(max_step, surf - surf_prev)
		surf_prev = surf
		if near_s < 0.0 and surf >= surf_db - 1.0:
			near_s = game.t_game / game.sim.TIME_SCALE - score_s
	check(surf_rising and max_step <= 2.0, "the surf swells back without an audible step (largest frame step %.2f dB)" % max_step)
	check(near_s >= 2.0, "the surf takes more than two seconds to come back (%.2f s)" % near_s)
	check(game.audio_surf.playing and is_equal_approx(game.audio_surf.volume_db, surf_db),
		"the surf is back at its pre-totality level within 10 s of the cue, long before third contact")
	print("F6: pre-contact %.2f dBFS; gap maximum %.2f dBFS; reduction %.2f dB; first score %.2f s; insect ramp error %.2f dB; surf maximum step %.2f dB" % [before, gap_max, before - gap_max, score_s, insects_ramp_error, max_step])
	game.set_process(false)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
