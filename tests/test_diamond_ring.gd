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
	await _check_runtime()
	print("%d diamond ring checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


# The real third-contact path drives the sky: beads and diamond reach the
# material during the daylight tween and are cleared after it.
func _check_runtime() -> void:
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	main.phase = main.Phase.TOTALITY
	main.tot_done = false
	main._end_totality()
	var peak := Vector2.ZERO
	var dark_at_diamond := 0.0
	var deadline := Time.get_ticks_msec() + 8000
	while main.phase != main.Phase.NIGHT and Time.get_ticks_msec() < deadline:
		var g = main.sky_mat.get_shader_parameter("third_contact")
		if g is Vector2:
			if g.y > peak.y:
				dark_at_diamond = main.sky_mat.get_shader_parameter("darkness")
			peak = peak.max(g)
		await process_frame
	check(peak.x > 0.8, "real third contact shows Baily's beads: %.2f" % peak.x)
	check(peak.y > 0.8, "real third contact shows the diamond ring: %.2f" % peak.y)
	check(dark_at_diamond > 0.9, "the diamond burns against a still-dark sky: darkness %.2f" % dark_at_diamond)
	var after = main.sky_mat.get_shader_parameter("third_contact")
	check(after is Vector2 and after == Vector2.ZERO, "glint cleared by the time night begins: %s" % [after])
	main.queue_free()
	await process_frame
