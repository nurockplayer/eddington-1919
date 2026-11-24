extends SceneTree

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
	var game = load("res://scenes/main.tscn").instantiate()
	game.next_seed = 7
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game._start_game()
	var print_material: ShaderMaterial = game._style.quad_material
	var last_darkness := -1.0
	for seconds_left in [65.0, 60.0, 45.0, 30.0, 15.0, 0.0]:
		game.prep_left = seconds_left
		game._update_sky_prep()
		var darkness: float = print_material.get_shader_parameter("darkness")
		check(darkness >= last_darkness, "paper darkens through approach")
		if seconds_left >= 60.0:
			check(darkness == 0.0, "paper is daylight before the final minute")
		elif seconds_left > 0.0:
			check(darkness > 0.0 and darkness < 1.0, "approach prints intermediate tones")
		else:
			check(darkness == 1.0, "second contact reaches the totality tone")
		last_darkness = darkness
		check(is_equal_approx(game.sky_mat.get_shader_parameter("contact"), lerpf(0.62, 0.985, 1.0 - seconds_left / game.PREP_S)), "approach keeps the contact geometry")
	game.t_game = game.sim.TOTALITY_S
	for elapsed in [0.0, 0.5, 3.0, 15.0, 30.0, 45.0, 60.0]:
		game._update_day_return(elapsed)
		var darkness: float = print_material.get_shader_parameter("darkness")
		check(darkness <= last_darkness, "paper recovers after third contact")
		if elapsed == 0.0:
			check(darkness == 1.0, "third contact begins in the totality print")
		elif elapsed < 60.0:
			check(darkness > 0.0 and darkness < 1.0, "recovery prints intermediate tones")
		else:
			check(darkness == 0.0, "paper is daylight after one minute")
		last_darkness = darkness
		var v := minf(elapsed / 3.0, 1.0)
		check(is_equal_approx(game.sky_mat.get_shader_parameter("contact"), 1.0 - 0.2 * v), "third contact keeps its geometry and duration")
		check(game.sky_mat.get_shader_parameter("third_contact").is_equal_approx(game.Cues.third_contact_glint(v)), "glint keeps its three-second cue")
		check(is_equal_approx(game.sky_mat.get_shader_parameter("cloud_time"), game.t_game + 10.0 * v), "third contact keeps the live cloud trajectory")
	game.stop_all_audio()
	game.free()
	print("test_day_return: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
