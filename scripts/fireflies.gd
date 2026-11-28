extends MultiMeshInstance3D
## Fireflies blinking low among the palms on the night after the eclipse.

const Settings := preload("res://scripts/settings.gd")

const PER_PALM := 5
const SPREAD := 1.6
const LOW := 0.45
const HIGH := 1.7
const DRIFT := 0.025

var spots: PackedVector3Array
var palms: Array
var _age := 0.0
var _material := ShaderMaterial.new()


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

	_material.shader = preload("res://shaders/firefly_mark.gdshader")
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE
	quad.material = _material
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_custom_data = true
	multimesh.mesh = quad
	multimesh.instance_count = spots.size()
	var box := AABB(spots[0], Vector3.ZERO)
	for i in spots.size():
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, spots[i]))
		multimesh.set_instance_custom_data(i, Color(rng.randf(), rng.randf(), 0.0, 0.0))
		box = box.expand(spots[i])
	custom_aabb = box.grow(DRIFT + 0.2)
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_night(false)


func set_night(on: bool) -> void:
	visible = on
	set_process(on)


func _process(delta: float) -> void:
	if not Settings.reduced_motion:
		_age += delta
	_material.set_shader_parameter("age", -1.0 if Settings.reduced_motion else _age)
