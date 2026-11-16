extends RefCounted
## Style audition: silver plate (docs/design/SLICE_PRINCIPE.md, 2026-11-16 JST).
## The pass in shaders/style_silver.gdshader makes the silver image; this script
## sets the lens, the halation, the toning and the plate's grain and edge.

const SHADER := preload("res://shaders/style_silver.gdshader")

## Every key is a float and can be overridden with --style-set. Keys listed in
## UNIFORMS are shader uniforms of the same name; the others are read here.
const PARAMS := {
	"resp_r": 0.75, "resp_g": 0.40, "resp_b": -0.15,
	"gain": 1.0, "totality_gain": 2.5, "night_gain": 1.0, "black": 0.0,
	"soft": 0.22, "soft_lod": 3.0, "focus_far": 22.0, "far_soft": 0.35, "tint": 0.0,
	"exposure": 1.0, "white": 4.0, "contrast": 1.08, "tone": 1.0,
	"glow": 0.9, "glow_threshold": 0.85, "glow_bloom": 0.06,
	"dof_far": 30.0, "dof_amount": 0.06,
	"sun_floor": 0.45, "sun_gain": 1.8, "ambient": 0.5, "sun_angle": 1.2,
	"ssao": 1.0, "volumetric_fog": 1.0, "fog_density": 0.008,
	"vignette": 0.5, "grain": 0.09, "dust": 0.6, "edge": 0.7, "fov": 60.0,
}
const UNIFORMS := [
	"resp_r", "resp_g", "resp_b", "gain", "totality_gain", "night_gain", "black",
	"soft", "soft_lod", "focus_far", "far_soft", "tint",
]
const DIALOGUE := {
	"portrait": "res://assets/portraits/eddington_neutral.jpg",
	"panel": Color(0.085, 0.07, 0.058, 0.94), "border": Color(0.56, 0.50, 0.41),
	"speaker": Color(0.86, 0.80, 0.68), "text": Color(0.93, 0.90, 0.82),
}
## The print's tone per channel: input value → output value. Black never prints
## pure black, the paper is cream. `tone` blends from a neutral curve to this.
const TONE_OFFSETS := [0.0, 0.12, 0.5, 0.88, 1.0]
const TONE_NEUTRAL := [Color(0.04, 0.04, 0.04), Color(0.14, 0.14, 0.14), Color(0.50, 0.50, 0.50), Color(0.88, 0.88, 0.88), Color(0.95, 0.95, 0.95)]
const TONE_WARM := [Color(0.045, 0.035, 0.030), Color(0.150, 0.120, 0.100), Color(0.520, 0.470, 0.410), Color(0.900, 0.865, 0.790), Color(0.965, 0.940, 0.880)]


static func tone_lut(tone: float) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(TONE_OFFSETS)
	var colors := PackedColorArray()
	for i in TONE_NEUTRAL.size():
		colors.append(TONE_NEUTRAL[i].lerp(TONE_WARM[i], tone))
	g.colors = colors
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	return tex


func apply(main: Node, style: RefCounted) -> void:
	var p: Dictionary = style.params
	var env: Environment = main.env
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = p.exposure
	env.tonemap_white = p.white
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.0
	env.adjustment_contrast = p.contrast
	env.adjustment_color_correction = tone_lut(p.tone)
	# Halation: light bleeding sideways in the emulsion round every highlight.
	env.glow_enabled = p.glow > 0.0
	env.glow_intensity = p.glow
	env.glow_bloom = p.glow_bloom
	env.glow_hdr_threshold = p.glow_threshold
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SCREEN
	for i in 7:
		env.set_glow_level(i, 1.0 if i >= 2 and i <= 5 else 0.0)
	env.sdfgi_enabled = false
	env.ssao_enabled = p.ssao > 0.5
	env.volumetric_fog_enabled = p.volumetric_fog > 0.5
	env.fog_density = p.fog_density
	# Settings.apply_quality() restores these three from the node's metas.
	for we in main.get_tree().get_nodes_in_group("quality_env"):
		we.set_meta("standard_ssao", env.ssao_enabled)
		we.set_meta("standard_sdfgi", false)
		we.set_meta("standard_volumetric_fog", env.volumetric_fog_enabled)
	main.sun.light_angular_distance = p.sun_angle
	if not main._look.is_empty():
		main._look["sun_floor"] = p.sun_floor
	main._look_sun = p.sun_gain
	main._look_ambient = p.ambient
	main.player.camera.fov = p.fov
	# A large-format lens: the distance goes soft.
	var lens := CameraAttributesPractical.new()
	lens.dof_blur_far_enabled = p.dof_amount > 0.0
	lens.dof_blur_far_distance = p.dof_far
	lens.dof_blur_far_transition = p.dof_far
	lens.dof_blur_amount = p.dof_amount
	main.player.camera.attributes = lens
	style.add_quad(main, SHADER)
	style.set_post(main, p.vignette, p.grain)
	# Match set_post(): children may not yet be registered in the tree's groups.
	for post in main.find_children("*", "CanvasLayer", true, false):
		if post.is_in_group("look_post"):
			post.material.set_shader_parameter("dust", p.dust)
			post.material.set_shader_parameter("edge", p.edge)


func light(_main: Node, style: RefCounted, _contact: float, darkness: float, night: float) -> void:
	if style.quad_material == null:
		return
	style.quad_material.set_shader_parameter("darkness", darkness)
	style.quad_material.set_shader_parameter("night", night)
