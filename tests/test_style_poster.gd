extends SceneTree

const Style := preload("res://scripts/style.gd")
const Poster := preload("res://scripts/styles/poster.gd")
const Settings := preload("res://scripts/settings.gd")
const MATERIAL_PROPERTIES := [
	"diffuse_mode", "specular_mode", "detail_enabled", "normal_enabled",
	"metallic", "metallic_specular", "roughness", "albedo_color", "albedo_texture",
	"roughness_texture", "metallic_texture", "shading_mode", "emission_enabled", "transparency",
]
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _snapshot(m: BaseMaterial3D) -> Array:
	var values := []
	for property in MATERIAL_PROPERTIES:
		values.append(m.get(property))
	return values


func _patches(m: Material) -> bool:
	if not m is StandardMaterial3D or not m.albedo_texture is NoiseTexture2D:
		return false
	var ramp: Gradient = m.albedo_texture.color_ramp
	return ramp != null and ramp.interpolation_mode == Gradient.GRADIENT_INTERPOLATE_CONSTANT and ramp.get_point_count() == 3


func _material_checks() -> void:
	var m := StandardMaterial3D.new()
	m.detail_enabled = true
	m.normal_enabled = true
	m.metallic = 0.8
	m.roughness = 0.9
	var texture := GradientTexture1D.new()
	m.roughness_texture = texture
	m.metallic_texture = texture
	Poster.flatten_material(m, Poster.PARAMS)
	check(m.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON, "plain material toon diffuse")
	check(m.specular_mode == BaseMaterial3D.SPECULAR_DISABLED, "plain material specular disabled")
	check(not m.detail_enabled and not m.normal_enabled, "detail and normal disabled")
	check(m.roughness_texture == null and m.metallic_texture == null, "roughness and metallic textures cleared")
	check(is_zero_approx(m.metallic) and is_zero_approx(m.metallic_specular), "metallic and specular zero")
	check(is_equal_approx(m.roughness, 0.08), "toon terminator width")
	var noisy := StandardMaterial3D.new()
	var noise := NoiseTexture2D.new()
	noise.noise = FastNoiseLite.new()
	noise.color_ramp = Gradient.new() # default black to white
	noisy.albedo_texture = noise
	Poster.flatten_material(noisy, Poster.PARAMS)
	check(noisy.albedo_texture == null, "noise albedo removed")
	check(noisy.albedo_color.is_equal_approx(Color(0.5, 0.5, 0.5)), "noise ramp becomes mid-grey")
	for skip in ["evidence", "unshaded", "emission", "alpha", "glass"]:
		var keep := StandardMaterial3D.new()
		keep.detail_enabled = true
		keep.normal_enabled = true
		keep.metallic = 0.8
		keep.roughness = 0.9
		keep.albedo_texture = texture
		keep.roughness_texture = texture
		keep.metallic_texture = texture
		match skip:
			"evidence": keep.set_meta("evidence", true)
			"unshaded": keep.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			"emission": keep.emission_enabled = true
			"alpha": keep.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			"glass": keep.resource_name = "E1919_plate_glass_test"
		var before := _snapshot(keep)
		Poster.flatten_material(keep, Poster.PARAMS)
		check(_snapshot(keep) == before, skip + " material unchanged")
	var foliage := ShaderMaterial.new()
	foliage.shader = Poster.FoliageCard
	Poster.flatten_material(foliage, Poster.PARAMS)
	check(is_equal_approx(foliage.get_shader_parameter("flatten"), 0.85), "foliage flatten")
	var ground := Poster.ground_material(Poster.PARAMS)
	check(_patches(ground), "ground constant-ramp noise with three colours")
	check(ground.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON, "ground toon diffuse")


func _run() -> void:
	var saved_quality := Settings.quality
	var shader_text := FileAccess.get_file_as_string("res://shaders/style_poster.gdshader")
	for key in Poster.UNIFORMS:
		check(shader_text.contains("uniform float " + key + " "), "float uniform " + key)
		check(Poster.PARAMS.has(key), "uniform has parameter " + key)
	for key in Poster.INKS:
		check(shader_text.contains("uniform vec3 " + key + " "), "ink uniform " + key)
	for token in ["hint_screen_texture", "hint_depth_texture", "uniform vec2 star_pos[12]", "POSITION = vec4(VERTEX.xy, 1.0, 1.0)"]:
		check(shader_text.contains(token), "shader contains " + token)
	var foliage_text := FileAccess.get_file_as_string("res://shaders/foliage_card.gdshader")
	check(foliage_text.contains("uniform float flatten = 0.0"), "foliage defaults to unchanged")
	for key in Poster.PARAMS:
		check(Poster.PARAMS[key] is float, "float parameter " + key)
	_material_checks()
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	check(game._style == null and get_nodes_in_group(Style.QUAD_GROUP).is_empty(), "default scene has no style pass")
	var protected_materials := {}
	var style = Style.from_args({"style": "poster"})
	style.each_material(game, func(m: Material, _node: Node):
		if m is BaseMaterial3D and (m.has_meta("evidence") or m.resource_name.begins_with("E1919_plate_glass") or m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or m.emission_enabled or m.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED):
			protected_materials[m] = _snapshot(m)
	)
	game._style = style
	style.apply(game)
	check(game.env.tonemap_mode == Environment.TONE_MAPPER_LINEAR and game.env.tonemap_exposure == 1.0, "linear tonemap and unit exposure")
	for property in ["adjustment_enabled", "glow_enabled", "fog_enabled", "ssao_enabled", "sdfgi_enabled", "volumetric_fog_enabled"]:
		check(not game.env.get(property), property + " disabled")
	check(game.env.ambient_light_source == Environment.AMBIENT_SOURCE_COLOR, "colour ambient source")
	check(game.env.reflected_light_source == Environment.REFLECTION_SOURCE_DISABLED, "reflected light disabled")
	check(game.sun.light_color.is_equal_approx(Poster.KEY_COLOR), "warm key colour")
	check(is_equal_approx(game.sun.light_angular_distance, 0.0) and is_equal_approx(game.sun.shadow_blur, 0.5), "hard cast shadows")
	var quads := get_nodes_in_group(Style.QUAD_GROUP)
	check(quads.size() == 1, "one style quad")
	check(quads[0].material_override.shader == Poster.SHADER, "quad uses poster shader")
	var q: ShaderMaterial = style.quad_material
	for key in Poster.PARAMS:
		check(is_equal_approx(q.get_shader_parameter(key), Poster.PARAMS[key]), "quad parameter " + key)
	for key in Poster.INKS:
		check(q.get_shader_parameter(key) == Poster.INKS[key], "quad ink " + key)
	check(q.get_shader_parameter("sun_r") == game.sim.SUN_R, "simulation Sun radius")
	check(q.get_shader_parameter("cloud_tex") == game.sky_mat.get_shader_parameter("cloud_tex"), "simulation cloud texture")
	check(game.sim.star_offsets is PackedVector2Array and game.sim.star_offsets.size() == 12, "twelve simulated field stars")
	check(q.get_shader_parameter("star_pos") == game.sim.star_offsets, "simulation field star positions")
	var grounds := get_nodes_in_group("ground")
	check(grounds.size() == 1 and _patches(grounds[0].material_override), "real ground has constant-ramp noise")
	check(grounds[0].material_override.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON, "real ground toon")
	var toon_meshes := []
	var evidence_materials := []
	var foliage_materials := []
	style.each_material(game, func(m: Material, node: Node):
		if m is BaseMaterial3D:
			if m.has_meta("evidence"):
				evidence_materials.append(m)
				check(m.diffuse_mode != BaseMaterial3D.DIFFUSE_TOON, "real evidence not toon")
			elif not protected_materials.has(m):
				check(m.diffuse_mode == BaseMaterial3D.DIFFUSE_TOON and not m.detail_enabled, "real lit opaque surface flattened")
				if node is MeshInstance3D and m is StandardMaterial3D:
					toon_meshes.append(node)
		elif m is ShaderMaterial and m.shader == Poster.FoliageCard:
			foliage_materials.append(m)
			check(is_equal_approx(m.get_shader_parameter("flatten"), 0.85), "real foliage flattened")
	)
	check(not toon_meshes.is_empty(), "world builder has active toon StandardMaterial3D meshes")
	check(not evidence_materials.is_empty(), "real evidence checked")
	check(not foliage_materials.is_empty(), "real foliage checked")
	for material in protected_materials:
		check(_snapshot(material) == protected_materials[material], "real protected material unchanged: " + material.resource_name)
	check(is_equal_approx(game.player.camera.fov, 60.0), "camera FOV 60")
	game._apply_light(0.62, 0.0, -150.0, 0.0)
	check(is_equal_approx(game.sun.light_energy, 1.1), "day key constant")
	check(game.env.ambient_light_color.is_equal_approx(Poster.SHADOW_DAY), "day shadow colour")
	check(is_equal_approx(game.env.ambient_light_energy, 0.6), "day ambient energy")
	for pair in [["cloud_time", -150.0], ["darkness", 0.0], ["contact", 0.62], ["night", 0.0], ["star_vis", 0.0]]:
		check(is_equal_approx(q.get_shader_parameter(pair[0]), pair[1]), "day quad " + pair[0])
	game._apply_light(1.0, 1.0, 215.0, 0.0)
	check(is_zero_approx(game.sun.light_energy), "totality key off")
	check(game.env.ambient_light_color.is_equal_approx(Poster.SHADOW_TOTALITY), "totality shadow colour")
	check(is_equal_approx(game.env.ambient_light_energy, 0.9), "totality ambient energy")
	for pair in [["cloud_time", 215.0], ["darkness", 1.0], ["contact", 1.0], ["night", 0.0], ["star_vis", 1.0]]:
		check(is_equal_approx(q.get_shader_parameter(pair[0]), pair[1]), "totality quad " + pair[0])
	game._apply_light(0.0, 0.0, 400.0, 1.0)
	check(is_zero_approx(game.sun.light_energy), "night key off")
	check(game.env.ambient_light_color.is_equal_approx(Poster.SHADOW_NIGHT), "night shadow colour")
	for pair in [["cloud_time", 400.0], ["darkness", 0.0], ["contact", 0.0], ["night", 1.0], ["star_vis", 0.0]]:
		check(is_equal_approx(q.get_shader_parameter(pair[0]), pair[1]), "night quad " + pair[0])
	Settings.quality = "standard"
	Settings.apply_quality(self)
	check(not game.env.ssao_enabled and not game.env.sdfgi_enabled and not game.env.volumetric_fog_enabled, "standard quality keeps effects disabled")
	game.free()
	var second = load("res://scenes/main.tscn").instantiate()
	root.add_child(second)
	await process_frame
	var ground = get_nodes_in_group("ground")[0]
	var original_ground: Material = ground.material_override
	second._style = Style.from_args({"style": "poster", "style-set": "key=1.4,ground_patches=0,haze_k=0.02"})
	second._style.apply(second)
	second._apply_light(0.62, 0.0, -150.0, 0.0)
	check(is_equal_approx(second.sun.light_energy, 1.4), "key override")
	check(is_equal_approx(second._style.quad_material.get_shader_parameter("haze_k"), 0.02), "haze override")
	check(ground.material_override == original_ground and not _patches(ground.material_override), "ground patches disabled keeps original material")
	second.free()
	Settings.quality = saved_quality
	Settings.apply_quality(self)
	print("test_style_poster: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
