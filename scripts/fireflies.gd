extends CPUParticles3D
## Fireflies blinking low among the palms on the night after the eclipse.
## Decoration only; no game state. Hidden and idle until night.

const PER_PALM := 5
const SPREAD := 1.6  # metres around a palm's foot where they hover
const LOW := 0.45  # above a life of drift (0.04 m/s x 8 s), so none sinks into the ground
const HIGH := 1.7
const GLOW := Color(0.78, 1.0, 0.38)

var spots: PackedVector3Array  # emission points, readable without a GPU
var palms: Array  # the crowns they gather under


func setup(crowns: Array) -> void:
	name = "Fireflies"
	palms = crowns
	var rng := RandomNumberGenerator.new()
	rng.seed = 1919
	for c in crowns:
		for i in PER_PALM:
			var a := rng.randf() * TAU
			var r := rng.randf_range(0.4, SPREAD)
			spots.append(Vector3(c.x + cos(a) * r, rng.randf_range(LOW, HIGH), c.z + sin(a) * r))
	emission_shape = EMISSION_SHAPE_POINTS
	emission_points = spots
	amount = spots.size()
	lifetime = 8.0
	preprocess = 8.0
	randomness = 1.0
	direction = Vector3(0, 0.3, 0)
	spread = 180.0
	initial_velocity_min = 0.015
	initial_velocity_max = 0.04
	gravity = Vector3.ZERO
	scale_amount_min = 0.7
	scale_amount_max = 1.0
	# Three short blinks a life, dark in between; random starts keep them out of step.
	var blink := Gradient.new()
	blink.set_color(0, Color(GLOW, 0.0))
	blink.set_color(1, Color(GLOW, 0.0))
	for peak in [0.12, 0.5, 0.86]:
		blink.add_point(peak - 0.05, Color(GLOW, 0.0))
		blink.add_point(peak, Color(GLOW, 0.9))
		blink.add_point(peak + 0.06, Color(GLOW, 0.0))
	color_ramp = blink
	var halo := GradientTexture2D.new()
	halo.fill = GradientTexture2D.FILL_RADIAL
	halo.fill_from = Vector2(0.5, 0.5)
	halo.fill_to = Vector2(1.0, 0.5)
	halo.gradient = Gradient.new()
	halo.gradient.set_color(0, Color(1, 1, 1, 1))
	halo.gradient.set_color(1, Color(1, 1, 1, 0))
	var quad := QuadMesh.new()
	quad.size = Vector2(0.05, 0.05)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.billboard_keep_scale = true
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = halo
	quad.material = mat
	mesh = quad
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Cull on every spot plus a life of drift, not on the node's origin.
	var box := AABB(spots[0], Vector3.ZERO)
	for p in spots:
		box = box.expand(p)
	visibility_aabb = box.grow(initial_velocity_max * lifetime + 0.1)
	set_night(false)


func set_night(on: bool) -> void:
	visible = on
	emitting = on
