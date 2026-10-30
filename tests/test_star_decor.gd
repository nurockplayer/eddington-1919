extends SceneTree
## The study's celestial globe, orrery and Taurus chart: placed, textured, decoration only.
const Room := preload("res://scripts/cambridge/room_builder.gd")
const StarDecor := preload("res://scripts/cambridge/star_decor.gd")
const C17 := preload("res://scripts/cambridge/content_1917.gd")
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
	var talk := C17.examine("orrery")
	check(talk.size() == 3 and str(talk[1].t).contains("43"), "the orrery tells of Mercury's 43″")
	for departure in [false, true]:
		var room := Node3D.new()
		root.add_child(room)
		var world := Room.build(room, departure)
		var globe: Node3D = world.globe
		var chart: Node3D = world.chart
		check(globe.name == "CelestialGlobe" and chart.name == "TaurusChart", "both decorations are built")
		# Issue #37 loop 1: the orrery is a hotspot in the 1917 study only.
		var hot = world.targets.get("orrery")
		check((hot != null) != departure, "orrery hotspot only in the 1917 study (departure=%s)" % departure)
		if hot != null:
			check(hot.distance_to(world.orrery.position) < 0.2, "hotspot sits on the orrery")
		check(is_equal_approx(globe.global_position.y, 2.185), "globe stands on the bookcase top board")
		var sky := globe.find_child("Sky", true, false) as MeshInstance3D
		var sky_tex := (sky.material_override as StandardMaterial3D).albedo_texture
		check(sky_tex != null and sky_tex.get_width() == 512, "globe carries its star map")
		var paper := chart.find_child("Paper", true, false) as MeshInstance3D
		var normal := paper.global_transform.basis.z
		check(normal.dot(Vector3.LEFT) > 0.99, "chart faces into the room from the east wall")
		var frame_east := -INF
		for mi in chart.find_children("*", "MeshInstance3D", true, false):
			var box: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
			frame_east = maxf(frame_east, box.end.x)
		check(frame_east < 4.3275, "whole chart and frame sit in front of the plaster: %.4f" % frame_east)
		check(StarDecor._globe_uv(68.98, 16.51).x > StarDecor._globe_uv(56.87, 24.11).x, "globe reads RA increasing to the right, as seen from outside")
		var paper_tex := (paper.material_override as StandardMaterial3D).albedo_texture
		var img := paper_tex.get_image()
		var sun := StarDecor._chart_xy(StarDecor.SUN_1919.x, StarDecor.SUN_1919.y)
		var aldebaran := StarDecor._chart_xy(68.98, 16.51)
		check(img.get_pixelv(aldebaran).v < 0.4, "Aldebaran is inked on the chart")
		check(img.get_pixelv(sun + Vector2(15, 0)).r > img.get_pixelv(sun + Vector2(15, 0)).b + 0.2, "1919 Sun position is ringed")
		var orrery: Node3D = world.orrery
		check(is_equal_approx(orrery.global_position.y, 2.185), "orrery stands on the bookcase top board")
		# Whole sweep stays in the front bay: clear of the top-row books and the globe.
		var clear := true
		for t in [0.0, 3.0, 11.0, 29.0]:
			StarDecor.turn_orrery(orrery, t)
			for mi in orrery.find_children("*", "MeshInstance3D", true, false):
				var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
				clear = clear and b.position.z > -1.245 and b.end.z < -0.97 and b.position.x > 3.31 and b.end.x < 3.99 and b.position.y >= 2.184
		check(clear, "every arm sweeps between the books and the globe")
		var arms: Array = orrery.get_meta("arms")
		var start: Array = []
		StarDecor.turn_orrery(orrery, 0.0)
		for arm in arms:
			start.append(arm.rotation.y)
		check(absf(wrapf(start[0] - start[2], -PI, PI)) > 0.5 and absf(wrapf(start[3] - start[2], -PI, PI)) > 0.5, "planets start spread out, not in a line")
		StarDecor.turn_orrery(orrery, 4.0)
		var turned: Array = []
		for i in arms.size():
			turned.append(arms[i].rotation.y - start[i])
		check(arms.size() == 4 and is_equal_approx(turned[0] / turned[2], 1.0 / 0.241) and is_equal_approx(turned[3] / turned[2], 1.0 / 1.881),
			"arms keep the real period ratios: %s" % [turned])
		check(is_equal_approx(orrery.get_meta("moon_arm").rotation.y, TAU * 4.0 / StarDecor.ORRERY_YEAR * 12.37), "the Moon laps the Earth 12.37 times a year")
		for node in [globe, chart, orrery]:
			check(node.find_children("*", "CollisionObject3D", true, false).is_empty(), "decoration adds no colliders")
		room.free()
	print("%d star decor checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
