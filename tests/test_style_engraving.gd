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
	for name in {"third_contact_gap": "float", "cloud_time": "float", "practice_cloud": "float", "cloud_scale": "float", "cloud_tex": "sampler2D", "wind": "vec2"}:
		var kind: String = {"cloud_tex": "sampler2D", "wind": "vec2"}.get(name, "float")
		check(shader_text.contains("uniform " + kind + " " + name + " "), "live cloud parameter " + name)
	check(shader_text.contains("front * moon_disc * max(diamond, print_darkness) * (1.0 - step(0.85, sun_cloud))")
		and shader_text.contains("mix(print_colour, ink_col, moon_ink)"), "the Moon is whole whenever the corona is visible")
	check(shader_text.contains("float thin_cloud = step(0.35, cloud_field.y);")
		and shader_text.contains("float dense_cloud = step(0.85, cloud_field.y);")
		and shader_text.contains("cloud_wash = plate_cloud * band_lines * totality_plate;"), "cloud plate has crisp density steps")
	check(shader_text.contains("float density = eclipse_cloud_density(direction);")
		and shader_text.contains("cloud_field = print_cloud(ray_w, print_darkness);"), "contours use the live exposure field")
	check(not shader_text.contains("for (int bank") and not shader_text.contains("1.0 - visible_diamond));"), "no invented banks or diamond-dependent disc fill")
	check(shader_text.contains("max(0.5 * step(0.35, cloud_field.y), step(0.85, cloud_field.y))")
		and shader_text.contains("step(0.85, sun_cloud)") and shader_text.contains("step(1.0, r) * (1.0 - cloud_veil)"), "cloud density veils the corona")
	check(shader_text.contains("moon_ink = before_second_contact ? 0.0 :")
		and shader_text.contains("if (!before_second_contact && print_darkness > 0.0 && front > 0.0)"),
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
	var telescope_ink := 0
	for mesh in pilot:
		for entry in mesh.get_meta(World.PILOT_MATERIALS):
			var active: Material = mesh.material_override if entry[0] < 0 else mesh.get_surface_override_material(entry[0])
			check(active == entry[2], "daylight installs the opaque surface print")
			swatches[active.get_shader_parameter("swatch")] = true
			if "horizontal_tube" in str(mesh.get_path()) and active.get_shader_parameter("swatch") == World.Swatch.TELESCOPE:
				telescope_ink += 1
	check(telescope_ink >= 3, "telescope dark parts take the dense-ink swatch")
	check(swatches.size() == 5, "ground, timber, canvas, dense ink and telescope are bound in the scene")
	check(material.get_shader_parameter("star_keyline_px") == 1.0 and material.get_shader_parameter("star_keyline_all") == 1.0, "one pixel keyline around every visible star")
	check(material.get_shader_parameter("diamond_radius") == 0.45 and material.get_shader_parameter("diamond_spikes") == 4.0 and material.get_shader_parameter("diamond_ray_floor") == 0.70, "diamond defaults")
	check(material.get_shader_parameter("sun_r") == game.sim.SUN_R, "solar radius")
	check(game.sky_mat.get_shader_parameter("third_contact") == Vector2.ZERO, "diamond starts off")
	check(material.get_shader_parameter("paper") == Engraving.PAPER, "paper colour")
	check(game.player.camera.fov == 60.0, "camera FOV")
	check(game._look_sun == 1.8, "sun gain")
	game._apply_light(1.0, 1.0, 230.0, 0.0)
	check(material.get_shader_parameter("darkness") == 1.0, "totality darkness")
	check(game.sky_mat.get_shader_parameter("before_second_contact") == false
		and material.get_shader_parameter("before_second_contact") == false, "totality reveals both solar layers")
	check(material.get_shader_parameter("night") == 0.0, "totality is daytime")
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
	game.sky_mat.set_shader_parameter("third_contact_gap", 0.75)
	game.sky_mat.set_shader_parameter("cloud_time", 304.4)
	game.sky_mat.set_shader_parameter("practice_cloud", 0.97)
	game.sky_mat.set_shader_parameter("wind", Vector2(0.005, 0.003))
	game.sky_mat.set_shader_parameter("cloud_scale", 0.4)
	game.phase = game.Phase.TITLE
	game._process(0.0)
	for name in ["cloud_tex", "cloud_time", "third_contact_gap", "practice_cloud", "wind", "cloud_scale"]:
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
	game.free()
	_test_eclipse_pilot_bindings()

	var overridden := Style.from_args({"style-set": "wash=0.3,line_px=7,diamond_radius=0.4,diamond_spikes=3,diamond_rays=0.5,diamond_ray_floor=0.85"})
	check(is_equal_approx(overridden.params.wash, 0.3), "wash override")
	check(overridden.params.line_px == 7.0, "line spacing override")
	check(overridden.params.diamond_radius == 0.4 and overridden.params.diamond_spikes == 3.0 and overridden.params.diamond_rays == 0.5 and overridden.params.diamond_ray_floor == 0.85, "diamond overrides")
	Settings.quality = saved_quality
	root.scaling_3d_scale = saved_scale
	root.msaa_3d = saved_msaa
	print("test_style_engraving: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


func _test_eclipse_pilot_bindings() -> void:
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game._start_game()
	game._begin_totality()
	# Complete the real second-contact holds without waiting on wall time.
	get_processed_tweens().back().custom_step(1.0)
	get_processed_tweens().back().custom_step(2.0)
	var pilot: Array[MeshInstance3D] = game._style.impl.pilot_meshes
	for mesh in pilot:
		_check_original_pilot_binding(mesh, "totality restores original materials")
	game.t_game = game.sim.TOTALITY_S
	game._process_totality(0.0)
	game._day_return.custom_step(game.DAY_RETURN_S)
	check(is_zero_approx(game.sky_mat.get_shader_parameter("darkness")), "daylight returns in 12 seconds")
	for mesh in pilot:
		_check_original_pilot_binding(mesh, "live daylight recovery retains original materials")
	game.free()


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


func _check_slip(slip: StyleBoxFlat, text: Color, paper: Color) -> void:
	check(slip.bg_color.a == 1.0, "slip is solid")
	check(slip.bg_color == paper, "slip uses the scene's paper")
	var a := text.srgb_to_linear().get_luminance()
	var b := slip.bg_color.srgb_to_linear().get_luminance()
	check((maxf(a, b) + 0.05) / (minf(a, b) + 0.05) >= 4.5, "slip text contrast >= 4.5")
