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

	var saved_quality := Settings.quality
	var saved_scale := root.scaling_3d_scale
	var saved_msaa := root.msaa_3d
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
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
	check(material.get_shader_parameter("sun_r") == game.sim.SUN_R, "solar radius")
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
	Settings.quality = "standard"
	Settings.apply_quality(self)
	check(not game.env.sdfgi_enabled, "standard quality preserves SDFGI off")
	check(not game.env.volumetric_fog_enabled, "standard quality preserves volumetric fog off")
	game.free()

	var overridden := Style.from_args({"style-set": "wash=0.3,line_px=7"})
	check(is_equal_approx(overridden.params.wash, 0.3), "wash override")
	check(overridden.params.line_px == 7.0, "line spacing override")
	Settings.quality = saved_quality
	root.scaling_3d_scale = saved_scale
	root.msaa_3d = saved_msaa
	print("test_style_engraving: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
