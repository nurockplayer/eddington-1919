extends RefCounted
## Cambridge/departure look (art/BIBLE.md §5): the 1919 "plate grade".
## Príncipe uses PRINCIPE (docs/design/SLICE_PRINCIPE.md). The Painted Diorama
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
const NIGHT_SAFELIGHT := 0.5   # darkroom red safelight at night (v0.1: 0.25; r05 darker room needs it to read)
const NIGHT_LINEN_DIM := 0.55   # linen albedo at night: under the red safelight linen and skin have the same red, so the suit read as bare skin

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


## Príncipe slice look (docs/design/SLICE_PRINCIPE.md, plan step 1). One parameter
## set; a windowed comparison run overrides single values with the user arg
## --look-set=key=value,key=value (tools/look_matrix.sh). No sepia in play.
const PRINCIPE := {
	"tonemap": "aces",          # Tone mapper: aces | agx | filmic
	"exposure": 1.1,            # Tonemap exposure multiplier
	"white": 5.0,               # ACES/filmic white point
	"agx_contrast": 1.4,        # AgX contrast multiplier
	"saturation": 1.30,         # Colour saturation multiplier
	"contrast": 1.06,           # Grade contrast multiplier
	"split_tone": 1.0,          # LUT blend: 0 neutral, 1 cool shadows/warm midtones
	"sun_floor": 0.3,           # Minimum daytime key energy through cloud
	"sun_gain": 1.8,            # Sun energy multiplier
	"ambient_gain": 0.5,        # Ambient energy multiplier
	"sky_gain": 0.72,           # Daytime sky brightness multiplier
	"cloud_shade": 0.34,        # Cloud underside shading strength
	"ssao": 1,                  # Contact occlusion: 0 off, 1 on
	"sdfgi": 0,                 # SDFGI: 0 off, 1 on; preserves shaded faces/hats
	"sdfgi_energy": 1.0,        # SDFGI bounce energy multiplier when enabled
	"fog_density": 0.0042,      # Depth fog density
	"fog_aerial": 0.8,          # Aerial perspective sky blend: 0..1
	"volumetric_fog": 1,        # Volumetric fog: 0 off, 1 on
	"volumetric_density": 0.012, # Volumetric fog density
	"vignette": 0.22,           # Corner darkening strength: 0 off
	"grain": 0.03,              # Film grain darkening strength: 0 off
	"fov": 60.0,                # Príncipe player camera vertical degrees
}


static func override_errors(overrides: String) -> PackedStringArray:
	var errors := PackedStringArray()
	if overrides.is_empty():
		return errors
	for pair in overrides.split(","):
		var parts := pair.split("=")
		if parts.size() != 2 or not PRINCIPE.has(parts[0]):
			errors.append(pair)
			continue
		var value: String = parts[1]
		if (parts[0] == "tonemap" and value not in ["aces", "agx", "filmic"]) or (parts[0] != "tonemap" and not value.is_valid_float()):
			errors.append(pair)
	return errors


static func principe(overrides := "") -> Dictionary:
	var result := PRINCIPE.duplicate()
	var errors := override_errors(overrides)
	if overrides.is_empty():
		return result
	for pair in overrides.split(","):
		if pair in errors:
			continue
		var parts := pair.split("=")
		var key: String = parts[0]
		if result[key] is int:
			result[key] = parts[1].to_int()
		elif result[key] is float:
			result[key] = parts[1].to_float()
		else:
			result[key] = parts[1]
	return result


static func principe_lut(split_tone: float) -> GradientTexture1D:
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.18, 0.5, 0.85, 1.0])
	var neutral := [Color(0, 0, 0), Color(0.18, 0.18, 0.18), Color(0.5, 0.5, 0.5), Color(0.85, 0.85, 0.85), Color(1, 1, 1)]
	var toned := [Color(0.012, 0.016, 0.024), Color(0.172, 0.182, 0.196), Color(0.508, 0.500, 0.488), Color(0.85, 0.85, 0.85), Color(1, 1, 1)]
	var colors := PackedColorArray()
	for i in neutral.size():
		colors.append(neutral[i].lerp(toned[i], split_tone))
	g.colors = colors
	var tex := GradientTexture1D.new()
	tex.gradient = g
	tex.width = 256
	return tex


static func apply_principe(env: Environment, sun: DirectionalLight3D, sky_mat: ShaderMaterial, p: Dictionary) -> void:
	env.tonemap_mode = {"aces": Environment.TONE_MAPPER_ACES, "agx": Environment.TONE_MAPPER_AGX, "filmic": Environment.TONE_MAPPER_FILMIC}[p.tonemap]
	env.tonemap_exposure = p.exposure
	env.tonemap_white = p.white
	env.tonemap_agx_contrast = p.agx_contrast
	env.adjustment_enabled = true
	env.adjustment_saturation = p.saturation
	env.adjustment_contrast = p.contrast
	env.adjustment_color_correction = principe_lut(p.split_tone)
	env.ssao_enabled = p.ssao != 0
	env.ssao_radius = 1.1
	env.ssao_intensity = 2.2
	env.ssao_power = 1.6
	env.ssao_detail = 0.6
	env.ssao_light_affect = 0.15
	env.sdfgi_enabled = p.sdfgi != 0
	env.sdfgi_use_occlusion = true
	env.sdfgi_read_sky_light = true
	env.sdfgi_energy = p.sdfgi_energy
	env.fog_density = p.fog_density
	env.fog_aerial_perspective = p.fog_aerial
	env.fog_sun_scatter = 0.1
	env.fog_height = 0.3
	env.fog_height_density = 0.02
	env.fog_sky_affect = 0.0
	env.volumetric_fog_enabled = p.volumetric_fog != 0
	env.volumetric_fog_density = p.volumetric_density
	env.volumetric_fog_albedo = Color(0.9, 0.93, 0.95)
	env.volumetric_fog_anisotropy = 0.6
	env.volumetric_fog_length = 64.0
	env.volumetric_fog_ambient_inject = 0.3
	env.volumetric_fog_sky_affect = 0.0
	sun.light_angular_distance = 1.2
	sun.light_color = Color(1.0, 0.91, 0.78)
	sun.directional_shadow_max_distance = 45.0
	sun.directional_shadow_blend_splits = true
	sun.shadow_blur = 1.0
	sky_mat.set_shader_parameter("cloud_shade", p.cloud_shade)
	sky_mat.set_shader_parameter("day_gain", p.sky_gain)
