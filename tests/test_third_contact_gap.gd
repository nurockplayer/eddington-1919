extends SceneTree
## Third contact keeps the live cloud field and the approved exposure simulation.
const Sim := preload("res://scripts/eclipse_sim.gd")
const Cues := preload("res://scripts/totality_cues.gd")
const Judgment := preload("res://scripts/judgment.gd")
var checks := 0
var failures := 0
var solar := {}


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	# P2 (#351) intentionally changes drive drift; pin that approved simulation,
	# including the unchanged exposure/plate and seeded cloud model.
	check(FileAccess.get_sha256("res://scripts/eclipse_sim.gd") == "b3a9c3bf179b79d44ecd6bd0f39bf79878884bda1deaa83a9ab88fa7ef451af2", "simulation matches the approved P2 oracle")
	var engraving := FileAccess.get_file_as_string("res://shaders/style_engraving.gdshader")
	for name in ["solar_fade", "sun_visibility", "cloud_veil", "moon_cloud", "corona_cloud"]:
		var expression := RegEx.create_from_string("float " + name + " = ([^;]+);").search(engraving)
		check(expression != null, "engraving defines " + name)
		if expression != null:
			var parsed := Expression.new()
			var code := expression.get_string(1).replace("mix(", "lerpf(")
			check(parsed.parse(code, ["print_darkness", "sun_cloud", "live_cloud", "sun_visibility", "cloud_veil"]) == OK,
				"evaluate shipping " + name)
			solar[name] = parsed
	var cloud := FileAccess.get_file_as_string("res://shaders/eclipse_cloud.gdshaderinc")
	check(cloud.contains("gap = third_contact_cloud_gap(d, time);")
		and cloud.contains("1.25 * elapsed - 0.86")
		and cloud.contains("smoothstep(1.1, 3.65, length(offset * vec2(1.0, 1.25)))")
		and cloud.contains("smoothstep(3.5, 5.0, length(local_sun))")
		and cloud.contains("return mix(cloud.x, min(cloud.x, 0.22), cloud.y);"), "sky draws the sampled pocket and its density")
	check(engraving.contains("front * moon_disc * solar_fade * moon_cloud")
		and engraving.contains("step(1.0, r) * corona_cloud")
		and engraving.contains("corona_white * solar_fade"), "engraving applies the measured visibility to the Moon and corona")
	for seed_ in [7, 1551]:
		await _check_seed(seed_)
	print("%d third contact gap checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check_seed(seed_: int) -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(seed_)
	game.sky_mat.set_shader_parameter("cloud_tex", ImageTexture.create_from_image(game.sim.cloud_img))
	var ref = Sim.new(seed_)
	# Exercise the actual exposure path across the contact window, once
	# closing just before contact and once leaving the shutter open at contact.
	game.phase = game.Phase.TOTALITY
	game.tot_done = false
	game._busy = false
	game.plates_left = game.sim.plates_available()
	game.t_game = 300.0
	for sunlit in [false, true]:
		game.sim.open_shutter(game.t_game)
		ref.open_shutter(game.t_game)
		var steps := 7 if not sunlit else 1
		for i in steps:
			game._process_totality(0.25 / Sim.TIME_SCALE)
			ref.accumulate(0.25, ref.cloud_over_sun(game.t_game))
		if not sunlit:
			game._toggle_shutter()
			var p: Dictionary = ref.close_shutter(false)
			p.sky_read = Cues.sky_band(p.clear, p.duration)
		else:
			ref.close_shutter(true)
	check(var_to_bytes(game.sim.plates) == var_to_bytes(ref.plates), "seed %d: plate bytes identical to the simulation oracle before/at third contact" % seed_)
	check(var_to_bytes(Judgment.grade(game.sim, "hopeful", "measured")) == var_to_bytes(Judgment.grade(ref, "hopeful", "measured")), "seed %d: scoring bytes identical to the simulation oracle" % seed_)
	_check_front(game, seed_)
	game.stop_all_audio()
	game.queue_free()
	await process_frame


func _check_front(game: Node, seed_: int) -> void:
	game._day_return.kill()
	game.tot_done = false
	game.t_game = Sim.TOTALITY_S - (3.0 + 2.0 / 60.0) * game._totality_rate
	var step := 1.0 / 60.0
	game._process_totality(step)
	var clock: Variant = game.sky_mat.get_shader_parameter("third_contact_cloud_clock")
	check(clock is Vector3, "seed %d: real contact flow supplies the cloud clock" % seed_)
	if not clock is Vector3 or solar.size() != 5:
		return
	var plate: ShaderMaterial = game._style.quad_material
	var sun: Vector3 = game.sim.sun_dir
	var tangent := sun.cross(Vector3.UP).normalized()
	var up := tangent.cross(sun)
	# Probe the facing and far limbs, and the transverse cuts through each mark.
	var rays: Array[Vector3] = []
	for p in [Vector2(-1.2, 0), Vector2(1.2, 0), Vector2(0, -1.2), Vector2(0, 1.2),
			Vector2(-0.65, 0), Vector2(0.65, 0), Vector2(0, -0.65), Vector2(0, 0.65)]:
		var offset: Vector2 = p * Sim.SUN_R
		rays.append(sun * sqrt(1.0 - offset.length_squared()) + tangent * offset.x + up * offset.y)
	var previous_darkness := 1.0
	var previous_density := 0.0
	var previous_amount: Array[float] = []
	var density_step := 0.0
	var drawn_step := 0.0
	var edge_crossed := false
	var start_density := 0.0
	var contact_density := 0.0
	var contact_frame := -1
	for frame in range(17 * 60):
		if game.tot_done:
			var tween: Tween = game._day_return
			if tween.is_valid():
				tween.custom_step(step)
		else:
			game._process_totality(step)
			if game.tot_done:
				contact_frame = frame
				game._day_return.pause()
		var t: float = game.sky_mat.get_shader_parameter("cloud_time")
		var darkness: float = plate.get_shader_parameter("darkness")
		check(darkness <= previous_darkness, "seed %d: sky recovers on frame %d" % [seed_, frame])
		check(plate.get_shader_parameter("cloud_time") == t and plate.get_shader_parameter("third_contact_cloud_clock") == clock,
			"seed %d: both materials sample the same field on frame %d" % [seed_, frame])
		var centre_cloud: Vector2 = game.Cues.third_contact_cloud_sample(game.sim, sun, t, clock)
		var density: float = game.Cues.third_contact_cloud_density(centre_cloud)
		if frame == 0:
			start_density = density
		else:
			density_step = maxf(density_step, absf(density - previous_density))
		if frame == contact_frame:
			contact_density = density
		var amount: Array[float] = []
		var args := [darkness, centre_cloud.x, Vector2.ZERO, 0.0, 0.0]
		var light: float = solar.solar_fade.execute(args)
		args[3] = solar.sun_visibility.execute(args)
		for i in rays.size():
			args[2] = game.Cues.third_contact_cloud_sample(game.sim, rays[i], t, clock)
			args[4] = solar.cloud_veil.execute(args)
			var gate: Expression = solar.corona_cloud if i < 4 else solar.moon_cloud
			amount.append(light * float(gate.execute(args)))
			if frame > 0:
				drawn_step = maxf(drawn_step, absf(amount[i] - previous_amount[i]))
		edge_crossed = edge_crossed or (contact_frame < 0 and amount[0] > 0.35 and amount[1] < 0.05)
		previous_darkness = darkness
		previous_density = density
		previous_amount = amount
		if contact_frame >= 0 and frame == contact_frame + 13 * 60:
			break
	check(start_density - contact_density > 0.4 and contact_density < 0.35,
		"seed %d: Sun-centre density opens from %.3f to %.3f at contact" % [seed_, start_density, contact_density])
	check(edge_crossed, "seed %d: the leading corona shows while the far limb is still clouded" % seed_)
	check(density_step <= (start_density - contact_density) * step + 0.00001 and drawn_step <= step + 0.00001,
		"seed %d: per-frame density and eclipse coverage steps %.5f and %.5f" % [seed_, density_step, drawn_step])
	check(previous_darkness == 0.0 and previous_amount.max() == 0.0,
		"seed %d: eclipse detail fades completely by daylight" % seed_)
	print("seed %d: density %.3f -> %.3f at contact, max frame steps density=%.5f drawn=%.5f" %
		[seed_, start_density, contact_density, density_step, drawn_step])
