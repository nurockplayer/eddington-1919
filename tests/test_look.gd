extends SceneTree

const Look := preload("res://scripts/look.gd")
const Settings := preload("res://scripts/settings.gd")

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
	var saved_quality := Settings.quality
	var saved_motion := Settings.reduced_motion
	var defaults := Look.PRINCIPE.duplicate()
	check(Look.principe() == defaults, "default parameters")
	var changed := Look.principe("saturation=1.3,tonemap=agx,sdfgi=0,fov=55")
	check(changed.saturation is float and is_equal_approx(changed.saturation, 1.3), "float override")
	check(changed.tonemap == "agx", "tonemap override")
	check(changed.sdfgi is int and changed.sdfgi == 0, "integer override")
	check(changed.fov is float and changed.fov == 55.0, "FOV override")
	for key in defaults:
		if key not in ["saturation", "tonemap", "sdfgi", "fov"]:
			check(changed[key] == defaults[key], "unchanged " + key)
	check(Look.PRINCIPE == defaults, "constant unchanged")
	check(Look.override_errors("saturation=1.3").is_empty(), "valid override")
	var invalid := "bogus=1,tonemap=neon,exposure=abc,novalue"
	check(Look.override_errors(invalid).size() == 4, "invalid overrides reported")
	check(Look.principe(invalid) == defaults, "invalid overrides ignored")
	check(Look.override_errors("").is_empty(), "empty overrides")
	var toned := Look.principe_lut(1.0).gradient
	for i in [3, 4]:
		var c := toned.get_color(i)
		check(c.r == c.g and c.g == c.b and c.r == toned.get_offset(i), "white remains neutral")
	check(toned.get_color(1).b > toned.get_color(1).r, "cool shadows")
	var neutral := Look.principe_lut(0.0).gradient
	for i in neutral.get_point_count():
		var c := neutral.get_color(i)
		check(c.r == c.g and c.g == c.b and c.r == neutral.get_offset(i), "neutral stop")
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	Settings.quality = "standard"
	Settings.apply_quality(self)
	check(game.env.tonemap_mode == Environment.TONE_MAPPER_ACES, "ACES")
	check(game.env.tonemap_white == 5.0, "white point")
	check(is_equal_approx(game.env.adjustment_saturation, 1.18), "saturation")
	check(game.env.sdfgi_enabled and game.env.volumetric_fog_enabled, "GI and fog enabled")
	check(game.env.fog_sky_affect == 0.0 and game.env.volumetric_fog_sky_affect == 0.0, "sky unaffected by fog")
	check(game.sun.directional_shadow_blend_splits, "shadow splits")
	check(game.player.camera.fov == 60.0, "camera FOV")
	var posts := get_nodes_in_group("look_post")
	check(posts.size() == 1, "one post layer")
	if posts.size() == 1:
		var post = posts[0]
		check(post is CanvasLayer and post.layer < game.ui.layer, "post below UI")
		Settings.reduced_motion = true
		var seed = post.material.get_shader_parameter("grain_seed")
		for i in 3:
			await process_frame
		check(post.material.get_shader_parameter("grain_seed") == seed, "reduced motion keeps grain still")
	game._apply_light(1.0, 1.0, 0.0, 0.0)
	check(game.sun.light_energy == 0.0, "totality sun off")
	game._apply_light(0.0, 0.0, 400.0, 1.0)
	check(game.sun.light_energy == 0.0, "night sun off")
	game._apply_light(0.62, 0.0, -150.0, 0.0)
	check(game.sun.light_energy >= 0.3 * 1.8, "cloud floor")
	check(game.env.ambient_light_energy == 0.5, "ambient gain")
	game._apply_light(0.97, 0.9, -10.0, 0.0)
	check(game.sun.light_energy < 0.3 * 1.8, "floor fades")
	game.free()
	var chapter = load("res://scenes/cambridge.tscn").instantiate()
	root.add_child(chapter)
	await process_frame
	var cambridge_env: Environment = chapter.world.environment.environment
	check(is_equal_approx(cambridge_env.adjustment_saturation, Look.SATURATION), "Cambridge grade")
	check(not cambridge_env.sdfgi_enabled, "Cambridge GI unchanged")
	check(get_nodes_in_group("look_post").is_empty(), "no Cambridge post")
	chapter.free()
	Settings.quality = saved_quality
	Settings.reduced_motion = saved_motion
	Settings.apply_quality(self)
	print("test_look: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
