extends SceneTree

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
	var scene: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.set_process(false)
	var groups := get_nodes_in_group("far_ridges")
	check(groups.size() == 1, "one ridge group")
	var meshes: Array[Node] = []
	if groups.size() == 1:
		meshes = groups[0].find_children("*", "MeshInstance3D", true, false)
	check(meshes.size() == 3, "three ridge meshes")
	var names := []
	var triangles := 0
	var max_elevation := -INF
	var max_bearing := 0.0
	var open_max := -INF
	var sectors := []
	sectors.resize(36)
	sectors.fill(-INF)
	var min_distance := INF
	var tall_slender := true
	var short_slender := true
	var tall_peak := false
	var short_peak := false
	for mi in meshes:
		names.append(str(mi.name))
		check(mi.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF and mi.gi_mode == GeometryInstance3D.GI_MODE_DISABLED, "ridge lighting: " + str(mi.name))
		var faces: PackedVector3Array = mi.mesh.get_faces()
		triangles += faces.size() / 3
		for vertex in faces:
			var p: Vector3 = mi.global_transform * vertex
			var distance := Vector2(p.x, p.z).length()
			min_distance = minf(min_distance, distance)
			var bearing := rad_to_deg(atan2(p.x, -p.z))
			var elevation := rad_to_deg(atan2(p.y - 1.6, distance))
			if p.y > 130:
				tall_slender = tall_slender and absf(bearing - 140) <= 2.2
			if p.y > 112:
				short_slender = short_slender and (absf(bearing - 140) <= 5 or absf(bearing - 168) <= 1.8)
			tall_peak = tall_peak or p.y > 155
			short_peak = short_peak or (absf(bearing - 168) <= 1.8 and p.y > 122)
			if elevation > max_elevation:
				max_elevation = elevation
				max_bearing = bearing
			if bearing >= -60 and bearing <= -15:
				open_max = maxf(open_max, elevation)
			if mi.name == "principe_ridges_near":
				var sector := int(fposmod(bearing, 360.0) / 10.0)
				sectors[sector] = maxf(sectors[sector], elevation)
	for name in ["principe_ridges_near", "principe_ridges_mid", "principe_ridges_far"]:
		check(name in names, "mesh named " + name)
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		check(not (mi.mesh is SphereMesh and mi.mesh.radius >= 26), "no hemisphere: " + str(mi.name))
	check(min_distance >= 75, "ridge distance")
	check(max_elevation >= 15 and max_elevation <= 20 and max_bearing >= 130 and max_bearing <= 150, "tall tower skyline")
	check(open_max <= 5, "open sector")
	for i in 36:
		check(sectors[i] >= 1.2, "closed horizon sector %d" % i)
	check(triangles <= 30000, "triangle budget")
	check(tall_slender, "vertices above 130 m stay within 2.2 degrees of 140")
	check(short_slender, "vertices above 112 m stay within the tower bearings")
	check(tall_peak, "tall tower exceeds 155 m")
	check(short_peak, "short tower exceeds 122 m near 168")
	scene.phase = scene.Phase.PREP
	await scene._begin_totality()
	check(is_equal_approx(groups[0].scale.y, 0.006), "totality entry applies the authored low ridge profile")
	await scene._end_totality()
	check(is_equal_approx(groups[0].scale.y, 1.0), "third contact restores daylight ridge geometry")
	# Night must also restore full height when entered from a flattened profile.
	scene._apply_light(1.0, 1.0, 0.0, 0.0)
	await scene._begin_night()
	check(is_equal_approx(groups[0].scale.y, 1.0), "night restores full ridge geometry")
	scene.stop_all_audio()
	print("test_ridges: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
