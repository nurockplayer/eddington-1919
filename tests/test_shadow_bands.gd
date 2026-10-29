extends SceneTree
## Shadow bands: only in the thin-crescent moments around totality, never in
## totality itself, at night or under thick cloud.
const ShadowBands := preload("res://scripts/shadow_bands.gd")
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
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	for i in 4:
		await process_frame
	var sb = main.world.get("shadow_bands")
	check(sb != null and sb.get_parent() == main, "bands are built into the Príncipe scene")
	if sb == null:
		_done()
		return
	check(sb.position.distance_to(Vector3(main.world.station_pos.x, ShadowBands.LIFT, main.world.station_pos.z)) < 0.001, "bands lie on the ground at the station")
	check(ShadowBands.LIFT > 0.035, "bands sit above the trampled earth and puddles, not under them")
	var dens_clear := 1.0
	var clear_t := 0.0
	for t in range(-120, 1):
		var d: float = main.sim.cloud_over_sun(float(t))
		if d < dens_clear:
			dens_clear = d
			clear_t = float(t)
	# Early partial phase: a fat crescent, no bands.
	main._apply_light(0.62, 0.0, clear_t, 0.0)
	check(not sb.visible, "no bands while the crescent is wide")
	# The last moments before totality.
	main._apply_light(0.985, 0.4, clear_t, 0.0)
	check(sb.visible or dens_clear >= 0.8, "bands ripple on the thin crescent (clearest cloud %.2f)" % dens_clear)
	main._apply_light(1.0, 1.0, clear_t, 0.0)
	check(not sb.visible, "none in totality")
	main._apply_light(0.0, 0.0, 400.0, 1.0)
	check(not sb.visible, "none at night")
	check(ShadowBands.strength(0.02, 1.0) > 0.99, "full strength on the last sliver")
	check(ShadowBands.strength(0.2, 1.0) == 0.0, "nothing on a wide crescent")
	check(ShadowBands.strength(0.0, 1.0) == 0.0, "nothing with no crescent")
	check(ShadowBands.strength(0.02, 0.0) == 0.0, "thick cloud stops them")
	var sky_src := FileAccess.get_file_as_string("res://shaders/eclipse_sky.gdshader")
	check(sky_src.contains("float cloud_visibility = 1.0 - smoothstep(0.35, 0.80, dens);"), "same cloud cut as the sky")
	main.queue_free()
	_done()


func _done() -> void:
	print("%d shadow band checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
