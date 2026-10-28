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
	for sky in skies:
		check(sky.mouse_filter == Control.MOUSE_FILTER_IGNORE, "sky never takes clicks")
	# Drive the title sky's clock: within 20 s at least one streak shows and ends.
	var sky = title_sky[0]
	var seen := 0
	var was_active := false
	for i in 2000:
		sky._step_meteor(0.01)
		var active: bool = not sky._meteor.is_empty()
		if active and not was_active:
			seen += 1
			check(sky._meteor.dir.y > 0.0, "shooting star falls downward")
		was_active = active
	check(seen >= 1 and seen <= 4, "a shooting star every 7-14 s, first after 4 s: %d in 20 s" % seen)
	var plain := FadeStars.new()
	root.add_child(plain)
	for i in 2000:
		plain._process(0.01)
	check(plain._meteor.is_empty(), "fade skies stay still")
	plain.free()
	ui.free()
	print("%d fade stars checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
