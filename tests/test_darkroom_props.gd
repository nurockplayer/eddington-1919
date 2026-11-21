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
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var props := get_nodes_in_group("darkroom_props")
	check(props.size() == 13, "13 darkroom props")
	for prefix in ["DrTray", "DrBottle", "DrPlateBox"]:
		var count := 0
		for prop in props:
			if prop.name.begins_with(prefix):
				count += 1
		check(count == {"DrTray": 3, "DrBottle": 4, "DrPlateBox": 2}[prefix], prefix + " count")
	for prop in props:
		var p: Vector3 = prop.global_position
		check(p.x >= 8.0 and p.x <= 12.0 and p.z >= 1.3 and p.z <= 4.7 and p.y >= 0.0 and p.y <= 1.1, str(prop.name) + " inside hut")
		check(not (p.x >= 10.0 and p.x <= 11.2 and p.z >= 3.7 and p.z <= 4.5), str(prop.name) + " clear of measuring table")
		check(prop.find_children("*", "StaticBody3D", true, false).is_empty(), str(prop.name) + " has no collider")
		for node in prop.find_children("*", "MeshInstance3D", true, false):
			var mesh_instance := node as MeshInstance3D
			for surface in mesh_instance.mesh.get_surface_count():
				var material := mesh_instance.get_active_material(surface) as BaseMaterial3D
				if material:
					check(material.albedo_color.v <= 0.82, str(prop.name) + " material brightness")
	check(game.world.plate_box_pos.is_equal_approx(Vector3(11.65, 1.18, 2.25)), "plate box position unchanged")
	check(game.world.measure_pos.is_equal_approx(Vector3(10.6, 0.82, 4.1)), "measure position unchanged")
	game.free()
	print("test_darkroom_props: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
