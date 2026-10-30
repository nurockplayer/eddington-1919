extends SceneTree
## The night-after sky over Príncipe: data matches the shader and points the right way.
const NightSky := preload("res://scripts/night_sky.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func dir_of(name: String) -> Vector3:
	for s in NightSky.STARS:
		if s[0] == name:
			return NightSky.direction(s[1], s[2])
	return Vector3.ZERO


func _run() -> void:
	var shader_src := FileAccess.get_file_as_string("res://shaders/eclipse_sky.gdshader")
	var n := NightSky.STARS.size()
	check(shader_src.contains("uniform vec4 night_stars[%d];" % n), "shader array matches the %d stars" % n)
	check(shader_src.contains("i < %d;" % n), "shader loop covers every star")
	var u := NightSky.uniforms()
	check(u.size() == n, "one uniform per star")
	for v in u:
		check(absf(Vector3(v.x, v.y, v.z).length() - 1.0) < 0.001 and v.y > 0.0 and v.w > 0.0, "unit direction above the horizon")
	var acrux := dir_of("Acrux")
	check(acrux.z > 0.85 and acrux.y < 0.45, "Southern Cross stands low in the south")
	var antares := dir_of("Antares")
	check(antares.x < -0.4 and antares.z > 0.3, "Antares rises in the south-east")
	check(dir_of("Dubhe").z < -0.8, "the Plough lies to the north")
	check(dir_of("Spica").y > 0.95, "Spica is near the zenith")
	var core := NightSky.direction(NightSky.GALACTIC_CENTRE.x, NightSky.GALACTIC_CENTRE.y)
	check(core.angle_to(dir_of("Shaula")) < deg_to_rad(12.0), "the Milky Way's core sits by Scorpius' tail")
	var pole := NightSky.direction(NightSky.GALACTIC_POLE.x, NightSky.GALACTIC_POLE.y)
	check(absf(rad_to_deg(pole.angle_to(core)) - 90.0) < 1.0, "galactic pole is 90 degrees from the core")
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/eclipse_sky.gdshader")
	NightSky.apply(mat)
	check((mat.get_shader_parameter("night_stars") as PackedVector4Array).size() == n, "uniforms reach the material")
	print("%d night sky checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
