extends SceneTree
## The live Hyades fade and the optional sky effects used by a title backdrop.
const FadeStars := preload("res://scripts/fade_stars.gd")
const UI := preload("res://scripts/ui.gd")
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
	var ui = UI.new()
	root.add_child(ui)
	await process_frame
	var skies: Array = ui.find_children("*", "Control", true, false).filter(func(n): return n.get_script() == FadeStars)
	var fade_sky: FadeStars = skies[0] if skies.size() == 1 else null
	check(fade_sky != null and fade_sky.get_parent() == ui.fade and fade_sky.target == ui.fade,
		"the live UI has one sky, attached to and following the fade")
	if failures:
		print("%d fade stars checks, %d failures" % [checks, failures])
		quit(1)
		return
	# F4 uses a static title plate. Exercise the former title configuration in
	# a test-only backdrop under the title's content.
	var sky := FadeStars.new()
	sky.target = ui.title_panel as ColorRect
	sky.drop = 0.16
	sky.meteors = true
	sky.figure = true
	ui.title_panel.add_child(sky, false, Node.INTERNAL_MODE_FRONT)
	sky.set_process(false)
	await process_frame
	check(not fade_sky.meteors and sky.meteors, "only the title backdrop enables shooting stars")
	for field in [fade_sky, sky]:
		check(field.mouse_filter == Control.MOUSE_FILTER_IGNORE, "sky never takes clicks")
	# Drive the title sky's clock for 40 s: streaks start, end after their life,
	# pause 7-14 s, and every streak runs inside the screen.
	var starts: Array = []
	var ends := 0
	var was_active := false
	var screen := Rect2(Vector2.ZERO, sky.size)
	for i in 4000:
		sky._process(0.01)
		var active: bool = not sky._meteor.is_empty()
		if active and not was_active:
			starts.append(i * 0.01)
			var c: Vector2 = sky.size * 0.5 + Vector2(0, sky.drop * sky.size.y)
			var a: Vector2 = c + sky._meteor.start * sky.size.y
			var b: Vector2 = c + (sky._meteor.start + sky._meteor.dir * 0.35) * sky.size.y
			check(screen.has_point(a) and screen.has_point(b), "streak runs inside the screen: %s -> %s" % [a, b])
			check(sky._meteor.dir.y > 0.0, "shooting star falls downward")
		if was_active and not active:
			ends += 1
		was_active = active
	check(starts.size() >= 2 and absf(starts[0] - 4.0) < 0.05, "first streak after 4 s, then more: %s" % [starts])
	check(ends >= starts.size() - 1, "every streak ends")
	for k in range(1, starts.size()):
		var gap: float = starts[k] - starts[k - 1] - FadeStars.METEOR_LIFE
		check(gap >= 6.98 and gap <= 14.02, "dark pause between streaks is 7-14 s: %.2f" % gap)
	# The bull's lines: real Taurus stars, faint, breathing in and out.
	for pair in FadeStars.FIGURE:
		for idx in pair:
			check(idx < FadeStars.NAMED.size(), "figure line uses a named star: %d" % idx)
	check(FadeStars.NAMED[2][0] < FadeStars.NAMED[1][0] and FadeStars.NAMED[1][0] < FadeStars.NAMED[0][0], "V arm runs gamma -> theta2 -> Aldebaran in RA")
	var peak := 0.0
	var low := 1.0
	sky._t = 0.0
	check(sky.figure_alpha() == 0.0, "lines wait before drawing")
	for i in 3200:
		sky._t = 2.0 + i * 0.01
		peak = maxf(peak, sky.figure_alpha())
		if sky._t > 2.0 + FadeStars.FIGURE_PERIOD * 0.5:  # after the first peak
			low = minf(low, sky.figure_alpha())
	check(peak <= FadeStars.FIGURE_ALPHA + 0.0001 and peak > 0.15, "lines stay faint: peak %.3f" % peak)
	check(low < 0.001, "lines fade fully away after each showing: %.4f" % low)
	ui.fade.color.a = 1.0
	for i in 2000:
		fade_sky._process(0.01)
	check(fade_sky.modulate.a > 0.0, "the live sky shows through an opaque fade")
	check(fade_sky._meteor.is_empty(), "fade skies stay still")
	check(fade_sky.figure_alpha() == 0.0, "fade skies draw no figure")
	ui.free()
	print("%d fade stars checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
