extends SceneTree
## Fireflies among the palms: hidden by day, blinking low around the palm feet
## on the night after the eclipse.
const Fireflies := preload("res://scripts/fireflies.gd")
const Settings := preload("res://scripts/settings.gd")
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
	check(ff is MultiMeshInstance3D, "the island has a swarm of pen marks")
	if not ff is MultiMeshInstance3D:
		_finish()
		return
	check(not ff.visible and not ff.is_processing(), "none by day")
	main._apply_light(0.985, 0.9, -5.0, 0.0)
	check(not ff.visible, "none during the eclipse")
	main._apply_light(0.0, 0.0, 400.0, 1.0)
	check(ff.visible and ff.is_processing(), "they come out at night")
	var crowns: Array = ff.palms
	check(crowns.size() >= 6, "they gather under the palms: %d" % crowns.size())
	check(ff.spots.size() == ff.multimesh.instance_count and ff.multimesh.instance_count >= 30 and ff.multimesh.instance_count <= 120, "a modest swarm: %d" % ff.multimesh.instance_count)
	var low := true
	var near := true
	for p in ff.spots:
		low = low and p.y >= Fireflies.LOW and p.y <= Fireflies.HIGH
		var best := INF
		for c in crowns:
			best = minf(best, Vector2(p.x - c.x, p.z - c.z).length())
		near = near and best <= Fireflies.SPREAD + 0.01
	check(low, "they hover between knee and head height")
	check(Fireflies.LOW - ff.DRIFT > 0.05, "drift never reaches the ground")
	check(near, "each one starts around a palm's foot")
	var stamp := ff.multimesh.mesh.material as ShaderMaterial
	check(stamp != null and stamp.shader.resource_path.ends_with("/firefly_mark.gdshader"), "the swarm draws pen marks")
	var reduced := Settings.reduced_motion
	Settings.reduced_motion = true
	ff._process(0.1)
	check(stamp.get_shader_parameter("age") == -1.0, "reduced motion holds the marks still")
	Settings.reduced_motion = false
	ff._process(0.1)
	check(stamp.get_shader_parameter("age") >= 0.1, "the asynchronous blink clock resumes")
	Settings.reduced_motion = reduced
	var covered := true
	for p in ff.spots:
		covered = covered and ff.custom_aabb.grow(-ff.DRIFT).has_point(p)
	check(covered, "culling box covers every spot plus drift")
	check(ff.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "fireflies cast no shadows")
	main._apply_light(0.8, 0.0, 300.0, 0.0)
	check(not ff.visible and not ff.is_processing(), "gone again in daylight")
	main.queue_free()
	await process_frame
	_finish()


func _finish() -> void:
	print("%d firefly checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
