extends SceneTree
## Pinhole crescents under the palms: placed in the shade, shaped by the sky's
## own Sun-and-Moon frame, lit only while sunlight reaches the ground.
const Sim := preload("res://scripts/eclipse_sim.gd")
const World := preload("res://scripts/world_builder.gd")
const SunCrescents := preload("res://scripts/sun_crescents.gd")
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
	var sim := Sim.new(1919)
	var root3d := Node3D.new()
	root.add_child(root3d)
	var wb = World.new(root3d)
	wb.build()
	check(wb.palm_crowns.size() == 15, "every palm reports its crown: %d" % wb.palm_crowns.size())
	var sc = SunCrescents.new()
	sc.setup(wb.palm_crowns, sim.sun_dir)
	root3d.add_child(sc)
	var mm: MultiMesh = sc.multimesh
	check(mm.instance_count == 15 * SunCrescents.GAPS_PER_PALM, "frond gaps under every palm")
	# Each spot lies down-sun of its crown: the shade, not the palm's foot.
	var away := Vector2(-sim.sun_dir.x, -sim.sun_dir.z).normalized()
	var down_sun := 0
	for i in mm.instance_count:
		var t: Transform3D = sc.spots[i]
		var crown: Vector3 = wb.palm_crowns[i / SunCrescents.GAPS_PER_PALM]
		var off := Vector2(t.origin.x - crown.x, t.origin.z - crown.z)
		if off.dot(away) > 0.0:
			down_sun += 1
		if i == 0:
			check(t.origin.y > 0.0 and t.origin.y < 0.05, "spot rests on the ground")
			check(t.basis.get_scale().x > 4.0 and t.basis.get_scale().x < 10.0, "image scales with gap height")
	check(down_sun > mm.instance_count * 0.9, "spots fall in the palms' shade: %d/%d" % [down_sun, mm.instance_count])
	# The ground map inverts the projection: the Sun's own edge lands at 1 solar radius.
	var t1 := sim.sun_dir.cross(Vector3.UP).normalized()
	var g := SunCrescents._ground(t1 * SunCrescents.SPOT_SUN_R, sim.sun_dir)
	var m: Vector4 = sc.ground_to_sun
	var lp := Vector2(m.x * g.x + m.y * g.y, m.z * g.x + m.w * g.y)
	check(lp.distance_to(Vector2(1, 0)) < 1e-4, "ground map returns the Sun's edge to 1 radius: %s" % lp)
	# A pinhole image is inverted: the Sun's right edge lands on the ground's left of the shade line.
	var right_world := Vector3(g.x, 0, g.y)
	check(right_world.dot(Vector3(t1.x, 0, t1.z)) < 0.0, "pinhole image is inverted")
	# Low Sun stretches the spot along its azimuth: longer than wide.
	var t2 := t1.cross(sim.sun_dir)
	var g2 := SunCrescents._ground(t2 * SunCrescents.SPOT_SUN_R, sim.sun_dir)
	check(g2.length() > g.length() * 1.1, "spot is an ellipse stretched away from the Sun")
	var size_cm := g.length() * 2.0 * 7.0 * 100.0
	check(size_cm > 10.0 and size_cm < 20.0, "spot under a 7 m gap is palm-sized: %.1f cm" % size_cm)
	var mat := sc.material_override as ShaderMaterial
	check(mat.shader.code.contains("uniform vec2 moon_c"), "shader takes the sky's Moon offset")
	sc.set_eclipse(0.8, 0.6)
	check(sc.visible and is_equal_approx(mat.get_shader_parameter("brightness"), 0.6), "lit in the partial phase")
	check((mat.get_shader_parameter("moon_c") as Vector2).is_equal_approx(Vector2(0.2 * 2.1, 0.12 * 0.2)), "Moon placed as in the sky shader")
	var sky_src := FileAccess.get_file_as_string("res://shaders/eclipse_sky.gdshader")
	check(sky_src.contains("vec2 moon_c = vec2((1.0 - contact) * 2.1, 0.12 * (1.0 - contact));"), "sky shader's Moon formula is unchanged")
	sc.set_eclipse(1.0, 0.0)
	check(not sc.visible, "dark in totality")
	root3d.free()
	print("%d sun crescent checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
