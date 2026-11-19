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
	var shader := FileAccess.get_file_as_string("res://shaders/style_engraving.gdshader")
	check(shader.contains("ALBEDO = texture(return_night, uv).rgb;") and shader.contains("ALBEDO = texture(return_day, uv).rgb;") and shader.contains("ALBEDO = paper;"), "only the two endpoint plates and paper white can reach the compositor")
	for seed_ in [7, 1919]:
		var game = load("res://scenes/main.tscn").instantiate()
		game.next_seed = seed_
		root.add_child(game)
		game.set_process(false)
		game.player.set_physics_process(false)
		game.t_game = game.sim.TOTALITY_S
		game._apply_light(1.0, 1.0, game.t_game, 0.0)
		game._style.impl.start_day_return(game, game._style)
		var front: Node = game._style.impl.day_return
		front.set_process(false)
		check(not front.started() and front.plates[1].render_target_update_mode == SubViewport.UPDATE_DISABLED, "unseen day endpoint does not draw before the front")
		check(front.plates[0].size == root.size and front.plates[1].size == root.size, "endpoint plates use the physical render size")
		var changes := 0
		var previous: Color = game.ui.hint_label.get_theme_color("font_color")
		for frame in 181:
			front.elapsed = frame / 60.0
			front._sync()
			var v: float = frame / 180.0
			game._apply_light(1.0 - v * 0.2, 1.0 - v * v, game.t_game + v * 10.0, 0.0)
			var foreground: Color = game.ui.hint_label.get_theme_color("font_color")
			if foreground != previous:
				changes += 1
				check(front.started(), "HUD changes on the front, never on darkness 0.5")
			previous = foreground
			check(front.materials[0].get_shader_parameter("darkness") == 1.0 and front.materials[1].get_shader_parameter("darkness") == 0.0, "both endpoint plate weights stay fixed")
			check(is_equal_approx(game.sky_mat.get_shader_parameter("darkness"), 1.0 - v * v), "native lighting tween stays unchanged")
			if frame == 51:
				check(front.radius() >= game.sim.SUN_R and front.radius() < 2.0 * game.sim.SUN_R and shader.contains("return_radius < 2.0 * sun_r"), "first white front covers the whole Moon")
		front.elapsed = 5.5
		front._sync()
		front.elapsed += 1.5
		front._sync()
		check(game._style.quad_material.get_shader_parameter("return_blend") == 1.0, "day glow reaches the live print before release")
		check(changes == 1, "HUD switches palette exactly once")
		game.stop_all_audio()
		game.free()
		await process_frame
	print("test_day_return: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
