extends SceneTree

const Style := preload("res://scripts/style.gd")
const Silver := preload("res://scripts/styles/silver.gd")
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
	var shader := FileAccess.get_file_as_string("res://shaders/style_silver.gdshader")
	for key in Silver.UNIFORMS:
		check(shader.contains("uniform float %s " % key), key + " uniform declaration")
		check(Silver.PARAMS.has(key), key + " parameter")
	for key in Silver.PARAMS:
		check(Silver.PARAMS[key] is float, key + " is float")
	for token in ["hint_screen_texture", "filter_linear_mipmap", "hint_depth_texture", "POSITION = vec4(VERTEX.xy, 1.0, 1.0)"]:
		check(shader.contains(token), token)
	var post_shader := FileAccess.get_file_as_string("res://shaders/look_post.gdshader")
	for key in ["dust", "edge"]:
		check(post_shader.contains("uniform float %s = 0.0" % key), key + " defaults off")
	var warm := Silver.tone_lut(1.0)
	check(warm.width == 256, "LUT width")
	check(warm.gradient.get_color(0).is_equal_approx(Color(0.045, 0.035, 0.030)), "warm black")
	check(warm.gradient.get_color(warm.gradient.get_point_count() - 1).is_equal_approx(Color(0.965, 0.940, 0.880)), "warm paper")
	for color in Silver.tone_lut(0.0).gradient.colors:
		check(color.r == color.g and color.g == color.b, "neutral channel equality")
	var saved_quality := Settings.quality
	Settings.quality = "standard"
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game._style == null and get_nodes_in_group(Style.QUAD_GROUP).is_empty(), "default has no style quad")
	game._style = Style.from_args({"style": "silver"})
	game._style.apply(game)
	check(game.env.tonemap_mode == Environment.TONE_MAPPER_FILMIC, "filmic")
	check(game.env.adjustment_enabled, "adjustments enabled")
	check(game.env.adjustment_color_correction is GradientTexture1D, "toning curve installed")
	check(game.env.adjustment_color_correction.gradient.colors == warm.gradient.colors, "warm toning curve")
	check(game.env.glow_enabled, "glow enabled")
	check(is_equal_approx(game.env.glow_hdr_threshold, 0.85), "glow threshold")
	check(not game.env.sdfgi_enabled, "SDFGI disabled")
	var quads := get_nodes_in_group(Style.QUAD_GROUP)
	check(quads.size() == 1, "one style quad")
	var material: ShaderMaterial = game._style.quad_material
	if quads.size() == 1:
		check(quads[0].material_override == material and material.shader == Silver.SHADER, "silver shader material")
	for key in Silver.PARAMS:
		check(is_equal_approx(material.get_shader_parameter(key), Silver.PARAMS[key]), key + " reaches material")
	check(is_equal_approx(material.get_shader_parameter("resp_b"), -0.15), "negative blue response")
	var posts := get_nodes_in_group("look_post")
	check(posts.size() == 1, "one post layer")
	if posts.size() == 1:
		for key in ["vignette", "grain", "dust", "edge"]:
			check(is_equal_approx(posts[0].material.get_shader_parameter(key), Silver.PARAMS[key]), key + " post value")
	var lens = game.player.camera.attributes
	check(lens is CameraAttributesPractical, "practical lens")
	if lens is CameraAttributesPractical:
		check(lens.dof_blur_far_enabled and lens.dof_blur_far_distance == 30.0, "far blur at 30 m")
	check(game.player.camera.fov == 60.0, "60 degree FOV")
	check(is_equal_approx(game._look_sun, 1.8), "sun gain")
	game._apply_light(1.0, 1.0, 215.0, 0.0)
	check(is_equal_approx(material.get_shader_parameter("darkness"), 1.0), "totality darkness")
	game._apply_light(0.62, 0.0, -150.0, 0.0)
	check(is_equal_approx(material.get_shader_parameter("darkness"), 0.0), "daylight darkness")
	game._apply_light(0.0, 0.0, 400.0, 1.0)
	check(is_equal_approx(material.get_shader_parameter("night"), 1.0), "night uniform")
	game._apply_light(0.62, 0.0, -150.0, 0.0)
	check(is_equal_approx(material.get_shader_parameter("night"), 0.0), "daylight night uniform")
	Settings.apply_quality(self)
	check(not game.env.sdfgi_enabled, "quality preserves SDFGI off")
	check(game.env.volumetric_fog_enabled, "quality preserves volumetric fog")
	game.free()
	var second = load("res://scenes/main.tscn").instantiate()
	root.add_child(second)
	await process_frame
	second._style = Style.from_args({"style": "silver", "style-set": "tint=0.3,glow=0"})
	second._style.apply(second)
	check(is_equal_approx(second._style.quad_material.get_shader_parameter("tint"), 0.3), "tint override")
	check(not second.env.glow_enabled, "glow override")
	second.free()
	Settings.quality = saved_quality
	Settings.apply_quality(self)
	print("test_style_silver: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
