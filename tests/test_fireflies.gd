extends SceneTree
## Fireflies among the palms: hidden by day, blinking low around the palm feet
## on the night after the eclipse.
const Fireflies := preload("res://scripts/fireflies.gd")
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
	var main: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	await process_frame
	var ff = main.world.get("fireflies")
	check(ff != null, "the island has fireflies")
	if ff == null:
		_finish()
		return
	check(not ff.visible and not ff.emitting, "none by day")
	main._apply_light(0.985, 0.9, -5.0, 0.0)
	check(not ff.visible, "none during the eclipse")
	main._apply_light(0.0, 0.0, 400.0, 1.0)
	check(ff.visible and ff.emitting, "they come out at night")
	var crowns: Array = ff.palms
	check(crowns.size() >= 6, "they gather under the palms: %d" % crowns.size())
	check(ff.spots.size() == ff.amount and ff.amount >= 30 and ff.amount <= 120, "a modest swarm: %d" % ff.amount)
	var low := true
	var near := true
	for p in ff.spots:
		low = low and p.y >= Fireflies.LOW and p.y <= Fireflies.HIGH
		var best := INF
		for c in crowns:
			best = minf(best, Vector2(p.x - c.x, p.z - c.z).length())
		near = near and best <= Fireflies.SPREAD + 0.01
	check(low, "they hover between knee and head height")
	check(near, "each one starts around a palm's foot")
	# Count separate blinks over a life: dark, lit, dark again.
	var blinks := 0
	var lit := false
	for i in 201:
		var a: float = ff.color_ramp.sample(i / 200.0).a
		if a > 0.5 and not lit:
			blinks += 1
		lit = a > 0.5
	check(blinks == 3, "three short blinks a life: %d" % blinks)
	check(ff.color_ramp.sample(0.0).a == 0.0 and ff.color_ramp.sample(1.0).a == 0.0, "they never pop in or out")
	var reach: float = ff.initial_velocity_max * ff.lifetime
	var covered := true
	for p in ff.spots:
		covered = covered and ff.visibility_aabb.grow(-reach * 0.99).has_point(p)
	check(covered, "culling box covers every spot plus a life of drift")
	check(ff.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "fireflies cast no shadows")
	main._apply_light(0.8, 0.0, 300.0, 0.0)
	check(not ff.visible and not ff.emitting, "gone again in daylight")
	main.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	print("%d firefly checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
