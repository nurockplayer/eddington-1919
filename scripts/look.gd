extends RefCounted
## Era look (art/BIBLE.md §5): the 1919 "plate grade". The Painted Diorama
## forms carry the series identity; this grade carries the era. It nudges the
## image toward a toned glass-plate print by slightly desaturating and warming
## the shadows and midtones (sepia). The LUT is identity at and above 0.85 so the
## near-neutral evidence whites (Sun, corona, plates) stay clean. Kept subtle on
## purpose: totality must stay readable.
##
## Disable for A/B comparisons with the user arg --no-grade.

const SATURATION := 0.86
const CONTRAST := 1.10       # r05: 1.04 → 1.10 (try1 read milky)

# r05 cinematic layer (Owner 2026-10-20: historical weight, cinematic light, not
# toy-like). Targets: art/runs/r05-cinematic/ paint-overs of real in-game frames.
const AMBIENT_GAIN := 0.72     # less flat fill → shadows read, forms ground themselves
const SUN_GAIN := 1.25         # stronger key through the cloud breaks
const CLOUD_SHADE := 0.34      # heavier, brooding cloud undersides (v0.1: 0.22; 0.40 read as camouflage)
const DAY_SKY_GAIN := 0.86     # stop the overcast sky clipping to white

static func apply_grade(env: Environment) -> void:
	env.adjustment_enabled = true
	env.adjustment_saturation = SATURATION
	env.adjustment_contrast = CONTRAST
	# Per-channel 1D LUT (input value → output value for R, G, B independently).
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.5, 0.85, 1.0])
	g.colors = PackedColorArray([
		Color(0.015, 0.008, 0.0),
		Color(0.200, 0.176, 0.150),   # sepia-warm shadows
		Color(0.510, 0.497, 0.474),   # warm midtones
		Color(0.850, 0.850, 0.850),   # identity from here up: evidence whites untouched
		Color(1.0, 1.0, 1.0),
	])
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	env.adjustment_color_correction = tex


## Cinematic lighting: tonemapping, contact occlusion, aerial depth, soft key.
## Totality and the evidence read are protected: fog never touches the sky
## (fog_sky_affect stays 0) and the sky gains fade out with `darkness`.
static func apply_cinematic(env: Environment, sun: DirectionalLight3D, sky_mat: ShaderMaterial) -> void:
	# try1 used AgX: it read milky and flat against the paint-over target; ACES
	# keeps the deep shadows (art/runs/r05-cinematic/REVIEW.md).
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.95
	# Contact occlusion: objects sit on the ground instead of floating (paint-over r05).
	env.ssao_enabled = true
	env.ssao_radius = 1.1
	env.ssao_intensity = 2.2
	env.ssao_power = 1.6
	env.ssao_detail = 0.6
	env.ssao_light_affect = 0.15
	# Aerial perspective: hills recede into humid haze; low mist after the storm.
	env.fog_density = 0.0042
	env.fog_aerial_perspective = 0.6
	env.fog_sun_scatter = 0.1
	env.fog_height = 0.3
	env.fog_height_density = 0.02
	env.fog_sky_affect = 0.0
	sun.light_angular_distance = 1.2   # soft, overcast-filtered shadow edges
	# Warmer key (the paint-overs' warmth) while keeping the historical high sun at
	# ~14:00; the low golden sun in r05 paint-overs is wrong for the hour.
	sun.light_color = Color(1.0, 0.91, 0.78)
	sun.directional_shadow_max_distance = 60.0
	sun.shadow_blur = 1.4
	sky_mat.set_shader_parameter("cloud_shade", CLOUD_SHADE)
	sky_mat.set_shader_parameter("day_gain", DAY_SKY_GAIN)
