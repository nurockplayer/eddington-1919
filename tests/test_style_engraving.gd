extends SceneTree

const Style := preload("res://scripts/style.gd")
const Engraving := preload("res://scripts/styles/engraving.gd")
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
	var shader_text := FileAccess.get_file_as_string("res://shaders/style_engraving.gdshader")
	for name in Engraving.UNIFORMS:
		check(shader_text.contains("uniform float " + name + " "), "shader uniform " + name)
		check(Engraving.PARAMS.has(name), "parameter for " + name)
	for name in Engraving.PARAMS:
		check(Engraving.PARAMS[name] is float, "float parameter " + name)
	for token in ["hint_screen_texture", "hint_depth_texture", "hint_normal_roughness_texture", "POSITION = vec4(VERTEX.xy, 1.0, 1.0)"]:
		check(shader_text.contains(token), "shader contains " + token)
	for name in {"cloud_time": "float", "practice_cloud": "float", "cloud_scale": "float", "cloud_tex": "sampler2D", "wind": "vec2"}:
		var kind: String = {"cloud_tex": "sampler2D", "wind": "vec2"}.get(name, "float")
		check(shader_text.contains("uniform " + kind + " " + name + " "), "live cloud parameter " + name)
	check(shader_text.contains("step(r, 1.0) * moon_lines") and not shader_text.contains("step(r, sqrt(transmission))"), "cloud does not resize Moon ink")
	check(shader_text.contains("hatch(elev, k, moon_weight, l_px, 99.0)") and shader_text.contains("step(1.0, moon_weight)"), "Moon darkens through ruling through to solid ink")

	var saved_quality := Settings.quality
	var saved_scale := root.scaling_3d_scale
	var saved_msaa := root.msaa_3d
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	_test_hud_paper(game)
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
	check(material.get_shader_parameter("diamond_radius") == 0.45 and material.get_shader_parameter("diamond_spikes") == 4.0 and material.get_shader_parameter("diamond_ray_floor") == 0.70, "diamond defaults")
	check(material.get_shader_parameter("sun_r") == game.sim.SUN_R, "solar radius")
	check(game.sky_mat.get_shader_parameter("third_contact") == Vector2.ZERO, "diamond starts off")
	check(material.get_shader_parameter("paper") == Engraving.PAPER, "paper colour")
	check(game.player.camera.fov == 60.0, "camera FOV")
	check(game._look_sun == 1.8, "sun gain")
	game._apply_light(1.0, 1.0, 230.0, 0.0)
	check(material.get_shader_parameter("darkness") == 1.0, "totality darkness")
	check(material.get_shader_parameter("night") == 0.0, "totality is daytime")
	game._apply_light(0.62, 0.0, -150.0, 0.0)
	check(material.get_shader_parameter("darkness") == 0.0, "daylight darkness")
	game._apply_light(0.62, 0.0, -150.0, 1.0)
	check(material.get_shader_parameter("night") == 1.0, "night follows lighting")
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
	game.free()

	var overridden := Style.from_args({"style-set": "wash=0.3,line_px=7,diamond_radius=0.4,diamond_spikes=3,diamond_rays=0.5,diamond_ray_floor=0.85"})
	check(is_equal_approx(overridden.params.wash, 0.3), "wash override")
	check(overridden.params.line_px == 7.0, "line spacing override")
	check(overridden.params.diamond_radius == 0.4 and overridden.params.diamond_spikes == 3.0 and overridden.params.diamond_rays == 0.5 and overridden.params.diamond_ray_floor == 0.85, "diamond overrides")
	Settings.quality = saved_quality
	root.scaling_3d_scale = saved_scale
	root.msaa_3d = saved_msaa
	print("test_style_engraving: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)


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
	check(ui.dialogue_portrait.disclosure.autowrap_mode == TextServer.AUTOWRAP_WORD_SMART, "translated portrait caption wraps inside its card")
	for state in [[0.0, 0.0], [1.0, 0.0], [0.0, 1.0]]:
		game._apply_light(0.62, state[0], -150.0, state[1])
		var dark: bool = state[0] > 0 or state[1] > 0
		for label in [ui.clock_label, ui.prompt_label, ui.toast, ui.caption]:
			check(label.has_theme_stylebox_override("normal"), "HUD text has its own slip: " + str(label.get_path()))
			if label.has_theme_stylebox_override("normal"):
				_check_slip(label.get_theme_stylebox("normal"), label.get_theme_color("font_color"), dark)
		check(not ui.crosshair.has_theme_stylebox_override("normal"), "crosshair mark has no slip")
		check(ui.crosshair.get_theme_constant("outline_size") > 0, "crosshair has a contrasting edge")
		if state[1] > 0:
			check(ui.dialog_panel.get_theme_stylebox("panel").bg_color == Engraving.INK, "night slips use warm page ink")
		for panel in [ui.objectives.get_parent(), ui.tot_panel, ui.dialog_panel, ui.dialogue_portrait]:
			var slip: StyleBoxFlat = panel.get_theme_stylebox("panel")
			var text: Color = ui.hint_label.get_theme_color("font_color")
			_check_slip(slip, text, dark)
		check(ui.hint_label.get_theme_color("font_color") == ui.speaker_label.get_theme_color("font_color"), "dialogue hint has the same ink as its speaker")
		check(ui.dialogue_portrait.disclosure.get_theme_color("font_color") == ui.hint_label.get_theme_color("font_color"), "portrait caption has the same ink as dialogue")
		if dark:
			check(ui.dialogue_portrait.image.self_modulate.get_luminance() < 0.5, "portrait paper takes the page wash")
	game._apply_light(0.62, 0, -150, 0)
	ui.set_objectives("[color=#a99]Grey line[/color]")
	check(not ui.objectives.text.contains("[color"), "authored objective colour cannot override page ink")
	ui.set_totality(true, "[color=#fd8]Exposure[/color]")
	ui.set_prompt("Shutter")
	check(not ui.prompt_label.visible and not ui.crosshair.visible, "totality leaves the corona free of central HUD")
	check(not ui.tot_label.text.contains("[color"), "exposure colour cannot override page ink")
	ui.set_totality(false)


func _check_slip(slip: StyleBoxFlat, text: Color, dark: bool) -> void:
	check(slip.bg_color.a == 1.0, "slip is solid")
	check((slip.bg_color.get_luminance() < text.get_luminance()) == dark, "slip follows page polarity")
	var a := text.srgb_to_linear().get_luminance()
	var b := slip.bg_color.srgb_to_linear().get_luminance()
	check((maxf(a, b) + 0.05) / (minf(a, b) + 0.05) >= 4.5, "slip text contrast >= 4.5")
