extends SceneTree
## Third contact: Baily's beads, then the diamond ring, then plain daylight.
const Cues := preload("res://scripts/totality_cues.gd")
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
	var start: Vector2 = Cues.third_contact_glint(0.0)
	check(start == Vector2.ZERO, "nothing before the Moon's limb opens")
	var beads_peak := 0.0
	var diamond_peak := 0.0
	var beads_at := 0.0
	var diamond_at := 0.0
	for i in 101:
		var v := i / 100.0
		var g: Vector2 = Cues.third_contact_glint(v)
		if g.x > beads_peak:
			beads_peak = g.x
			beads_at = v
		if g.y > diamond_peak:
			diamond_peak = g.y
			diamond_at = v
	check(beads_peak > 0.99 and diamond_peak > 0.99, "both beads and diamond reach full strength")
	check(beads_at < diamond_at, "beads come first, then the diamond: %.2f < %.2f" % [beads_at, diamond_at])
	check(Cues.third_contact_glint(0.5) == Vector2.ZERO, "both gone before half the daylight is back")
	check(Cues.third_contact_glint(1.0) == Vector2.ZERO, "nothing left at full daylight")
	var src := FileAccess.get_file_as_string("res://shaders/eclipse_sky.gdshader")
	check(src.contains("uniform vec2 third_contact"), "sky shader takes the third-contact glint")
	var main_src := FileAccess.get_file_as_string("res://scripts/main.gd")
	check(main_src.contains("sky_mat.set_shader_parameter(\"third_contact\", Vector2.ZERO)"), "glint is cleared once daylight returns")
	print("%d diamond ring checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
