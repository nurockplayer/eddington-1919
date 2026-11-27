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
	# Pin the P2 simulation with the middle-totality seam added in #589.
	check(FileAccess.get_sha256("res://scripts/eclipse_sim.gd") == "478fb62d10452787416e0a6baa4cb8345f5882380c871048cd5fb175360d4070", "simulation matches the P2 oracle with the middle seam")
	var engraving := FileAccess.get_file_as_string("res://shaders/style_engraving.gdshader")
	var ternary := RegEx.create_from_string("^([a-z_]+) \\? ([^:]+) : (.+)$")
	for name in ["solar_fade", "pocket_print", "pocket_softness", "sun_visibility", "thin_veil",
			"cloud_veil", "moon_cover", "moon_cloud", "corona_base", "corona_cloud"]:
		var expression := RegEx.create_from_string("float " + name + " = ([^;]+);").search(engraving)
		check(expression != null, "engraving defines " + name)
		if expression != null:
			var parsed := Expression.new()
			var code := expression.get_string(1).replace("mix(", "lerpf(")
			# Expression accepts lerpf over scalar inputs, but not GLSL's ternary.
			var branches := ternary.search(code)
			if branches != null:
				code = "lerpf(%s, %s, float(%s))" % [branches.get_string(3), branches.get_string(2), branches.get_string(1)]
			var result := parsed.parse(code, ["print_darkness", "sun_cloud", "live_cloud", "sun_visibility", "cloud_veil",
				"pocket_time", "practice_cloud", "pocket_softness", "cloud_time", "thin_veil",
				"cloud_cutoff", "returning_sky", "cloud_covers_sun", "moon_cloud",
				"solar_density", "seam_blend", "moon_cover", "corona_base", "band_body"])
			check(result == OK, "evaluate shipping " + name + ": " + parsed.get_error_text())
			if result == OK:
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
	check(engraving.contains("float sun_cloud = eclipse_cloud_sample_at(sun_dir, cloud_time, false).x;")
		and engraving.contains("1.0 - smoothstep(0.35, 0.80, eclipse_cloud_density(direction))"),
		"Sun-centre and field-star gates use the original cloud field")
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
	if not clock is Vector3 or solar.size() != 10:
		return
	var plate: ShaderMaterial = game._style.quad_material
	var sun: Vector3 = game.sim.sun_dir
	var mid_time := Sim.TOTALITY_S / 2.0
	var mid_cloud := Cues.third_contact_cloud_sample(game.sim, sun, mid_time, clock)
	check(mid_cloud.y == 0.0, "seed %d: mid-totality is outside the pocket" % seed_)
	# Sweep centre and ray density independently through the totality gates.
	for density in [0.30, 0.32, 0.35, 0.49, 0.78, 0.80, 0.81, 0.84, 0.85, 0.93]:
		var args := [1.0, density, Vector2(density, mid_cloud.y), 0.0, 0.0, (mid_time - clock.x) / clock.y,
			-1.0, 0.0, mid_time, 0.0, 0.0, false, false, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
		args[7] = solar.pocket_softness.execute(args)
		args[3] = solar.sun_visibility.execute(args)
		args[12] = args[3] < 1.0
		var expected_sun := 1.0 - smoothstep(0.80, 0.85, density)
		check(is_equal_approx(args[3], expected_sun), "seed %d: mid-totality Sun visibility at density %.2f" % [seed_, density])
		for ray_density in [0.29, 0.32, 0.35, 0.49, 0.80, 0.83, 0.85, 0.93]:
			args[2] = Vector2(ray_density, mid_cloud.y)
			args[9] = solar.thin_veil.execute(args)
			args[4] = solar.cloud_veil.execute(args)
			args[10] = float(ray_density >= 0.85)
			args[14] = ray_density
			args[16] = solar.moon_cover.execute(args)
			args[13] = solar.moon_cloud.execute(args)
			args[17] = solar.corona_base.execute(args)
			var expected_moon := float(ray_density < 0.85)
			var thin_veil := 0.5 * smoothstep(0.30, 0.35, ray_density)
			var expected_corona := expected_moon * (1.0 - thin_veil) if expected_sun < 1.0 \
				else 1.0 - maxf(thin_veil, smoothstep(0.80, 0.85, ray_density))
			check(is_equal_approx(solar.corona_cloud.execute(args), expected_corona)
				and is_equal_approx(args[13], expected_moon),
				"seed %d: totality Moon and corona gates at centre %.2f, ray %.2f" % [seed_, density, ray_density])
	var warp_args := [1.0, mid_cloud.x, mid_cloud, 0.0, 0.0, (mid_time - clock.x) / clock.y,
		-1.0, 0.0, mid_time, 0.0, 0.0, false, false, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	check(solar.pocket_print.execute(warp_args) == 1.0, "seed %d: contour bends in mid-totality" % seed_)
	warp_args[5] = -6.5
	warp_args[8] = clock.x - 6.5 * clock.y
	check(solar.pocket_print.execute(warp_args) == 0.0, "seed %d: third-contact clip uses the accepted contour" % seed_)
	var tangent := sun.cross(Vector3.UP).normalized()
	var up := tangent.cross(sun)
	# Probe the facing and far limbs, and the transverse cuts through each mark.
	var rays: Array[Vector3] = []
	var inner_rays: Array[Vector3] = []
	for p in [Vector2(-1.2, 0), Vector2(1.2, 0), Vector2(0, -1.2), Vector2(0, 1.2),
			Vector2(-0.65, 0), Vector2(0.65, 0), Vector2(0, -0.65), Vector2(0, 0.65)]:
		var offset: Vector2 = p * Sim.SUN_R
		rays.append(sun * sqrt(1.0 - offset.length_squared()) + tangent * offset.x + up * offset.y)
		if p.length() > 1.0:
			var inner := offset.normalized() * (1.125 * Sim.SUN_R)
			inner_rays.append(sun * sqrt(1.0 - inner.length_squared()) + tangent * inner.x + up * inner.y)
	var previous_darkness := 1.0
	var previous_density := 0.0
	var previous_amount: Array[float] = []
	var previous_masks: Array[int] = []
	var previous_thin_transmission: Array[float] = []
	var density_step := 0.0
	var drawn_step := 0.0
	var edge_crossed := false
	var moon_matches_mask := true
	var returning_sky := false
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
		returning_sky = plate.get_shader_parameter("day_return_cloud_time") >= 0.0
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
		var masks: Array[int] = []
		var thin_transmission: Array[float] = []
		var from_contact: float = t - clock.x
		var pocket_time: float = from_contact / (clock.y if from_contact < 0.0 else clock.z)
		var args := [darkness, centre_cloud.x, Vector2.ZERO, 0.0, 0.0, pocket_time, -1.0, 0.0, t,
			0.0, 0.0, returning_sky, false, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
		var light: float = solar.solar_fade.execute(args)
		args[7] = solar.pocket_softness.execute(args)
		args[3] = solar.sun_visibility.execute(args)
		var cloud_covers_sun: bool = not returning_sky and args[3] < 1.0
		args[12] = cloud_covers_sun
		for i in rays.size():
			var cloud := Cues.third_contact_cloud_sample(game.sim, rays[i], t, clock)
			var ray_density := Cues.third_contact_cloud_density(cloud)
			var dense := ray_density >= 0.85
			args[2] = cloud
			args[9] = solar.thin_veil.execute(args)
			args[4] = solar.cloud_veil.execute(args)
			args[10] = float(dense)
			args[14] = ray_density
			args[16] = solar.moon_cover.execute(args)
			args[13] = solar.moon_cloud.execute(args)
			var gate: float = args[13]
			var mask := int(returning_sky)
			if i < inner_rays.size():
				args[17] = solar.corona_base.execute(args)
				gate = solar.corona_cloud.execute(args)
				if cloud_covers_sun:
					var inner_cloud := Cues.third_contact_cloud_sample(game.sim, inner_rays[i], t, clock)
					var inner_dense := Cues.third_contact_cloud_density(inner_cloud) >= 0.85
					gate *= float(not inner_dense)
					mask = 2 + int(dense or inner_dense)
			elif not returning_sky:
				moon_matches_mask = moon_matches_mask and is_equal_approx(gate, float(not dense))
				mask = 2 + int(dense)
			amount.append(light * gate)
			masks.append(mask)
			thin_transmission.append(light * (1.0 - 0.5 * smoothstep(0.30, 0.35, cloud.x)))
			# The printed edge is a hard step. Measure continuity between mask changes.
			if frame > 0 and mask == previous_masks[i]:
				var change := amount[i] - previous_amount[i]
				if i < inner_rays.size() and cloud_covers_sun and mask == 2:
					# The exposed corona follows the steeper, ray-local thin veil here.
					change -= thin_transmission[i] - previous_thin_transmission[i]
				drawn_step = maxf(drawn_step, absf(change))
		edge_crossed = edge_crossed or (not returning_sky and contact_frame < 0 and amount[0] > 0.35 and amount[1] < 0.05)
		previous_darkness = darkness
		previous_density = density
		previous_amount = amount
		previous_masks = masks
		previous_thin_transmission = thin_transmission
		if contact_frame >= 0 and frame == contact_frame + 13 * 60:
			break
	check(start_density - contact_density > 0.4 and contact_density < 0.35,
		"seed %d: Sun-centre density opens from %.3f to %.3f at contact" % [seed_, start_density, contact_density])
	check(edge_crossed, "seed %d: the leading corona shows while the far limb is still clouded" % seed_)
	check(moon_matches_mask, "seed %d: the pre-contact Moon follows the printed cloud mask" % seed_)
	check(density_step <= (start_density - contact_density) * step + 0.00001 and drawn_step <= step + 0.00001,
		"seed %d: per-frame density step %.5f and unexplained coverage step %.5f" % [seed_, density_step, drawn_step])
	check(returning_sky and previous_darkness == 0.0 and previous_amount.max() == 0.0,
		"seed %d: eclipse detail fades completely by daylight" % seed_)
	print("seed %d: density %.3f -> %.3f at contact, max frame steps density=%.5f drawn=%.5f" %
		[seed_, start_density, contact_density, density_step, drawn_step])
