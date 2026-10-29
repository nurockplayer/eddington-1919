extends SceneTree
## Hyades sky in fades and behind the title; shooting stars on the title only.
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
	check(skies.size() == 2, "one sky in the fade and one behind the title")
	var title_sky = skies.filter(func(n): return n.meteors)
	check(title_sky.size() == 1 and title_sky[0].drop > 0.0, "only the title sky has shooting stars")
	if title_sky.size() != 1:
		print("%d fade stars checks, %d failures" % [checks, failures])
		quit(1)
		return
	for sky in skies:
		check(sky.mouse_filter == Control.MOUSE_FILTER_IGNORE, "sky never takes clicks")
	# Drive the title sky's clock for 40 s: streaks start, end after their life,
	# pause 7-14 s, and every streak runs inside the screen.
	var sky = title_sky[0]
	var starts: Array = []
	var ends := 0
	var was_active := false
	var screen := Rect2(Vector2.ZERO, sky.size)
	for i in 4000:
		sky._step_meteor(0.01)
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
	var plain := FadeStars.new()
	root.add_child(plain)
	for i in 2000:
		plain._process(0.01)
	check(plain._meteor.is_empty(), "fade skies stay still")
	plain.free()
	ui.free()
	print("%d fade stars checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
