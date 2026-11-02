extends SceneTree
## Shooting stars on the night after: idle by day, now and then at night, high in
## the sky, short streaks that come and go without popping.
const NightMeteors := preload("res://scripts/night_meteors.gd")
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
	var shader_src := FileAccess.get_file_as_string("res://shaders/eclipse_sky.gdshader")
	for u in ["uniform vec3 meteor_head", "uniform vec3 meteor_tail", "uniform float meteor_glow"]:
		check(shader_src.contains(u), "shader declares " + u)
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	var m = main.meteors
	check(m != null and m.get_parent() == main, "main builds the meteors with the sky")
	main.set_process(false)  # drive the clock by hand below
	m.set_process(false)
	main._apply_light(0.8, 0.1, -60.0, 0.0)
	for i in 600:
		m.tick(0.05)
	check(m.count == 0 and m.glow == 0.0, "no meteors by day")
	main._apply_light(0.0, 0.0, 400.0, 1.0)
	check(m.active, "night wakes them")
	var high := true
	var short := true
	var peak := 0.0
	var gaps: Array[float] = []
	var dark_for := 0.0
	var was_lit := false
	var steps := 0
	for i in 2400:  # two minutes at 20 Hz
		m.tick(0.05)
		var lit: bool = m.glow > 0.0
		if lit:
			high = high and m.head.y > sin(deg_to_rad(NightMeteors.MIN_ALT)) - 0.01 and m.tail.y > 0.3
			short = short and m.head.angle_to(m.tail) <= NightMeteors.LENGTH + 0.01
			peak = maxf(peak, m.glow)
			if not was_lit and m.count > 1:  # the first waits only 3 s after dark
				gaps.append(dark_for)
			dark_for = 0.0
		else:
			dark_for += 0.05
		if lit != was_lit:
			steps += 1
		was_lit = lit
	check(m.count >= 6 and m.count <= 20, "now and then, not a shower: %d in two minutes" % m.count)
	check(high, "they stay high in the sky, out of the horizon haze")
	check(short, "short streaks")
	check(peak > 0.95, "each one flares to full: %.2f" % peak)
	check(gaps.min() >= NightMeteors.GAP_MIN - 0.1, "quiet between them: %.1f s at least" % gaps.min())
	var sampled: float = main.sky_mat.get_shader_parameter("meteor_glow")
	check(is_equal_approx(sampled, m.glow), "the sky shader gets the glow")
	# Glow ramps from zero: no pop at launch or at the end.
	m.set_night(false)
	m.set_night(true)
	m.wait = 0.0
	m.tick(0.01)
	m.tick(0.01)
	check(m.glow > 0.0 and m.glow < 0.1, "fades in: %.3f" % m.glow)
	main._apply_light(0.8, 0.1, -60.0, 0.0)
	check(not m.active and main.sky_mat.get_shader_parameter("meteor_glow") == 0.0, "gone again by day")
	print("%d meteor checks, %d failures" % [checks, failures])
	main.queue_free()
	await process_frame
	quit(1 if failures else 0)
