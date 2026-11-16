extends RefCounted
## Style audition: poster (docs/design/SLICE_PRINCIPE.md, 2026-11-16).
## Flat colour and light: toon diffuse on every lit surface, a warm key with
## hard cast shadows, a violet ambient as the one shadow tone, no texture noise.
## The pass in shaders/style_poster.gdshader adds the haze and redraws the sky.

const SHADER := preload("res://shaders/style_poster.gdshader")
const FoliageCard := preload("res://shaders/foliage_card.gdshader")
const Palette := preload("res://scripts/palette.gd")

## Every key is a float and can be overridden with --style-set. Keys listed in
## UNIFORMS are shader uniforms of the same name; the others are read here.
const PARAMS := {
	"gain": 0.78, "sat": 1.15, "sky_bands": 5.0, "cloud_lo": 0.50, "cloud_hi": 0.74, "veil": 0.55,
	"haze_k": 0.012, "haze_max": 0.88, "haze_turn": 0.45,
	"corona_fall": 3.2, "corona_base": 0.35, "streamer": 1.3, "streamer_reach": 0.25,
	"corona_1": 0.30, "corona_2": 0.11, "corona_3": 0.035, "star_px": 2.2,
	"key": 1.1, "ambient": 0.6, "ambient_totality": 0.9, "terminator": 0.08,
	"shadow_blur": 0.5, "sun_angle": 0.0, "flatten": 0.85, "ground_patches": 1.0,
	"vignette": 0.0, "grain": 0.04, "fov": 60.0,
}
const UNIFORMS := [
	"gain", "sat", "sky_bands", "cloud_lo", "cloud_hi", "veil", "haze_k", "haze_max", "haze_turn",
	"corona_fall", "corona_base", "streamer", "streamer_reach", "corona_1", "corona_2", "corona_3", "star_px",
]
## The inks, as display colours (the uniforms are source_color).
const INKS := {
	"sky_top": Color(0.30, 0.56, 0.62), "sky_low": Color(0.96, 0.87, 0.68),
	"cloud_a": Color(0.98, 0.94, 0.84), "cloud_b": Color(0.78, 0.72, 0.74),
	"sun_ink": Color(1.0, 0.96, 0.80),
	"tot_top": Color(0.055, 0.075, 0.20), "tot_mid": Color(0.16, 0.17, 0.38), "tot_low": Color(0.86, 0.47, 0.30),
	"tot_cloud_a": Color(0.13, 0.14, 0.30), "tot_cloud_b": Color(0.08, 0.09, 0.21),
	"corona_a": Color(1.0, 0.97, 0.88), "corona_b": Color(0.78, 0.82, 0.93), "corona_c": Color(0.36, 0.40, 0.68),
	"moon_ink": Color(0.03, 0.035, 0.09), "prom_ink": Color(0.89, 0.33, 0.25),
	"haze_near": Color(0.98, 0.80, 0.60), "haze_far": Color(0.62, 0.72, 0.82), "tot_haze": Color(0.10, 0.11, 0.26),
}
const KEY_COLOR := Color(1.0, 0.86, 0.62)
const SHADOW_DAY := Color(0.42, 0.44, 0.72)        # the ambient is the shadow tone
const SHADOW_TOTALITY := Color(0.10, 0.11, 0.26)
const SHADOW_NIGHT := Color(0.03, 0.035, 0.06)
const DIALOGUE := {
	"portrait": "res://assets/portraits/eddington_poster.jpg",
	"panel": Color(0.09, 0.11, 0.24, 0.96), "border": Color(0.80, 0.42, 0.28),
	"speaker": Color(0.95, 0.62, 0.42), "text": Color(0.97, 0.93, 0.82),
	"mount": Color(0.09, 0.11, 0.24), "mount_border": Color(0.97, 0.93, 0.82),
}


func apply(main: Node, style: RefCounted) -> void:
	var p: Dictionary = style.params
	var env: Environment = main.env
	# The pass writes final colours: nothing may grade, bloom or fog them afterwards.
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.adjustment_enabled = false
	env.glow_enabled = false
	env.fog_enabled = false
	env.sdfgi_enabled = false
	env.ssao_enabled = false
	env.volumetric_fog_enabled = false
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	# Settings.apply_quality() restores these three from the node's metas.
	for we in main.get_tree().get_nodes_in_group("quality_env"):
		we.set_meta("standard_ssao", false)
		we.set_meta("standard_sdfgi", false)
		we.set_meta("standard_volumetric_fog", false)
	main.sun.light_color = KEY_COLOR
	main.sun.light_angular_distance = p.sun_angle
	main.sun.shadow_blur = p.shadow_blur
	main.player.camera.fov = p.fov
	style.each_material(main, func(m: Material, _node: Node): flatten_material(m, p))
	if p.ground_patches > 0.5:
		for ground in main.get_tree().get_nodes_in_group("ground"):
			if ground is MeshInstance3D:
				ground.material_override = ground_material(p)
	var uniforms := INKS.duplicate()
	uniforms["sun_dir"] = main.sim.sun_dir
	uniforms["sun_r"] = main.sim.SUN_R
	uniforms["wind"] = main.sim.wind
	uniforms["cloud_scale"] = main.sim.CLOUD_SCALE
	uniforms["cloud_tex"] = main.sky_mat.get_shader_parameter("cloud_tex")
	uniforms["star_pos"] = main.sim.star_offsets
	style.add_quad(main, SHADER, uniforms)
	style.set_post(main, p.vignette, p.grain)


## One flat colour and one hard shadow tone per surface. Evidence, glass, lamps
## and anything unshaded keep their materials.
static func flatten_material(m: Material, p: Dictionary) -> void:
	if m is ShaderMaterial:
		if m.shader == FoliageCard:
			m.set_shader_parameter("flatten", p.flatten)
		return
	var b := m as BaseMaterial3D
	if b == null or b.has_meta("evidence") or b.resource_name.begins_with("E1919_plate_glass"):
		return
	if b.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED or b.emission_enabled or b.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED:
		return
	b.detail_enabled = false
	b.normal_enabled = false
	b.roughness_texture = null
	b.metallic_texture = null
	if b.albedo_texture is NoiseTexture2D:
		# A noise ramp becomes its middle colour.
		var ramp: Gradient = (b.albedo_texture as NoiseTexture2D).color_ramp
		if ramp != null:
			b.albedo_color = b.albedo_color * ramp.sample(0.5)
		b.albedo_texture = null
	b.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	b.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	b.metallic = 0.0
	b.metallic_specular = 0.0
	b.roughness = p.terminator   # with toon diffuse this is the width of the terminator


## The clearing as cut paper: three flat greens with organic edges.
static func ground_material(p: Dictionary) -> StandardMaterial3D:
	var tex := NoiseTexture2D.new()
	tex.width = 1024
	tex.height = 1024
	tex.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = 0.006
	n.fractal_octaves = 3
	tex.noise = n
	var g := Gradient.new()
	g.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	g.offsets = PackedFloat32Array([0.0, 0.44, 0.62])
	g.colors = PackedColorArray([
		Palette.C["foliage_deep"].darkened(0.10),
		Palette.C["foliage_deep"].lerp(Palette.C["foliage_light"], 0.45),
		Palette.C["foliage_light"],
	])
	tex.color_ramp = g
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.035, 0.035, 0.035)
	m.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON
	m.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	m.metallic_specular = 0.0
	m.roughness = p.terminator
	return m


func light(main: Node, style: RefCounted, contact: float, darkness: float, night: float) -> void:
	var p: Dictionary = style.params
	# A poster has one key: constant by day whatever the cloud, gone by totality.
	main.sun.light_energy = 0.0 if night > 0.5 else p.key * (1.0 - smoothstep(0.5, 0.95, darkness))
	main.env.ambient_light_color = SHADOW_DAY.lerp(SHADOW_TOTALITY, darkness).lerp(SHADOW_NIGHT, night)
	main.env.ambient_light_energy = lerpf(p.ambient, p.ambient_totality, darkness)
	if style.quad_material == null:
		return
	var q: ShaderMaterial = style.quad_material
	q.set_shader_parameter("contact", contact)
	q.set_shader_parameter("darkness", darkness)
	q.set_shader_parameter("night", night)
	q.set_shader_parameter("cloud_time", main.sky_mat.get_shader_parameter("cloud_time"))
	q.set_shader_parameter("star_vis", main.sky_mat.get_shader_parameter("star_vis"))
