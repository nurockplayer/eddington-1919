extends SceneTree
## The Príncipe beds follow the real phase changes: the birds fall quiet when
## totality begins, and at night the surf and birds give way to the insects.
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
	game.phase = game.Phase.PREP
	game._begin_totality()
	check(game.phase == game.Phase.TOTALITY and "birds_quiet" in game._sfx_log, "beginning totality quiets the birds")
	check(game.audio_surf.playing, "the surf goes on through totality")
	await create_timer(1.0).timeout
	game.score.stop("totality_drone")
	game.score.stop("totality_glass")
	game._begin_night()
	await create_timer(2.0).timeout
	check(not game.audio_surf.playing and not game.audio_birds.playing, "night stops the surf and the birds")
	check(game.audio_insects.playing and "insects" in game._sfx_log, "night starts the insects")
	game.stop_all_audio()
	game.queue_free()
	await process_frame
	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
