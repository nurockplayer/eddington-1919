extends RefCounted
## Procedural reconstruction of the Cambridge measuring room (October 1917).
## All dimensions and staging are invented for the prologue; see M1 spec.

const WorldBuilder := preload("res://scripts/world_builder.gd")
const Look := preload("res://scripts/look.gd")
const Figures := preload("res://scripts/cambridge/figures.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")
const DepartureProps := preload("res://scripts/cambridge/departure_props.gd")
const StarDecor := preload("res://scripts/cambridge/star_decor.gd")

const ROOM_W := 9.0
const ROOM_D := 6.0
const ROOM_H := 3.6
## The north sky over Cambridge through the sash on departure night, 1919 March 7 21:00 GMT:
## Cassiopeia low in the north-west, Polaris, and the Plough high in the north-east, handle
## down. [name, x, y, magnitude]: a flat projection about altitude 47, azimuth 8 (east to the
## right, up is up), from J2000 positions; precession since 1919 (about 1 degree) is ignored.
## The pointers Merak -> Dubhe aim at Polaris (within about 3 degrees).
const NORTH_SKY := [
	["Schedar", -0.765, -0.063, 2.2], ["Caph", -0.664, -0.127, 2.3], ["Gamma Cas", -0.669, 0.002, 2.4],
	["Ruchbah", -0.693, 0.077, 2.7], ["Segin", -0.609, 0.145, 3.4], ["Polaris", -0.099, 0.099, 2.0],
	["Kochab", 0.177, 0.004, 2.1], ["Dubhe", 0.342, 0.425, 1.8], ["Merak", 0.439, 0.506, 2.4],
	["Phecda", 0.568, 0.401, 2.4], ["Megrez", 0.513, 0.308, 3.3], ["Alioth", 0.557, 0.207, 1.8],
	["Mizar", 0.586, 0.123, 2.2], ["Alkaid", 0.720, 0.046, 1.9],
]
## Fitted so no named star sits behind a glazing bar or in the street lamp's halo.
const NORTH_SKY_SCALE := 1.06
const NORTH_SKY_OFFSET := Vector2(0.94, 2.18)
const FILLER_STARS := 10
const WINDOW_STARS := 24  # NORTH_SKY + FILLER_STARS
const EMBER_GLOW := 0.75
const PENDULUM_ROD := 0.55
const RAIN_RUN := 0.5
const PENDULUM_SWING := 4.0  # degrees either side


static func _plaster_material(color: Color) -> StandardMaterial3D:
	# The shared weathering is too contrasty for the large Cambridge walls at
	# conversation distance. Keep its broad world-space variation, but soften it
	# and reduce the albedo range so it reads as aged plaster rather than mottling.
	var noise := FastNoiseLite.new()
	noise.frequency = 0.008
	noise.fractal_octaves = 2
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	ramp.colors = PackedColorArray([
		Color(0.94, 0.94, 0.93),
		Color(0.97, 0.97, 0.96),
		Color(1.0, 1.0, 0.99),
	])
	var texture := NoiseTexture2D.new()
	texture.width = 512
	texture.height = 512
	texture.seamless = true
	texture.noise = noise
	texture.color_ramp = ramp
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.94
	material.detail_enabled = true
	material.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	material.detail_albedo = texture
	material.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	material.uv2_triplanar = true
	material.uv2_world_triplanar = true
	material.uv2_scale = Vector3(0.3, 0.3, 0.3)
	return material


## Embers breathe with the fire's flicker, brighter where the light swells, and
## on a slower wave of their own so the coals never pulse in lockstep.
static func glow_embers(ember_mat: StandardMaterial3D, flicker: float, t: float) -> void:
	ember_mat.emission_energy_multiplier = EMBER_GLOW * (1.0 + 2.5 * (flicker - 1.0) + 0.12 * sin(t * 0.6))


## A seconds pendulum: it crosses the middle on every whole second, when the
## directors play the tick, and swings along the wall (about the x axis).
static func swing_pendulum(pendulum: Node3D, t: float) -> void:
	pendulum.rotation.x = deg_to_rad(PENDULUM_SWING) * sin(PI * t)


static func _window_glass_material(departure: bool) -> StandardMaterial3D:
	# Glazing has a broad, faint room reflection, never the timber weathering.
	var reflection := Gradient.new()
	reflection.offsets = PackedFloat32Array([0.0, 0.42, 0.58, 1.0])
	reflection.colors = PackedColorArray([
		Color(0.65, 0.70, 0.78), Color(0.78, 0.82, 0.88),
		Color(1.0, 1.0, 1.0), Color(0.65, 0.70, 0.78),
	])
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.gradient = reflection
	texture.fill_from = Vector2.ZERO
	texture.fill_to = Vector2.ONE
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.19, 0.27) if departure else Color(0.12, 0.19, 0.23)
	material.albedo_texture = texture
	material.roughness = 0.24
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


## Streaks rest on a staggered grid over the visible half of the sash; each runs
## RAIN_RUN down the glass at its own pace (fixed seed), see window_rain.gdshader.
static func _window_rain() -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1917
	var rain_mm := MultiMesh.new()
	rain_mm.transform_format = MultiMesh.TRANSFORM_3D
	rain_mm.use_custom_data = true
	var rain_mesh := BoxMesh.new()
	rain_mesh.size = Vector3(0.012, 0.16, 0.006)
	rain_mm.mesh = rain_mesh
	rain_mm.instance_count = 36
	var spots: Array[Vector3] = []
	var rates: Array[float] = []
	for i in rain_mm.instance_count:
		var x := -0.02 + float(i % 9) * 0.235
		var y := 1.25 + RAIN_RUN + float((i * 7) % 17) * 0.098 * (1.66 - RAIN_RUN) / 1.66
		spots.append(Vector3(x, y, -2.79))
		rates.append(rng.randf_range(0.12, 0.3))
		rain_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, spots[i]))
		rain_mm.set_instance_custom_data(i, Color(rng.randf(), rates[i], 0.0, 0.0))
	var rain_streaks := MultiMeshInstance3D.new()
	rain_streaks.name = "RainStreaks"
	rain_streaks.multimesh = rain_mm
	# Headless keeps no MultiMesh data, so the tests read the layout from here.
	rain_streaks.set_meta("spots", spots)
	rain_streaks.set_meta("rates", rates)
	var rain_mat := ShaderMaterial.new()
	rain_mat.shader = preload("res://shaders/window_rain.gdshader")
	rain_mat.set_shader_parameter("run", RAIN_RUN)
	rain_streaks.material_override = rain_mat
	rain_streaks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The shader moves the streaks down to RAIN_RUN below their rest points.
	rain_streaks.custom_aabb = AABB(Vector3(-0.1, 1.1, -2.85), Vector3(2.15, 1.85, 0.12))
	return rain_streaks


## With the blackout curtains gone, the north sky shows above the street lamp: the real
## Cassiopeia, Polaris and Plough (NORTH_SKY), plus a few faint filler stars.
## Upper sash only, clear of the glazing bars and the lamp halo; fixed seed.
static func _window_stars(window_center: Vector3, lamp: Vector3) -> MultiMeshInstance3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1919
	var bars: Array[float] = []
	for x in [-1.9, -0.625, 0.625, 1.9]:
		bars.append(window_center.x + x)
	var spots: Array[Vector3] = []
	var mags: Array[float] = []
	for star in NORTH_SKY:
		spots.append(Vector3(window_center.x + NORTH_SKY_OFFSET.x + star[1] * NORTH_SKY_SCALE,
			NORTH_SKY_OFFSET.y + (star[2] + 0.13) * NORTH_SKY_SCALE, window_center.z + 0.025))
		mags.append(star[3])
	var tries := 0
	while spots.size() < WINDOW_STARS and tries < 400:
		tries += 1
		var p := Vector3(window_center.x + rng.randf_range(-1.82, 1.82), rng.randf_range(2.16, 2.88), window_center.z + 0.025)
		if Vector2(p.x - lamp.x, p.y - lamp.y).length() < 0.34:
			continue
		var on_bar := false
		for b in bars:
			on_bar = on_bar or absf(p.x - b) < 0.07
		var crowded := false
		for q in spots:
			crowded = crowded or Vector2(p.x - q.x, p.y - q.y).length() < 0.09
		if not on_bar and not crowded:
			spots.append(p)
			mags.append(4.2)  # faint filler, so the named shapes read first
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	mm.mesh = quad
	mm.instance_count = spots.size()
	var looks: Array[Vector2] = []  # (size, strength) per star; headless drops MultiMesh data
	for i in spots.size():
		# Brighter stars draw larger and stronger; magnitude 1.8 -> 0.05 m at 0.9, 4.2 -> 0.022 m at 0.3.
		var bright := clampf((4.2 - mags[i]) / 2.4, 0.0, 1.0)
		var size := lerpf(0.022, 0.05, bright)
		mm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3(size, size, 1.0)), spots[i]))
		var warm := rng.randf()
		mm.set_instance_color(i, Color(0.80 + 0.2 * warm, 0.86, 1.0 - 0.15 * warm, lerpf(0.3, 0.9, bright)))
		looks.append(Vector2(size, lerpf(0.3, 0.9, bright)))
		mm.set_instance_custom_data(i, Color(rng.randf() * TAU, rng.randf_range(0.6, 1.8), 0, 0))
	var stars := MultiMeshInstance3D.new()
	stars.name = "DepartureWindowStars"
	stars.multimesh = mm
	var material := ShaderMaterial.new()
	material.shader = preload("res://shaders/window_stars.gdshader")
	stars.material_override = material
	stars.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	stars.set_meta("spots", spots)
	stars.set_meta("looks", looks)
	return stars


static func build(root: Node3D, departure := false) -> Dictionary:
	var w = WorldBuilder.new(root)
	var out := {"targets": {}}
	var wood: Color = w.P("teak")
	var dark_wood: Color = w.P("teak_dark")
	var iron: Color = w.P("iron")
	var brass: Color = w.P("brass")
	var plaster := Color(0.43, 0.40, 0.34)
	var plaster_material := _plaster_material(plaster)
	var floor_color := Color(0.25, 0.22, 0.18)
	var evidence := Color(0.93, 0.92, 0.87)

	# Weathered plaster and floor; the south wall opening is the corridor entrance.
	w.box(Vector3(ROOM_W, 0.16, ROOM_D), Vector3(0, -0.08, 0), floor_color)
	w.box(Vector3(0.14, ROOM_H, ROOM_D), Vector3(-4.43, 1.8, 0), dark_wood)
	w.box(Vector3(0.14, ROOM_H, ROOM_D), Vector3(4.43, 1.8, 0), dark_wood)
	# North wall is framed around the sash opening, so the cold pane remains visible.
	# The left pier meets the sash; leaving it at x=-2.5 opened a player-width gap.
	w.box(Vector3(3.1, ROOM_H, 0.14), Vector3(-2.95, 1.8, -2.93), dark_wood)
	w.box(Vector3(2.0, ROOM_H, 0.14), Vector3(3.5, 1.8, -2.93), dark_wood)
	w.box(Vector3(4.0, 1.05, 0.14), Vector3(0.55, 0.525, -2.93), dark_wood)
	w.box(Vector3(4.0, 0.575, 0.14), Vector3(0.55, 3.3125, -2.93), dark_wood)
	# South wall leaves a generous doorway, 1.4 m wide.
	w.box(Vector3(3.8, ROOM_H, 0.14), Vector3(-2.6, 1.8, 2.93), dark_wood)
	w.box(Vector3(3.8, ROOM_H, 0.14), Vector3(2.6, 1.8, 2.93), dark_wood)
	w.box(Vector3(1.4, 0.45, 0.14), Vector3(0, 3.375, 2.93), dark_wood)
	# The open doorway enters a short, fully enclosed corridor rather than a void.
	w.box(Vector3(1.7, 0.16, 4.8), Vector3(0, -0.08, 5.35), floor_color)
	for x in [-0.82, 0.82]:
		var wall := w.box(Vector3(0.14, ROOM_H, 4.8), Vector3(x, 1.8, 5.35), plaster)
		wall.name = "CorridorPlasterLeft" if x < 0 else "CorridorPlasterRight"
		(wall.get_child(1) as MeshInstance3D).material_override = plaster_material
	var hall_end := w.box(Vector3(1.7, ROOM_H, 0.14), Vector3(0, 1.8, 7.75), plaster)
	hall_end.name = "CorridorPlasterEnd"
	(hall_end.get_child(1) as MeshInstance3D).material_override = plaster_material
	w.box(Vector3(1.7, 0.16, 4.8), Vector3(0, 3.52, 5.35), dark_wood, null, false)
	# A low-lit closed door gives the corridor a readable end rather than a black gap.
	w.box(Vector3(1.28, 2.8, 0.08), Vector3(0, 1.4, 7.62), wood, null, false)
	for y in [0.75, 2.0]:
		w.box(Vector3(1.05, 0.95, 0.04), Vector3(0, y, 7.55), dark_wood, null, false)
	w.cyl(0.04, 0.07, Vector3(0.45, 1.2, 7.48), brass, null, false, Vector3(deg_to_rad(90), 0, 0))
	var hall_fill := OmniLight3D.new()
	hall_fill.name = "CorridorBounce"
	hall_fill.position = Vector3(0, 2.4, 5.6)
	hall_fill.light_color = Color(0.90, 0.78, 0.59)
	hall_fill.light_energy = 0.8
	hall_fill.omni_range = 4.2
	hall_fill.omni_attenuation = 1.7
	hall_fill.light_specular = 0.0
	hall_fill.shadow_enabled = false
	root.add_child(hall_fill)
	w.box(Vector3(ROOM_W, 0.16, ROOM_D), Vector3(0, 3.52, 0), dark_wood, null, false)
	for x in [-4.34, 4.34]:
		var wall := w.box(Vector3(0.025, 2.15, 5.8), Vector3(x, 2.375, 0), plaster, null, false)
		(wall as MeshInstance3D).material_override = plaster_material
	for x in [-3.5, 3.5]:
		var north_width := 3.0 if x < 0 else 1.85
		var north_center := -2.95 if x < 0 else 3.5
		var north_wall := w.box(Vector3(north_width, 2.15, 0.025), Vector3(north_center, 2.375, -2.84), plaster, null, false)
		(north_wall as MeshInstance3D).material_override = plaster_material
		var south_wall := w.box(Vector3(3.7, 2.15, 0.025), Vector3(x * 0.743, 2.375, 2.84), plaster, null, false)
		(south_wall as MeshInstance3D).material_override = plaster_material
	# Door jambs and skirting keep the corridor legible in the south wall.
	for x in [-0.75, 0.75]:
		w.box(Vector3(0.1, 3.1, 0.18), Vector3(x, 1.55, 2.83), wood, null, false)
	w.box(Vector3(1.6, 0.1, 0.18), Vector3(0, 3.1, 2.83), wood, null, false)
	for x in [-4.3, 4.3]:
		w.box(Vector3(0.06, 0.14, 5.8), Vector3(x, 0.14, 0), wood, null, false)
	# Dark rafters break up the ceiling plane and give the room a human scale.
	for x in [-3.3, -1.1, 1.1, 3.3]:
		w.box(Vector3(0.12, 0.2, 5.8), Vector3(x, 3.38, 0), wood, null, false)

	# Tall sash window on the north wall: divided panes, wet dark glazing, half-drawn curtain.
	var window_center := Vector3(0.55, 2.05, -2.82)
	var glass_mat := _window_glass_material(departure)
	out.window_glass = glass_mat
	for x in [-1.25, 0.0, 1.25]:
		var pane := w.box(Vector3(1.15, 1.75, 0.025), window_center + Vector3(x, 0, 0), Color(0.16, 0.23, 0.27), null, false)
		pane.name = "WindowPane%d" % int((x + 1.25) / 1.25)
		(pane as MeshInstance3D).material_override = glass_mat
	for x in [-1.9, -0.625, 0.625, 1.9]:
		w.box(Vector3(0.075, 1.95, 0.11), window_center + Vector3(x, 0, 0.03), wood, null, false)
	for y in [1.08, 2.05, 3.02]:
		w.box(Vector3(3.9, 0.075, 0.11), Vector3(0.55, y, -2.77), wood, null, false)
	w.box(Vector3(4.0, 0.08, 0.28), Vector3(0.55, 1.025, -2.66), wood, null, false)
	if departure:
		# A distant gas lamp, placed in the pane visible beside Kit on arrival.
		var halo := Gradient.new()
		halo.offsets = PackedFloat32Array([0.0, 0.045, 0.13, 0.40, 1.0])
		halo.colors = PackedColorArray([
			Color(1.0, 0.94, 0.73, 1.0), Color(1.0, 0.85, 0.51, 0.95),
			Color(1.0, 0.67, 0.30, 0.55), Color(1.0, 0.55, 0.22, 0.12),
			Color(1.0, 0.48, 0.18, 0.0),
		])
		var halo_texture := GradientTexture2D.new()
		halo_texture.width = 128
		halo_texture.height = 128
		halo_texture.gradient = halo
		halo_texture.fill = GradientTexture2D.FILL_RADIAL
		halo_texture.fill_from = Vector2(0.5, 0.5)
		halo_texture.fill_to = Vector2(0.5, 1.0)
		var halo_material := StandardMaterial3D.new()
		halo_material.albedo_texture = halo_texture
		halo_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		halo_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		var lamp_point := MeshInstance3D.new()
		lamp_point.name = "DepartureStreetLampPoint"
		var quad := QuadMesh.new()
		quad.size = Vector2(0.48, 0.48)
		lamp_point.mesh = quad
		lamp_point.material_override = halo_material
		lamp_point.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		lamp_point.position = Vector3(-0.70, 2.50, -2.79)
		root.add_child(lamp_point)
		root.add_child(_window_stars(window_center, lamp_point.position))
	# Rain running down the visible half of the sash, drawn as one low-cost mesh instance.
	if not departure:
		root.add_child(_window_rain())
	# Curtain drawn across the left half; folds are broad and economical.
	if not departure:
		w.box(Vector3(1.95, 2.15, 0.08), Vector3(-1.3, 1.95, -2.69), Color(0.29, 0.27, 0.23), null, false)
		for x in [-2.05, -1.4, -0.75]:
			w.box(Vector3(0.035, 2.1, 0.10), Vector3(x, 1.95, -2.62), Color(0.22, 0.21, 0.19), null, false)
	var window_light := OmniLight3D.new()
	window_light.name = "DepartureStreetLampGlow" if departure else "ColdWindowFill"
	window_light.position = Vector3(-0.70, 2.35, -2.45) if departure else Vector3(0.5, 2.35, -2.45)
	window_light.light_color = Color(1.0, 0.64, 0.34) if departure else Color(0.48, 0.65, 0.82)
	window_light.light_energy = 0.85 if departure else 1.25
	window_light.omni_range = 8.0
	window_light.omni_attenuation = 1.25
	window_light.shadow_enabled = false
	window_light.light_specular = 0.0
	root.add_child(window_light)
	var floor_bounce := SpotLight3D.new()
	floor_bounce.name = "WindowFloorBounce"
	floor_bounce.position = Vector3(0.65, 1.35, -2.4)
	floor_bounce.light_color = Color(1.0, 0.68, 0.39) if departure else Color(0.55, 0.69, 0.86)
	floor_bounce.light_energy = 0.4 if departure else 0.65
	floor_bounce.spot_range = 6.0
	floor_bounce.spot_angle = 48.0
	floor_bounce.spot_attenuation = 0.7
	floor_bounce.light_specular = 0.0
	floor_bounce.shadow_enabled = false
	root.add_child(floor_bounce)
	floor_bounce.look_at(Vector3(0.65, 0, 0.7))
	out.floor_bounce = floor_bounce

	# Central measuring table, with evidence at the near-facing edge for easy reach.
	_table(w, Vector3(0, 0, 0), Vector3(3.5, 0.78, 1.45), wood)
	# Copy chart, loupe and inkwell are present as restrained set dressing.
	var chart := w.box(Vector3(0.72, 0.018, 0.5), Vector3(-0.48, 0.795, -0.04), evidence, null, false)
	(chart as MeshInstance3D).material_override = w.evidence_mat(Color(0.79, 0.76, 0.68))
	w.box(Vector3(0.10, 0.02, 0.025), Vector3(-0.48, 0.808, -0.03), Color(0.18, 0.13, 0.09), null, false)
	if not departure:
		w.cyl(0.11, 0.035, Vector3(-0.95, 0.82, 0.25), brass, null, false)
		w.cyl(0.07, 0.03, Vector3(-0.95, 0.84, 0.25), Color(0.13, 0.18, 0.2), null, false)
	w.box(Vector3(0.22, 0.035, 0.18), Vector3(-0.1, 0.82, 0.28), dark_wood, null, false)
	w.cyl(0.035, 0.11, Vector3(-0.1, 0.89, 0.28), iron, null, false)

	# Light box: slanted frame, bright frosted evidence glass and under-light.
	var lightbox := Node3D.new()
	lightbox.name = "LightBox"
	lightbox.position = Vector3(-0.85, 0.80, -0.23)
	lightbox.rotation.x = deg_to_rad(-9.0)
	root.add_child(lightbox)
	w.box(Vector3(0.92, 0.13, 0.66), Vector3(0, -0.045, 0), dark_wood, lightbox, false)
	var frosted := w.box(Vector3(0.79, 0.018, 0.54), Vector3(0, 0.035, 0), evidence, lightbox, false)
	var frosted_material := w.evidence_mat(Color(0.96, 0.95, 0.89), 0.55).duplicate() as StandardMaterial3D
	frosted_material.emission_enabled = true
	frosted_material.emission = Color(0.82, 0.81, 0.77)
	frosted_material.emission_energy_multiplier = 0.4
	(frosted as MeshInstance3D).material_override = frosted_material
	# Plate and chart marks are explicitly evidence surfaces.
	var plate := w.box(Vector3(0.57, 0.008, 0.38), Vector3(0, 0.05, 0), Color(0.88, 0.88, 0.84), lightbox, false)
	var plate_mat := w.evidence_mat(Color(0.91, 0.91, 0.87), 0.5).duplicate() as StandardMaterial3D
	plate_mat.emission_enabled = true
	plate_mat.emission = Color(0.91, 0.91, 0.88)
	plate_mat.emission_energy_multiplier = 0.5
	(plate as MeshInstance3D).material_override = plate_mat
	for p in [Vector3(-0.19, 0.056, -0.10), Vector3(-0.06, 0.056, -0.11), Vector3(0.11, 0.056, -0.08), Vector3(0.20, 0.056, 0.04), Vector3(-0.12, 0.056, 0.11), Vector3(0.09, 0.056, 0.12)]:
		var dot := w.cyl(0.018, 0.006, p, Color(0.16, 0.16, 0.15), lightbox, false)
		(dot as MeshInstance3D).material_override = w.evidence_mat(Color(0.13, 0.13, 0.12))
	var underlight := OmniLight3D.new()
	underlight.name = "LightBoxGlow"
	underlight.position = Vector3(0, -0.08, 0)
	underlight.light_color = Color(1.0, 0.84, 0.55)
	underlight.light_energy = 0.32
	underlight.omni_range = 0.8
	underlight.shadow_enabled = false
	lightbox.add_child(underlight)
	var lightbox_hotspot := w.hotspot(Vector3(0.88, 0.25, 0.65), lightbox.transform * Vector3(0, 0.13, 0), "lightbox", "查看底片")
	lightbox_hotspot.rotation = lightbox.rotation
	out.targets["lightbox"] = lightbox_hotspot.global_position if root.is_inside_tree() else lightbox_hotspot.position

	# Player notebook and Kit's independent plate stack and ledger.
	var notebook := w.box(Vector3(0.38, 0.055, 0.28), Vector3(0.72, 0.825, 0.22), Color(0.37, 0.24, 0.15), null, false)
	w.box(Vector3(0.34, 0.012, 0.24), Vector3(0.72, 0.86, 0.22), Color(0.78, 0.73, 0.62), null, false)
	var notebook_hotspot := w.hotspot(Vector3(0.44, 0.18, 0.34), Vector3(0.72, 0.9, 0.22), "notebook", "查看筆記本")
	out.targets["notebook"] = notebook_hotspot.position
	for i in range(3):
		w.box(Vector3(0.38, 0.035, 0.28), Vector3(1.13, 0.81 + i * 0.035, -0.20), Color(0.45, 0.38, 0.29), null, false)
	var kit_ledger := w.box(Vector3(0.4, 0.06, 0.3), Vector3(1.14, 0.89, 0.20), Color(0.28, 0.30, 0.26), null, false)
	var ledger_hotspot := w.hotspot(Vector3(0.48, 0.2, 0.36), Vector3(1.14, 0.94, 0.20), "kit_ledger", "查看 %s 的工作簿" % Cast.KIT)
	out.targets["kit_ledger"] = ledger_hotspot.position
	if departure:
		var plate_label := Label3D.new()
		plate_label.text = "KIT 的變星底片"
		var label_font := SystemFont.new()
		label_font.font_names = PackedStringArray(["PingFang TC", "Heiti TC", "Noto Sans CJK TC"])
		plate_label.font = label_font
		plate_label.font_size = 24
		plate_label.pixel_size = 0.0025
		plate_label.modulate = Color(0.72, 0.65, 0.52)
		plate_label.position = Vector3(1.43, 1.02, -0.02)
		root.add_child(plate_label)

	# Green-shaded oil lamp, the warm key and light pool.
	var lamp_shift := Vector3.ZERO if departure else Vector3(-2.45, 0, 0.1)
	w.cyl(0.07, 0.18, Vector3(0.25, 0.92, -0.19) + lamp_shift, brass, null, false)
	w.cyl(0.025, 0.25, Vector3(0.25, 1.12, -0.19) + lamp_shift, iron, null, false)
	var shade := w.cyl(0.28, 0.16, Vector3(0.25, 1.31, -0.19) + lamp_shift, Color(0.15, 0.34, 0.19), null, false, Vector3.ZERO, 0.15)
	var lamp := OmniLight3D.new()
	lamp.name = "GreenShadeLamp"
	lamp.position = Vector3(0.25, 1.14, -0.19) + lamp_shift
	lamp.light_color = Color(1.0, 0.73, 0.43)
	lamp.light_energy = 1.5
	lamp.omni_range = 5.0
	lamp.omni_attenuation = 1.35
	lamp.shadow_enabled = true
	if not departure:
		lamp.light_size = 0.10
		lamp.light_energy = 1.5
		lamp.light_specular = 0.15
		# The green glass shade transmits the key instead of acting as an opaque
		# lid. The source stays under it, so its top cannot outshine the paper.
		shade.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(lamp)
	out.lamp = lamp
	out.lamp_dust = _lamp_dust(root, lamp.position)

	# Interactable set dressing along the walls. Hotspots are in the room side of props.
	_shelf(w, Vector3(3.65, 0, -1.35), wood, dark_wood)
	out.merge(StarDecor.build(w, brass, dark_wood))
	if not departure:
		# Issue #37 loop 1: Newton's clockwork, and the small number it cannot fit.
		# It stands 0.2 m back on the top board, above eye height: the box reaches out past
		# the board's front edge (x 3.31) and below it, so a ray from the floor finds it first.
		var orrery_hotspot := w.hotspot(Vector3(0.36, 0.34, 0.34), out.orrery.position + Vector3(-0.17, 0.0, 0.03), "orrery", "查看太陽系儀")
		out.targets["orrery"] = orrery_hotspot.position
	var logbook := w.box(Vector3(0.42, 0.09, 0.31), Vector3(3.38, 1.42, -1.38), Color(0.37, 0.27, 0.18), null, false)
	var log_hotspot := w.hotspot(Vector3(0.55, 0.3, 0.4), Vector3(3.28, 1.46, -1.34), "logbook", "查看 1915 年觀測日誌")
	out.targets["logbook"] = log_hotspot.position

	# Plate cabinet against west wall, with shallow visible drawer fronts.
	w.box(Vector3(0.72, 1.72, 1.05), Vector3(-3.82, 0.86, -0.9), dark_wood)
	for y in [0.24, 0.57, 0.90, 1.23, 1.56]:
		w.box(Vector3(0.045, 0.025, 0.91), Vector3(-3.43, y, -0.9), wood, null, false)
		w.cyl(0.025, 0.09, Vector3(-3.39, y, -0.9), brass, null, false, Vector3(0, 0, deg_to_rad(90)))
	var cabinet_hotspot := w.hotspot(Vector3(0.8, 1.6, 1.1), Vector3(-3.1, 0.9, -0.9), "cabinet", "查看底片櫃")
	out.targets["cabinet"] = cabinet_hotspot.position

	# Empty copyist desk and chair, with an unsigned folded letter.
	_table(w, Vector3(-2.55, 0, 0.05), Vector3(1.55, 0.75, 0.9), dark_wood)
	var folded_letter := w.box(Vector3(0.28, 0.025, 0.2), Vector3(-2.47, 0.79, -0.02), Color(0.78, 0.73, 0.63), null, false)
	if not departure:
		folded_letter.position.y = 0.815
		(folded_letter as MeshInstance3D).material_override = w.evidence_mat(Color(0.91, 0.90, 0.85))
	var letter_hotspot := w.hotspot(Vector3(0.4, 0.18, 0.3), Vector3(-2.47, 0.86, -0.02), "letter", "查看摺起的信")
	out.targets["letter"] = letter_hotspot.position
	var chair_shift := Vector3.ZERO if departure else Vector3(0.8, 0, 0.55)
	w.box(Vector3(0.52, 0.1, 0.52), Vector3(-2.55, 0.52, 0.82) + chair_shift, wood)
	for x in [-2.78, -2.32]:
		w.box(Vector3(0.06, 0.52, 0.06), Vector3(x, 0.26, 0.82) + chair_shift, wood, null, false)
	# Coat on a wall peg; no identity or initials.
	w.cyl(0.04, 0.15, Vector3(-3.9, 1.7, 1.0), brass, null, false, Vector3(0, 0, deg_to_rad(90)))
	w.box(Vector3(0.48, 0.68, 0.12), Vector3(-3.82, 1.18, 1.0), Color(0.22, 0.23, 0.24), null, false)
	# M1's broad empty-desk hotspot overlaps Kit's departure staging point.
	# Keep the desk and chair geometry, but remove this obsolete interaction volume in 1919.
	if not departure:
		var empty_hotspot := w.hotspot(Vector3(1.7, 1.7, 1.0), Vector3(-2.55, 0.9, 0.62), "empty_desk", "查看空桌")
		out.targets["empty_desk"] = empty_hotspot.position

	# Fireplace and low coal fire, opposite the window. Fire has no dynamic particles.
	w.box(Vector3(0.18, 1.45, 1.35), Vector3(4.32, 0.73, 1.35), dark_wood)
	w.box(Vector3(0.20, 0.13, 1.55), Vector3(4.22, 1.5, 1.35), wood, null, false)
	w.box(Vector3(0.10, 0.72, 0.92), Vector3(4.14, 0.68, 1.35), iron, null, false)
	var embers := w.box(Vector3(0.035, 0.19, 0.65), Vector3(4.07, 0.3, 1.35), Color(0.44, 0.15, 0.05), null, false)
	var ember_mat := w.mat(Color(0.44, 0.15, 0.05)).duplicate() as StandardMaterial3D
	ember_mat.emission_enabled = true
	ember_mat.emission = Color(0.68, 0.19, 0.045)
	ember_mat.emission_energy_multiplier = EMBER_GLOW
	(embers as MeshInstance3D).material_override = ember_mat
	for z in [1.12, 1.35, 1.58]:
		w.box(Vector3(0.05, 0.29, 0.035), Vector3(4.025, 0.35, z), iron, null, false)
	var fire_light := OmniLight3D.new()
	fire_light.name = "CoalFireBounce"
	fire_light.position = Vector3(3.92, 0.48, 1.35)
	fire_light.light_color = Color(1.0, 0.57, 0.29)
	fire_light.light_energy = 1.0
	fire_light.omni_range = 5.2
	fire_light.omni_attenuation = 1.3
	fire_light.light_specular = 0.0
	fire_light.shadow_enabled = false
	root.add_child(fire_light)
	out.fire_light = fire_light
	out.ember_mat = ember_mat
	var fire_hotspot := w.hotspot(Vector3(0.6, 0.8, 0.9), Vector3(3.45, 0.58, 1.35), "fire", "查看爐火")
	out.targets["fire"] = fire_hotspot.position

	# Regulator clock on the west wall.
	w.box(Vector3(0.1, 1.15, 0.42), Vector3(-4.28, 2.3, -2.05), wood)
	w.cyl(0.18, 0.07, Vector3(-4.18, 2.65, -2.05), brass, null, false, Vector3(0, 0, deg_to_rad(90)))
	w.cyl(0.14, 0.08, Vector3(-4.12, 2.65, -2.05), Color(0.75, 0.7, 0.55), null, false, Vector3(0, 0, deg_to_rad(90)))
	# Its seconds pendulum hangs in front of the case, below the dial.
	var pendulum := Node3D.new()
	pendulum.name = "ClockPendulum"
	pendulum.position = Vector3(-4.215, 2.47, -2.05)
	root.add_child(pendulum)
	w.box(Vector3(0.008, PENDULUM_ROD, 0.012), Vector3(0, -PENDULUM_ROD * 0.5, 0), brass, pendulum, false)
	w.cyl(0.055, 0.02, Vector3(0, -PENDULUM_ROD, 0), brass, pendulum, false, Vector3(0, 0, deg_to_rad(90)))
	out.pendulum = pendulum
	var clock_hotspot := w.hotspot(Vector3(0.85, 1.35, 0.7), Vector3(-3.55, 2.3, -2.05), "clock", "查看調節鐘")
	out.targets["clock"] = clock_hotspot.position

	# Kit waits at the far end of the table and is reachable from either side.
	var kit := _npc_without_hat(w, Cast.KIT, Vector3(-2.1, 0, 0.5) if departure else Vector3(2.7, 0, 0.85), Color(0.27, 0.29, 0.30), Color(0.75, 0.70, 0.60), "kit")
	kit.rotation.y = deg_to_rad(155)
	out.kit = kit
	out.targets["kit"] = kit.global_position if root.is_inside_tree() else kit.position

	# Late arrivals are staged by the chapter controller; no hats indoors.
	out.mentor = _npc_without_hat(w, Cast.MENTOR, Vector3(0, 0, 6.4) if departure else Vector3(-2.65, 0, 1.05), Color(0.24, 0.23, 0.22), Color(0.78, 0.75, 0.67), "mentor", not departure)
	out.mentor.visible = departure
	var mentor_shape := out.mentor.get_meta("room_collision_shape") as CollisionShape3D
	mentor_shape.disabled = not departure
	out.mentor.visibility_changed.connect(func(): mentor_shape.disabled = not out.mentor.visible)
	# A plain closed journal under the mentor's arm, kept as a single prop.
	if departure:
		w.box(Vector3(0.20, 0.035, 0.24), Vector3(0.27, 1.28, -0.12), Color(0.27, 0.22, 0.17), out.mentor, false)
	out.eddington = _npc_without_hat(w, Cast.EDDINGTON, Vector3(-3.35, 0, 2.35) if departure else Vector3(-3.65, 0, -0.30), Color(0.19, 0.2, 0.21), Color(0.83, 0.81, 0.76), "eddington", not departure)
	if not departure:
		out.eddington.rotation.y = -PI * 0.5
	out.eddington.visible = false
	var eddington_shape := out.eddington.get_meta("room_collision_shape") as CollisionShape3D
	eddington_shape.disabled = true
	out.eddington.visibility_changed.connect(func(): eddington_shape.disabled = not out.eddington.visible)
	if departure:
		# Three plain shipping crates flank the entrance; restrained lettering reads at room scale.
		for crate_spec in [Vector3(-2.55, 0.48, 2.05), Vector3(2.55, 0.48, 2.05), Vector3(3.20, 0.38, 1.35)]:
			var crate_height := 0.96 if crate_spec.y > 0.4 else 0.76
			var crate := w.box(Vector3(0.95, crate_height, 0.78), crate_spec, Color(0.36, 0.27, 0.18), null, true)
			var stencil := Label3D.new()
			stencil.text = "R.A.S. ECLIPSE"
			var crate_font := SystemFont.new()
			crate_font.font_names = PackedStringArray(["PingFang TC", "Heiti TC", "Noto Sans CJK TC"])
			stencil.font = crate_font
			stencil.font_size = 26
			stencil.pixel_size = 0.003
			stencil.modulate = Color(0.76, 0.67, 0.49)
			stencil.position = Vector3(0, 0, 0.397)
			crate.add_child(stencil)
		# Finished comparison list and Kit's variable-star plate stack on the bench.
		w.box(Vector3(0.48, 0.012, 0.34), Vector3(-0.45, 0.83, 0.28), Color(0.79, 0.73, 0.61), null, false)
		for i in range(4):
			w.box(Vector3(0.30, 0.002, 0.006), Vector3(-0.45, 0.839, 0.18 + i * 0.045), Color(0.22, 0.18, 0.14), null, false)
		# Workbook with an animated opening leaf; used by the M2 sky-promise beat.
		var workbook := DepartureProps.new() as Node3D
		workbook.position = Vector3(-1.20, 0.83, 0.40)
		workbook.name = "DepartureWorkbook"
		root.add_child(workbook)
		out.workbook = workbook
		var workbook_hotspot := w.hotspot(Vector3(0.58, 0.25, 0.43), Vector3(-1.20, 0.91, 0.40), "workbook", "查看工作簿")
		out.targets["workbook"] = workbook_hotspot.position

	# Target dictionary coordinates are fixed in room space and suitable for the player's 3.2 m ray.
	var window_hotspot := w.hotspot(Vector3(3.9, 2.15, 0.3), Vector3(0.55, 2.05, -2.25), "window", "查看窗外的路燈" if departure else "查看雨中的窗")
	out.targets["window"] = window_hotspot.position
	out.targets["kit"] = kit.position + Vector3(0, 1.1, 0)
	out.targets["lightbox"] = lightbox.transform * Vector3(0, 0.13, 0)
	out.targets["kit_ledger"] = Vector3(1.14, 0.94, 0.20)
	out.targets["logbook"] = Vector3(3.28, 1.46, -1.34)
	out.targets["empty_desk"] = Vector3(-2.55, 0.9, 0.62)
	out.targets["letter"] = Vector3(-2.47, 0.86, -0.02)
	out.targets["fire"] = Vector3(3.45, 0.58, 1.35)
	out.targets["clock"] = Vector3(-3.55, 2.3, -2.05)
	out.targets["cabinet"] = Vector3(-3.1, 0.9, -0.9)
	out.targets["notebook"] = Vector3(0.72, 0.9, 0.22)
	out.targets["window"] = Vector3(0.55, 2.05, -2.25)
	if departure:
		out.targets["corridor"] = Vector3(0, 0, 5.45)
		out.targets["mentor"] = out.mentor.position + Vector3(0, 1.0, 0)
		out.targets["kit"] = kit.position + Vector3(0, 1.0, 0)
	out.spawn = Vector3(0, 0, 2.35)
	out.window_light = window_light
	out.environment = _environment(root)
	return out


static func _lamp_dust(root: Node3D, light_pos: Vector3) -> CPUParticles3D:
	# A few dust motes drift through the cone under the shade and glint warm.
	# Decoration only; unshaded so they read as lit by the lamp itself.
	var dust := CPUParticles3D.new()
	dust.name = "LampDust"
	dust.position = light_pos + Vector3(0, -0.12, 0)
	dust.amount = 36
	dust.lifetime = 9.0
	dust.preprocess = 9.0  # already drifting when the room appears
	dust.randomness = 1.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(0.24, 0.08, 0.24)
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 180.0
	dust.initial_velocity_min = 0.004
	dust.initial_velocity_max = 0.008
	dust.gravity = Vector3.ZERO  # motes hang; drift stays between desk and shade
	# Cull on the whole drift volume (box + a life of drift), not the emitter point.
	var reach := dust.emission_box_extents + Vector3.ONE * (dust.initial_velocity_max * dust.lifetime + 0.05)
	dust.visibility_aabb = AABB(-reach, reach * 2.0)
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 1.0
	var fade := Gradient.new()
	fade.set_color(0, Color(1.0, 0.74, 0.45, 0.0))
	fade.set_color(1, Color(1.0, 0.74, 0.45, 0.0))
	fade.add_point(0.3, Color(1.0, 0.74, 0.45, 0.4))
	fade.add_point(0.7, Color(1.0, 0.74, 0.45, 0.4))
	dust.color_ramp = fade
	var quad := QuadMesh.new()
	quad.size = Vector2(0.006, 0.006)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	quad.material = mat
	dust.mesh = quad
	dust.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(dust)
	return dust


static func _table(w, pos: Vector3, size: Vector3, wood: Color) -> void:
	w.box(Vector3(size.x, 0.1, size.z), pos + Vector3(0, size.y, 0), wood)
	for x in [-size.x * 0.43, size.x * 0.43]:
		for z in [-size.z * 0.38, size.z * 0.38]:
			w.box(Vector3(0.1, size.y, 0.1), pos + Vector3(x, size.y * 0.5, z), wood)


static func _shelf(w, pos: Vector3, wood: Color, dark_wood: Color) -> void:
	for y in [0.75, 1.45, 2.15]:
		w.box(Vector3(0.68, 0.07, 1.7), pos + Vector3(0, y, 0), wood)
	for z in [-0.77, 0.77]:
		w.box(Vector3(0.07, 2.35, 0.08), pos + Vector3(0, 1.17, z), dark_wood)
	for row in range(3):
		for i in range(4):
			var h := 0.34 + 0.08 * float((row + i) % 3)
			w.box(Vector3(0.10, h, 0.29), pos + Vector3(-0.22 + i * 0.15, 0.79 + row * 0.70 + h * 0.5, -0.47 + (i % 2) * 0.43), Color(0.30 + 0.025 * i, 0.22 + 0.02 * row, 0.15))


static func _npc_without_hat(w, display_name: String, pos: Vector3, coat: Color, shirt: Color, id: String, production := false) -> Node3D:
	var body: Node3D
	if production:
		body = Figures.build_person(w, display_name, pos, id, "ashby" if id == "mentor" else "eddington_cambridge")
	else:
		body = Figures.build(w, display_name, pos, coat, shirt, id)
	var cs := body.get_child(0) as CollisionShape3D
	body.set_meta("room_collision_shape", cs)
	return body


static func _environment(root: Node3D) -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.045, 0.06)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.68, 0.71, 0.76)
	env.ambient_light_energy = 0.62
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05
	env.ssao_enabled = true
	env.ssao_radius = 1.1
	env.ssao_intensity = 1.25
	env.ssao_power = 1.2
	env.ssao_detail = 0.6
	Look.apply_grade(env)
	# Preserve the plate grade, with less contrast crush in this unlit interior.
	env.adjustment_contrast = 1.035
	var node := WorldEnvironment.new()
	node.name = "CambridgeRoomEnvironment"
	node.environment = env
	root.add_child(node)
	return node
