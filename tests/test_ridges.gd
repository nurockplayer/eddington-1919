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
	var scene := load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
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
			if elevation > max_elevation:
				max_elevation = elevation
				max_bearing = bearing
			if bearing >= -60 and bearing <= -15:
				open_max = maxf(open_max, elevation)
			if mi.name == "ridge_near":
				var sector := int(fposmod(bearing, 360.0) / 10.0)
				sectors[sector] = maxf(sectors[sector], elevation)
	for name in ["ridge_near", "ridge_mid", "ridge_far"]:
		check(name in names, "mesh named " + name)
	for mi in scene.find_children("*", "MeshInstance3D", true, false):
		check(not (mi.mesh is SphereMesh and mi.mesh.radius >= 26), "no hemisphere: " + str(mi.name))
	check(min_distance >= 75, "ridge distance")
	check(max_elevation >= 15 and max_elevation <= 20 and max_bearing >= 130 and max_bearing <= 150, "tall tower skyline")
	check(open_max <= 5, "open sector")
	for i in 36:
		check(sectors[i] >= 1.2, "closed horizon sector %d" % i)
	check(triangles <= 30000, "triangle budget")
	print("test_ridges: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
