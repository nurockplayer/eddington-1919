extends MultiMeshInstance3D
## Pinhole crescents: gaps in the palm fronds image the partly eclipsed Sun on
## the ground, as under any tree during the partial phases. Each spot is the
## projection of the sky's own Sun-and-Moon frame (eclipse_sky.gdshader) through
## a gap at its height, so its shape, size and stretch follow the real geometry.
## Decoration only; no game state.

const SHADER := preload("res://shaders/sun_crescent.gdshader")
# Radians: 1.5x the true solar radius (0.00465), so a spot reads from eye
# height (about 12 x 17 cm under a 7 m crown); the sky's disc is exaggerated 6x.
const SPOT_SUN_R := 0.007
const GAPS_PER_PALM := 14
const GAP_SPREAD := 1.9  # metres around the crown where frond gaps open

var spots: Array[Transform3D] = []  # same as the MultiMesh, readable without a GPU
var ground_to_sun := Vector4()  # row-major 2x2: ground offset per metre of gap height -> solar radii


func setup(crowns: Array, sun_dir: Vector3) -> void:
	name = "SunCrescents"
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# The sky's frame around the Sun: t1 right, t2 up, in solar radii.
	var t1 := sun_dir.cross(Vector3.UP).normalized()
	var t2 := t1.cross(sun_dir)
	var c1 := _ground(t1 * SPOT_SUN_R, sun_dir)
	var c2 := _ground(t2 * SPOT_SUN_R, sun_dir)
	var m := Transform2D(c1, c2, Vector2.ZERO).affine_inverse()
	ground_to_sun = Vector4(m.x.x, m.y.x, m.x.y, m.y.y)
	var mat := ShaderMaterial.new()
	mat.shader = SHADER
	mat.set_shader_parameter("ground_to_sun", ground_to_sun)
	material_override = mat
	var quad := PlaneMesh.new()
	var extent := (c1.length() + c2.length()) * 1.25
	quad.size = Vector2(extent, extent) * 2.0
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = quad
	mm.instance_count = crowns.size() * GAPS_PER_PALM
	var rng := RandomNumberGenerator.new()
	rng.seed = 1919_0529
	var i := 0
	for crown: Vector3 in crowns:
		for k in GAPS_PER_PALM:
			var r := sqrt(rng.randf()) * GAP_SPREAD
			var a := rng.randf() * TAU
			var gap := crown + Vector3(cos(a) * r, -rng.randf_range(0.1, 0.8), sin(a) * r)
			var spot := gap - sun_dir * (gap.y / sun_dir.y)
			# The image grows with the gap's height above the ground.
			spots.append(Transform3D(Basis().scaled(Vector3.ONE * gap.y), Vector3(spot.x, 0.012, spot.z)))
			mm.set_instance_transform(i, spots[i])
			i += 1
	multimesh = mm
	set_eclipse(0.0, 0.0)


## Ground offset (x, z) per metre of gap height for a small sky offset off the Sun.
static func _ground(delta: Vector3, sun_dir: Vector3) -> Vector2:
	var g := -(delta - sun_dir * (delta.y / sun_dir.y)) / sun_dir.y
	return Vector2(g.x, g.z)


## contact and the Moon's place match eclipse_sky.gdshader; brightness is the
## sunlight still reaching the ground (0 in totality, at night or under cloud).
func set_eclipse(contact: float, brightness: float) -> void:
	var mat := material_override as ShaderMaterial
	mat.set_shader_parameter("moon_c", Vector2((1.0 - contact) * 2.1, 0.12 * (1.0 - contact)))
	mat.set_shader_parameter("brightness", brightness)
	visible = brightness > 0.002
