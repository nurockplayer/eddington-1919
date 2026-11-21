extends SceneTree
## The Príncipe beds follow the real phase changes: the birds fall quiet when
## totality begins, dusk insects enter before the score, and night keeps its bed.
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
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
