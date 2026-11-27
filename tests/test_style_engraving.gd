extends SceneTree

const Style := preload("res://scripts/style.gd")
const Engraving := preload("res://scripts/styles/engraving.gd")
const Settings := preload("res://scripts/settings.gd")
const World := preload("res://scripts/world_builder.gd")

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
	var shader_text := FileAccess.get_file_as_string("res://shaders/style_engraving.gdshader")
	var cloud_shader := FileAccess.get_file_as_string("res://shaders/eclipse_cloud.gdshaderinc")
	check(cloud_shader.contains("dens = mix(dens, rehearsal_density, near_practice_sun);"),
		"the rehearsal solar override blends into the live field away from the Sun")
	for name in Engraving.UNIFORMS:
		check(shader_text.contains("uniform float " + name + " "), "shader uniform " + name)
		check(Engraving.PARAMS.has(name), "parameter for " + name)
	for name in Engraving.PARAMS:
		check(Engraving.PARAMS[name] is float, "float parameter " + name)
	for token in ["hint_screen_texture", "hint_depth_texture", "hint_normal_roughness_texture", "POSITION = vec4(VERTEX.xy, 1.0, 1.0)"]:
		check(shader_text.contains(token), "shader contains " + token)
	check(shader_text.contains("floor(uv * depth_size) + vec2(0.5)")
		and shader_text.contains("if (border_depth < 0.00001) day_edge = 1.0;")
		and shader_text.contains("edge = mix(edge, day_edge, day_weight);"),
		"daylight ridge prints where its depth touches sky and fades into totality")
	check(shader_text.contains("float heightening = sky ? sky_white : 0.0;"),
		"camp surfaces share the darkening paper while the horizon keeps its glow")
	for name in {"cloud_time": "float", "practice_cloud": "float", "cloud_scale": "float", "cloud_tex": "sampler2D", "wind": "vec2"}:
		var kind: String = {"cloud_tex": "sampler2D", "wind": "vec2"}.get(name, "float")
		check(shader_text.contains("uniform " + kind + " " + name + " "), "live cloud parameter " + name)
	check(shader_text.contains("float thin_cloud = step(0.35, cloud_field.y);")
		and shader_text.contains("float dense_cloud = step(0.85, cloud_field.y);")
		and shader_text.contains("cloud_wash = plate_cloud * band_lines * totality_plate;"), "cloud plate has crisp density steps")
	check(shader_text.contains("float density = eclipse_cloud_density_from_sample(cloud);")
		and shader_text.contains("cloud_field = print_cloud(live_cloud, sky_plate_darkness);")
		and shader_text.contains("live_cloud.x = mix(live_cloud.x, pocket_print_density(ray_w, print_time, live_cloud.x, false), pocket_print);")
		and shader_text.contains("solar_density = eclipse_cloud_density_from_sample(live_cloud);"),
		"the contour uses the drifting pocket and the solar veil adds the seam")
	check(shader_text.contains("if (night <= 0.5 && sky_plate_darkness > 0.0) {\n\t\t\tcloud_field = print_cloud")
		and shader_text.contains("if (night <= 0.5) {\n\t\t\tink *= sky_plate_darkness;\n\t\t\tcloud_wash *= sky_plate_darkness;"),
		"the existing cloud plate grades its ruling and wash with darkness")
	check(shader_text.contains("if (before_second_contact && practice_cloud < 0.0 && night <= 0.5 && print_darkness < 0.35) {")
		and shader_text.contains("float density = eclipse_cloud_density_from_sample(live_cloud);")
		and shader_text.contains("ink = mix(cloud_ink * band_lines, ink,"),
		"density-cut strokes replace the daytime sky ruling before second contact outside rehearsal")
	check(not shader_text.contains("for (int bank") and not shader_text.contains("1.0 - visible_diamond));"), "no invented banks or diamond-dependent disc fill")
	check(shader_text.contains("moon_ink = before_second_contact ? 0.0 :")
		and shader_text.contains("if (!before_second_contact && solar_fade > 0.0 && front > 0.0)"),
		"engraving hides Moon ink and corona before second contact")
	var sky_shader := FileAccess.get_file_as_string("res://shaders/eclipse_sky.gdshader")
	check(sky_shader.contains("totality_darkness = before_second_contact ? 0.0 : darkness")
		and sky_shader.contains("totality_darkness * cloud_visibility * corona")
		and sky_shader.contains("1.0 - in_moon * 0.9, totality_darkness"),
		"underlying sky hides the corona and full Moon disc before second contact")

	var saved_quality := Settings.quality
	var saved_scale := root.scaling_3d_scale
	var saved_msaa := root.msaa_3d
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var post_puddles: Array = game.find_children("*", "MeshInstance3D", true, false).filter(
		func(mesh): return mesh.mesh is CylinderMesh and mesh.position.is_equal_approx(Vector3(2.6, 0.03, -0.4)))
	check(post_puddles.is_empty(), "no placeholder puddle at the front shelter post")
	_test_hud_paper(game)
	await _test_choices_caption(game)
	check(game._style != null and game._style.id == "engraving", "engraving by default")
	check(Style.from_args({"no-grade": ""}) == null, "existing no-grade comparison preserved")
	check(game.env.tonemap_mode == Environment.TONE_MAPPER_LINEAR, "linear tonemap")
	check(game.env.tonemap_exposure == 1.0, "neutral tonemap exposure")
	check(not game.env.adjustment_enabled, "no grade")
	check(not game.env.glow_enabled, "no glow")
	check(not game.env.sdfgi_enabled, "no SDFGI")
	check(not game.env.volumetric_fog_enabled, "no volumetric fog")
	var quads := get_nodes_in_group(Style.QUAD_GROUP)
	check(quads.size() == 1, "one style quad")
	var material: ShaderMaterial = game._style.quad_material
	check(quads.size() == 1 and quads[0].material_override == material and material.shader == Engraving.SHADER, "quad uses engraving shader")
	check(material.render_priority == RenderingServer.MATERIAL_RENDER_PRIORITY_MIN, "transparent objects draw after engraving")
	var labels: Array[Node] = game.find_children("*", "Label3D", true, false)
	check(labels.size() > 0 and labels[0].modulate == Engraving.INK and labels[0].outline_modulate == Engraving.PAPER, "labels use print palette")
	check(game.world.sun_crescents.material_override.get_shader_parameter("print_paper") == Engraving.PAPER, "crescents use paper colour")
	check(game.world.sun_crescents.material_override.get_shader_parameter("print_ink") == Engraving.INK, "crescents use ink rim")
	for name in Engraving.PARAMS:
		check(material.get_shader_parameter(name) == Engraving.PARAMS[name], "material parameter " + name)
	check(material.get_shader_parameter("line_px") == 5.0, "default line spacing")
	var pilot: Array = game.find_children("*", "MeshInstance3D", true, false).filter(
		func(mesh): return mesh.has_meta(World.PILOT_MATERIALS))
	var swatches := {}
	var telescope_parts := 0
	for mesh in pilot:
		for entry in mesh.get_meta(World.PILOT_MATERIALS):
			var active: Material = mesh.material_override if entry[0] < 0 else mesh.get_surface_override_material(entry[0])
			check(active == entry[2], "daylight installs the opaque surface print")
			swatches[active.get_shader_parameter("swatch")] = true
			if "horizontal_tube" in str(mesh.get_path()):
				telescope_parts += 1
				check(active.shader == World.ENGRAVING_SURFACE and active.get_shader_parameter("swatch") == 4,
					"telescope part binds the surface shader's wider-rim swatch")
	check(telescope_parts >= 3, "telescope has printed parts")
	check(swatches.size() == 5, "ground, timber, canvas, dense ink and telescope are bound in the scene")
	check(material.get_shader_parameter("star_keyline_px") == 1.0 and material.get_shader_parameter("star_keyline_all") == 1.0, "one pixel keyline around every visible star")
	check(material.get_shader_parameter("diamond_radius") == 0.45 and material.get_shader_parameter("diamond_spikes") == 4.0 and material.get_shader_parameter("diamond_ray_floor") == 0.70, "diamond defaults")
	check(material.get_shader_parameter("sun_r") == game.sim.SUN_R, "solar radius")
	check(game.sky_mat.get_shader_parameter("third_contact") == Vector2.ZERO, "diamond starts off")
	check(material.get_shader_parameter("paper") == Engraving.PAPER, "paper colour")
	check(game.player.camera.fov == 60.0, "camera FOV")
	check(game._look_sun == 1.8, "sun gain")
	game.sky_mat.set_shader_parameter("practice_cloud", -1.0)
	game._apply_light(1.0, 1.0, 230.0, 0.0)
	check(material.get_shader_parameter("darkness") == 1.0, "totality darkness")
	check(game.sky_mat.get_shader_parameter("before_second_contact") == false
		and material.get_shader_parameter("before_second_contact") == false, "totality reveals both solar layers")
	check(material.get_shader_parameter("night") == 0.0, "totality is daytime")
	_check_totality_visibility(shader_text, material, 0.0)
	_check_totality_visibility(shader_text, material, 1.0)
	game._apply_light(0.62, 0.0, -150.0, 0.0)
	check(material.get_shader_parameter("darkness") == 0.0, "daylight darkness")
	game._apply_light(0.62, 0.0, -150.0, 1.0)
	check(material.get_shader_parameter("night") == 1.0, "night follows lighting")
	for mesh in pilot:
		for entry in mesh.get_meta(World.PILOT_MATERIALS):
			var active: Material = mesh.material_override if entry[0] < 0 else mesh.get_surface_override_material(entry[0])
			check(active == entry[1], "night restores the original material")
	game._apply_light(0.62, 0.0, -150.0, 0.0)
	check(material.get_shader_parameter("night") == 0.0, "night clears in daylight")
	game.sky_mat.set_shader_parameter("cloud_time", 304.4)
	game.sky_mat.set_shader_parameter("practice_cloud", 0.97)
	game.sky_mat.set_shader_parameter("wind", Vector2(0.005, 0.003))
	game.sky_mat.set_shader_parameter("cloud_scale", 0.4)
	game.phase = game.Phase.TITLE
	game._process(0.0)
	for name in ["cloud_tex", "cloud_time", "practice_cloud", "wind", "cloud_scale"]:
		check(material.get_shader_parameter(name) == game.sky_mat.get_shader_parameter(name), "live cloud sync " + name)
	game.sky_mat.set_shader_parameter("practice_cloud", -1.0)
	Settings.quality = "standard"
	Settings.apply_quality(self)
	check(not game.env.sdfgi_enabled, "standard quality preserves SDFGI off")
	check(not game.env.volumetric_fog_enabled, "standard quality preserves volumetric fog off")
	game._start_game()
	for seconds in [30.0, 10.0, 0.0]:
		game.prep_left = seconds
		game._update_sky_prep()
		check(game.sky_mat.get_shader_parameter("before_second_contact") == true
			and material.get_shader_parameter("before_second_contact") == true,
			"approach darkness leaves the corona and full Moon disc hidden at %.0f seconds" % seconds)
	game.prep_left = game.PREP_S
	game._update_sky_prep()
	game._begin_rehearsal()
	game._process(0.0)
	var thick: float = material.get_shader_parameter("practice_cloud")
	game._process(3.0)
	var thin: float = material.get_shader_parameter("practice_cloud")
	check(is_equal_approx(thick, 0.93) and is_equal_approx(thin, 0.12)
		and material.get_shader_parameter("darkness") < 0.01, "early rehearsal sends thick and thin cloud to the compositor")
	check(is_equal_approx(material.get_shader_parameter("cloud_time"), 3.0 - game.PREP_S)
		and is_equal_approx(game.prep_left, game.PREP_S), "rehearsal drifts the live cloud without advancing the observation countdown")
	game.free()
	_test_eclipse_pilot_bindings(shader_text)

	var overridden := Style.from_args({"style-set": "wash=0.3,line_px=7,diamond_radius=0.4,diamond_spikes=3,diamond_rays=0.5,diamond_ray_floor=0.85"})
	check(is_equal_approx(overridden.params.wash, 0.3), "wash override")
	check(overridden.params.line_px == 7.0, "line spacing override")
	check(overridden.params.diamond_radius == 0.4 and overridden.params.diamond_spikes == 3.0 and overridden.params.diamond_rays == 0.5 and overridden.params.diamond_ray_floor == 0.85, "diamond overrides")
	Settings.quality = saved_quality
	root.scaling_3d_scale = saved_scale
	root.msaa_3d = saved_msaa
	print("test_style_engraving: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _check_totality_visibility(shader: String, material: ShaderMaterial, seam_blend: float) -> void:
	# Evaluate the shipping fragment expressions on the CPU, as in test_third_contact_gap.
	# Probe the disc, limb and an outer ray at the same totality time.
	var clock: Vector3 = material.get_shader_parameter("third_contact_cloud_clock")
	var pocket_time := (float(material.get_shader_parameter("cloud_time")) - clock.x) / clock.y
	var disc: Array[float] = []
	var corona: Array[float] = []
	var blends := RegEx.create_from_string(
		"print_colour = [^;]+sun_crescent[^;]*;\\s*print_colour = ([^;]+);\\s*print_colour = ([^;]+);"
	).search(shader)
	if blends == null:
		check(false, "find the solar compositing expressions")
		return
	for cloud: Vector2 in [Vector2(0.20, 0.20), Vector2(0.50, 0.50), Vector2(0.95, 0.95), Vector2(0.20, 0.95)]:
		var outer_density := cloud.x
		var inner_density := cloud.y
		var detached_ray := outer_density < inner_density
		var values := {
			"print_darkness": material.get_shader_parameter("darkness"),
			"before_second_contact": material.get_shader_parameter("before_second_contact"),
			"practice_cloud": material.get_shader_parameter("practice_cloud"),
			"pocket_time": pocket_time, "returning_sky": false,
			"sun_cloud": inner_density, "live_cloud": Vector2(outer_density, 0.0),
			"solar_density": outer_density, "inner_density": inner_density, "seam_blend": seam_blend, "front": 1.0,
			"moon_pixel": 0.01, "rays": float(detached_ray), "ink_col": 0.0, "white": 1.0,
		}
		for name in ["solar_fade", "cloud_cutoff", "pocket_softness", "sun_visibility", "thin_veil",
				"cloud_veil", "moon_cover", "moon_cloud", "cloud_covers_sun", "corona_base", "corona_cloud"]:
			values[name] = _solar_value(shader, name, values)
		for radius in ([1.5] if detached_ray else [0.0, 1.02]):
			values.r = radius
			values.moon_disc = _solar_value(shader, "moon_disc", values)
			values.moon_ink = _solar_value(shader, "moon_ink", values)
			values.limb_white = _solar_value(shader, "limb_white", values)
			values.corona_white = _solar_value(shader, "corona_white", values)
			if (values.cloud_covers_sun or seam_blend > 0.0) and values.corona_white > 0.0:
				values.corona_white *= 1.0 - _solar_value(shader, "inner_cover", values)
			values.print_colour = 0.5
			values.print_colour = _evaluate_solar(blends.get_string(1), values)
			var colour := _evaluate_solar(blends.get_string(2), values)
			if detached_ray:
				check(absf(colour - 0.5) < 0.001,
					"thick inner cloud hides the clear outer ray (contrast %.3f)" % (colour - 0.5))
			elif radius < 1.0:
				disc.append(0.5 - colour)
			else:
				corona.append(colour - 0.5)
	var measured := "disc %s, corona %s (clear, thin, thick; seam %.1f)" % [disc, corona, seam_blend]
	check(disc[0] >= disc[1] and disc[1] > 0.01 and absf(disc[2]) < 0.001,
		"the Moon disc shows through clear and thin sky and disappears under thick cloud: " + measured)
	check(corona[0] > corona[1] and corona[1] > 0.01 and absf(corona[2]) < 0.001,
		"corona visibility falls from clear to thin to hidden: " + measured)
	print("Totality visibility: " + measured)


func _solar_value(shader: String, name: String, values: Dictionary) -> float:
	var assignment := RegEx.create_from_string("\\b" + name + " = ([^;]+);").search_all(shader)
	if assignment.is_empty():
		check(false, "find the fragment expression for " + name)
		return NAN
	# The fragment initializes its output weights to zero before drawing the sky.
	return _evaluate_solar(assignment.back().get_string(1), values)


func _evaluate_solar(code: String, values: Dictionary) -> float:
	code = code.replace("mix(", "lerpf(").replace("vec3(1.0)", "white")
	code = RegEx.create_from_string("\\bstep\\(").sub(code, "_shader_step(", true)
	var branches := RegEx.create_from_string("^([a-z_]+) \\? ([^:]+) : (.+)$").search(code)
	if branches != null:
		code = "lerpf(%s, %s, float(%s))" % [branches.get_string(3), branches.get_string(2), branches.get_string(1)]
	var expression := Expression.new()
	if expression.parse(code, PackedStringArray(values.keys())) != OK:
		check(false, "parse solar expression '%s': %s" % [code, expression.get_error_text()])
		return NAN
	var result: Variant = expression.execute(values.values(), self)
	if expression.has_execute_failed():
		check(false, "evaluate solar expression '%s': %s" % [code, expression.get_error_text()])
		return NAN
	return float(result)


func _shader_step(edge: float, value: float) -> float:
	return float(value >= edge)


func _test_eclipse_pilot_bindings(shader_text: String) -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	_check_distant_land_bindings(game)
	game._begin_totality()
	# Complete the real second-contact holds without waiting on wall time.
	get_processed_tweens().back().custom_step(1.0)
	get_processed_tweens().back().custom_step(2.0)
	var material: ShaderMaterial = game._style.quad_material
	var pilot := game.find_children("*", "MeshInstance3D", true, false).filter(
		func(mesh): return mesh.has_meta(World.PILOT_MATERIALS))
	check(not pilot.is_empty(), "scene has pilot materials to restore")
	check(material.get_shader_parameter("darkness") == 1.0
		and material.get_shader_parameter("before_second_contact") == false,
		"second contact reaches the totality print")
	check(material.get_shader_parameter("day_return_cloud_time") == -1.0,
		"totality does not bind the fixed return sky")
	for mesh in pilot:
		_check_original_pilot_binding(mesh, "totality restores original materials")
	game.t_game = game.sim.TOTALITY_S
	game._process_totality(0.0)
	game._day_return.custom_step(0.6)
	var darkness: float = material.get_shader_parameter("darkness")
	check(darkness > 0.0 and darkness < 1.0, "third contact starts the daylight recovery")
	check(material.get_shader_parameter("diamond") > 0.0
		and material.get_shader_parameter("diamond") == game.sky_mat.get_shader_parameter("third_contact").y,
		"third-contact diamond is bound to the engraving")
	_check_return_cloud_bindings(game, game.sim.TOTALITY_S + game.THIRD_CONTACT_CLOUD_S * 0.2)
	for mesh in pilot:
		_check_original_pilot_binding(mesh, "third contact retains original materials")
	game._day_return.custom_step(11.4)
	check(material.get_shader_parameter("darkness") == 0.0
		and game.sky_mat.get_shader_parameter("darkness") == 0.0,
		"both solar layers reach daylight in 12 seconds")
	check(material.get_shader_parameter("diamond") == 0.0, "daylight clears the diamond")
	_check_return_cloud_bindings(game, game.sim.TOTALITY_S + game.THIRD_CONTACT_CLOUD_S)
	_check_return_outline(game, shader_text)
	for mesh in pilot:
		_check_original_pilot_binding(mesh, "live daylight recovery retains original materials")
	_test_return_paper(game)
	game.free()


func _check_return_cloud_bindings(game: Node, live_time: float) -> void:
	var material: ShaderMaterial = game._style.quad_material
	check(material.get_shader_parameter("day_return_cloud_time") == game.sim.TOTALITY_S,
		"return sky print stays bound to the end-of-totality cloud time")
	check(is_equal_approx(material.get_shader_parameter("cloud_time"), live_time)
		and is_equal_approx(game.sky_mat.get_shader_parameter("cloud_time"), live_time),
		"return solar layers share the advancing cloud time")


func _check_return_outline(game: Node, shader_text: String) -> void:
	check(shader_text.contains("outline_sample(uv, outline_px * pixel")
		and shader_text.contains("outline_sample(uv, 0.5 * pixel")
		and shader_text.contains("edge = mix(totality_outline.x, daylight_outline.x, day_weight);")
		and shader_text.contains("edge = mix(edge, day_edge, day_weight);"),
		"the return blends fixed outline samples on both sides of the silhouette")
	check(is_zero_approx(game.sky_mat.get_shader_parameter("darkness")), "daylight returns in 12 seconds")


func _check_distant_land_bindings(game: Node) -> void:
	var material: ShaderMaterial = game._style.quad_material
	check(material.get_shader_parameter("darkness") == 0.0 and material.get_shader_parameter("night") == 0.0,
		"daylight enables the compositor's ridge treatment")
	check(material.get_shader_parameter("far_start") == 25.0
		and material.get_shader_parameter("far_end") == 70.0
		and material.get_shader_parameter("far_line") == 0.0,
		"sky-side contours bind the distant-edge fade")
	var camera: Camera3D = game.player.camera
	var has_distant_ridge := false
	for ridges in get_nodes_in_group("far_ridges"):
		for mesh: MeshInstance3D in ridges.find_children("*", "MeshInstance3D", true, false):
			for vertex in mesh.mesh.get_faces():
				var point: Vector3 = mesh.global_transform * vertex
				var distance := camera.global_position.distance_to(point)
				if distance > 70.0 and distance < camera.far and Vector2(point.x, point.z).length() > 75.0 and point.y > -0.39:
					has_distant_ridge = true
					break
	check(has_distant_ridge, "scene supplies ridge geometry in the distant-edge and daylight land ranges")


func _test_return_paper(game: Node) -> void:
	var ui: Node = game.ui
	var saved_motion := Settings.reduced_motion
	var blue: Color = Engraving.PAGES.tot_paper
	var labels := [
		[ui.objectives.get_parent(), ui.objectives, "default_color"],
		[ui.tot_panel, ui.tot_label, "default_color"],
		[ui.tot_panel, ui.tot_hint, "font_color"],
		[ui.tot_panel, ui.callout, "font_color"],
		[ui.dialog_panel, ui.speaker_label, "font_color"],
		[ui.dialog_panel, ui.text_label, "default_color"],
		[ui.dialog_panel, ui.hint_label, "font_color"],
		[ui.dialogue_portrait, ui.dialogue_portrait.disclosure, "font_color"],
		[ui.clock_label, ui.clock_label, "font_color"],
		[ui.prompt_label, ui.prompt_label, "font_color"],
		[ui.caption, ui.caption, "font_color"],
		[ui.toast, ui.toast, "font_color"],
	]
	var frames := range(0, int(game.DAY_RETURN_S * 60) + 1)
	frames.append(14 * 60)
	for reduced_motion in [false, true]:
		Settings.reduced_motion = reduced_motion
		var wipe_frames := 0
		for frame in frames:
			var elapsed: float = frame / 60.0
			game._update_day_return(elapsed)
			var darkness: float = game._style.quad_material.get_shader_parameter("darkness")
			var paper := Engraving.PAPER.lerp(blue, darkness)
			wipe_frames += int(ui.text_label.material != null)
			for entry in labels:
				var label: Control = entry[1]
				var slip: StyleBoxFlat = entry[0].get_theme_stylebox("normal" if entry[0] == label else "panel")
				var ink := label.get_theme_color(entry[2])
				_check_slip(slip, ink, paper, 3.5)
				check(label.get_theme_constant("outline_size") == 0, "return text has no outline at %.3f s" % elapsed)
				check(ink == Engraving.PAPER or ink == Engraving.INK, "return text only uses the original inks")
				check(label.material == ui.text_label.material, "return text shares the ink transition")
				if label.material != null:
					for channel in ["light_ink", "dark_ink"]:
						var wipe_ink: Color = label.material.get_shader_parameter(channel)
						check(wipe_ink == (Engraving.PAPER if channel == "light_ink" else Engraving.INK)
							and _contrast(wipe_ink, slip.bg_color) >= 3.5, "both original inks read during the wipe")
				if elapsed >= game.DAY_RETURN_S:
					check(slip.bg_color == Engraving.PAPER and slip.border_color == Engraving.INK and ink == Engraving.INK,
						"return ends on exact daylight paper and ink")
			check(ui.dialogue_portrait.image.self_modulate.is_equal_approx(Color.WHITE.lerp(blue.lerp(Color.WHITE, 0.4), darkness)),
				"portrait follows page darkness at %.3f s (reduced motion %s)" % [elapsed, reduced_motion])
		check(wipe_frames >= 15 and wipe_frames <= 21, "ink transition takes about 0.3 s")
	Settings.reduced_motion = saved_motion


func _check_original_pilot_binding(mesh: MeshInstance3D, message: String) -> void:
	for entry in mesh.get_meta(World.PILOT_MATERIALS):
		var surface: int = entry[0]
		var active: Material = mesh.material_override if surface < 0 else mesh.get_surface_override_material(surface)
		check(active == entry[1], "%s (%s, surface %d)" % [message, mesh.get_path(), surface])


func _test_hud_paper(game: Node) -> void:
	var ui: Node = game.ui
	var was_title: bool = ui.title_panel.visible
	var was_busy: bool = game._busy
	ui.title_panel.hide()
	game._busy = false
	game._process_interaction(0)
	check(ui.crosshair.modulate == Color.WHITE, "interaction cannot fade or tint the crosshair slip")
	ui.title_panel.visible = was_title
	game._busy = was_busy
	for state in [[0.0, 0.0, Engraving.PAPER], [1.0, 0.0, Engraving.PAGES.tot_paper], [0.0, 1.0, Engraving.PAGES.safe_paper]]:
		game._apply_light(0.62, state[0], -150.0, state[1])
		for label in [ui.clock_label, ui.prompt_label, ui.toast, ui.caption]:
			check(label.has_theme_stylebox_override("normal"), "HUD text has its own slip: " + str(label.get_path()))
			if label.has_theme_stylebox_override("normal"):
				_check_slip(label.get_theme_stylebox("normal"), label.get_theme_color("font_color"), state[2])
		check(not ui.crosshair.has_theme_stylebox_override("normal"), "crosshair mark has no slip")
		check(ui.crosshair.get_theme_constant("outline_size") > 0, "crosshair has a contrasting edge")
		check(ui.dialog_panel.get_theme_stylebox("panel").bg_color == state[2], "dialogue uses the scene's paper")
		for panel in [ui.objectives.get_parent(), ui.tot_panel, ui.dialog_panel, ui.dialogue_portrait]:
			var slip: StyleBoxFlat = panel.get_theme_stylebox("panel")
			var text: Color = ui.hint_label.get_theme_color("font_color")
			_check_slip(slip, text, state[2])
		check(ui.hint_label.get_theme_color("font_color") == ui.speaker_label.get_theme_color("font_color"), "dialogue hint has the same ink as its speaker")
		check(ui.dialogue_portrait.disclosure.get_theme_color("font_color") == ui.hint_label.get_theme_color("font_color"), "portrait caption has the same ink as dialogue")
		var tint: Color = Color.WHITE
		if state[1] > 0.5:
			tint = Engraving.PAGES.safe_light
		elif state[0] > 0.5:
			tint = Engraving.PAGES.tot_paper.lerp(Color.WHITE, 0.4)
		check(ui.dialogue_portrait.image.self_modulate == tint, "portrait takes the scene's light")
	game._apply_light(0.62, 0, -150, 0)
	ui.set_objectives("[color=#a99]Grey line[/color]")
	check(not ui.objectives.text.contains("[color"), "authored objective colour cannot override page ink")
	ui.set_totality(true, "[color=#fd8]Exposure[/color]")
	ui.set_prompt("Shutter")
	check(not ui.prompt_label.visible and not ui.crosshair.visible, "totality leaves the corona free of central HUD")
	check(not ui.tot_label.text.contains("[color"), "exposure colour cannot override page ink")
	ui.set_totality(false)
	ui.set_hold(0.5)
	check(not ui.prompt_label.get_global_rect().grow(16).intersects(ui.hold_bar.get_global_rect()), "hold bar clears the prompt paper margin")
	ui.set_hold(0)


func _test_choices_caption(game: Node) -> void:
	var ui: Node = game.ui
	var title_visible: bool = ui.title_panel.visible
	ui.title_panel.hide()
	ui.play([{"s":"Eddington", "t":"Choice", "key":"choice", "choices":["First", "Second"]}])
	ui._layout_dialogue_portrait()
	check(ui.dialogue_portrait.disclosure.autowrap_mode == TextServer.AUTOWRAP_OFF, "portrait caption uses explicit line breaks")
	for state in [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]]:
		game._apply_light(0.62, state[0], -150, state[1])
		for selected in [0, 1]:
			ui._choice_buttons[selected].grab_focus()
			var chosen: Button = ui._choice_buttons[selected]
			var other: Button = ui._choice_buttons[1 - selected]
			var normal: StyleBoxFlat = other.get_theme_stylebox("normal")
			var reverse: StyleBoxFlat = chosen.get_theme_stylebox("normal")
			check(reverse.bg_color != normal.bg_color, "selected choice differs from normal in polarity " + str(state))
			check(reverse.bg_color == other.get_theme_color("font_color") and chosen.get_theme_color("font_color") == normal.bg_color, "selected choice reverses ink and paper")
			check(other.get_theme_stylebox("hover").border_width_left > normal.border_width_left, "unfocused hover has a heavier rule")
			check(chosen.get_theme_stylebox("pressed").bg_color == reverse.bg_color, "pressed choice reverses too")
	ui._choose(0)
	var locale := L.current()
	for language in ["en", "ja", "zh_TW", "ko"]:
		L.apply(language)
		var tween: Tween = ui.show_caption(L.t("接下來的六個夜晚\n暗房裡，底片一張張沖洗出來（時間壓縮）"))
		tween.kill()
		await process_frame
		var rect: Rect2 = ui.caption.get_global_rect()
		var viewport: Rect2 = ui.caption.get_viewport_rect()
		check(viewport.encloses(rect.grow(16)), language + " caption slip is inside viewport")
		check(absf(rect.get_center().x - viewport.get_center().x) <= 2 and absf(rect.get_center().y - viewport.get_center().y) <= 2, language + " caption centred within 2 px")
	L.apply(locale)
	ui.caption.modulate.a = 0
	ui.dialogue_portrait.hide()
	ui.title_panel.visible = title_visible
	game._apply_light(0.62, 0, -150, 0)


func _check_slip(slip: StyleBoxFlat, text: Color, paper: Color, minimum_contrast := 4.5) -> void:
	check(slip.bg_color.a == 1.0, "slip is solid")
	check(slip.bg_color.is_equal_approx(paper), "slip uses the scene's paper")
	check(_contrast(text, slip.bg_color) >= minimum_contrast, "slip text contrast >= %.1f" % minimum_contrast)


func _contrast(text: Color, paper: Color) -> float:
	var fill := text.srgb_to_linear().get_luminance() + 0.05
	var stock := paper.srgb_to_linear().get_luminance() + 0.05
	return maxf(fill, stock) / minf(fill, stock)
