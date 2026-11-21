extends SceneTree
## Painted vegetation on the real built camp, including the unchanged layout.
const World := preload("res://scripts/world_builder.gd")
const CARD_SHADER := "res://shaders/foliage_card.gdshader"
const FOLIAGE := "res://assets/textures/principe/foliage/"
var checks := 0
var failures := 0
var readback_skipped := 0
var readback_checked := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _card(material: Material) -> bool:
	return material is ShaderMaterial and material.shader.resource_path == CARD_SHADER


func _triangles(mesh: Mesh) -> int:
	var count := 0
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var indices = arrays[Mesh.ARRAY_INDEX]
		count += (indices.size() if indices != null and not indices.is_empty() else arrays[Mesh.ARRAY_VERTEX].size()) / 3
	return count


func _run() -> void:
	var camp := Node3D.new()
	root.add_child(camp)
	var wb = World.new(camp)
	wb.build()
	check(wb.palm_crowns.size() == 15, "15 palm crowns preserved")
	var variants := {}
	var frond_mesh: Mesh
	var frond_material: Material
	var dead := 0
	for palm in get_nodes_in_group("veg_palm"):
		for i in palm.get_child_count() - 1:
			var frond := palm.get_child(i + 1).get_child(0) as MeshInstance3D
			check(frond != null, "frond is a MeshInstance3D under its original pivot")
			if frond == null:
				continue
			frond_mesh = frond.mesh
			check(_card(frond.material_override), "frond uses foliage card shader")
			if not _card(frond.material_override):
				continue
			var m := frond.material_override as ShaderMaterial
			if frond_material == null:
				frond_material = m
				for entry in [["tex_v1", "coconut_frond-v1.png"], ["tex_v2", "coconut_frond-v2.png"], ["tex_v3", "coconut_frond_dry-v1.png"]]:
					var tex: Texture2D = m.get_shader_parameter(entry[0])
					check(tex != null and tex.resource_path == FOLIAGE + entry[1], "shared frond material contains " + entry[1])
			check(m == frond_material, "all fronds share one material")
			var pick: float = frond.get_instance_shader_parameter("pick")
			if i < 12:
				check(pick == 0.0 or pick == 1.0, "living frond picks a green cut-out")
				variants[pick] = true
			else:
				dead += 1
				check(pick == 2.0, "dead frond picks dry v1")
			check(is_zero_approx(m.get_shader_parameter("sway")), "PalmSway owns frond motion")
	check(variants.size() == 2 and dead > 0, "both green variants and dry fronds occur")
	_check_fold(frond_mesh)
	print("triangles frond: ", _triangles(frond_mesh))
	_check_shrubs(wb)
	var forest := camp.get_node_or_null("ForestEdge") as Node3D
	check(forest != null and forest.is_in_group("veg_forest_edge"), "ForestEdge has benchmark group")
	if forest != null:
		check(forest.get_child_count() == 2, "two forest loops")
		for loop_name in ["Front", "Back"]:
			_check_forest(forest.get_node(loop_name), 5.0 if loop_name == "Front" else 7.0)
	var second := Node3D.new()
	root.add_child(second)
	var wb2 = World.new(second)
	wb2.build()
	for loop_name in ["Front", "Back"]:
		var a: MeshInstance3D = camp.get_node("ForestEdge/" + loop_name)
		var b: MeshInstance3D = second.get_node("ForestEdge/" + loop_name)
		check(a.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == b.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], "deterministic forest vertices: " + loop_name)
	for group in ["veg_palm", "veg_shrub", "veg_forest_edge"]:
		for node in get_nodes_in_group(group):
			node.hide()
			for geometry in node.find_children("*", "GeometryInstance3D", true, false):
				check(not geometry.is_visible_in_tree(), "benchmark group hides descendant geometry")
			check(not node.is_visible_in_tree(), "benchmark group hides vegetation node")
			node.show()
	second.free()
	camp.free()
	if readback_skipped > 0:
		print("renderer readback skipped (headless dummy renderer): %d checks" % readback_skipped)
	else:
		print("renderer readback checked: %d checks" % readback_checked)
	print("%d vegetation card checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check_fold(mesh: Mesh) -> void:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	check(normals.size() == vertices.size(), "generated frond normals")
	var ribs := 0
	for i in vertices.size():
		if not is_equal_approx(uvs[i].y, 0.5):
			continue
		ribs += 1
		var edges := {}
		for j in vertices.size():
			if is_equal_approx(uvs[i].x, uvs[j].x) and (is_zero_approx(uvs[j].y) or is_equal_approx(uvs[j].y, 1.0)):
				edges[uvs[j].y] = true
				check(vertices[i].y > vertices[j].y and is_equal_approx(vertices[i].z, vertices[j].z), "rib above edge at same spine point")
		check(edges.size() == 2, "both folded edges exist at rib")
	check(ribs > 0, "frond has rib vertices")


func _check_shrubs(wb) -> void:
	var nodes := get_nodes_in_group("veg_shrub")
	check(nodes.size() == 2, "exactly two shrub MultiMeshes")
	var expected := {"shrub_cocoa_multi": 45, "banana_clump_multi": 21}
	var found := {}
	for node in nodes:
		check(node is MultiMeshInstance3D and expected.has(String(node.name)), "named shrub MultiMesh")
		if not node is MultiMeshInstance3D:
			continue
		found[String(node.name)] = true
		var mm: MultiMesh = node.multimesh
		check(mm.instance_count == expected.get(String(node.name), 0), "instance count: " + String(node.name))
		check(mm.use_custom_data, "custom instance data enabled")
		if DisplayServer.get_name() == "headless":
			readback_skipped += mm.instance_count
		else:
			for j in mm.instance_count:
				readback_checked += 1
				check(is_equal_approx(mm.get_instance_custom_data(j).r, float(j % 2)), "alternating texture variant")
		for surface in mm.mesh.get_surface_count():
			var m: Material = mm.mesh.surface_get_material(surface)
			var palette_material: Material = wb.mat(wb.P("teak_dark")) if String(node.name) == "shrub_cocoa_multi" else wb.mat(wb.P("foliage_light").darkened(0.25))
			check(_card(m) or m == palette_material, "surface uses card shader or palette mat()")
			if _card(m):
				check(m.get_shader_parameter("use_custom_variant"), "shrub material selects custom variant")
				for parameter in ["tex_v1", "tex_v2"]:
					var tex: Texture2D = m.get_shader_parameter(parameter)
					check(tex.resource_path.begins_with(FOLIAGE), "shrub uses installed painted cut-out")
		print("triangles %s: %d" % [node.name, _triangles(mm.mesh)])
	check(found.size() == 2, "both shrub kinds occur")


func _check_forest(loop: MeshInstance3D, top: float) -> void:
	check(loop.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "forest shadows off")
	check(_card(loop.material_override), "forest uses card shader")
	var arrays := loop.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var v_min := 1.0
	var v_max := 0.0
	var low_columns := 0
	for i in vertices.size():
		var p := vertices[i]
		check(Vector2(p.x, p.z).length() >= 46.0 and absf(p.x) <= 57.5 and absf(p.z) <= 57.5, "forest outside clearing, within rounded square")
		var inward := Vector3(-p.x, 0, -p.z).normalized()
		# Mesh normals are octahedrally encoded and quantized by Godot.
		check(normals[i].distance_to((inward + Vector3.UP).normalized()) < 0.0002, "forest normal faces inward and up")
		var bearing := rad_to_deg(atan2(p.x, -p.z))
		if is_equal_approx(uvs[i].y, 0.02) and bearing >= -50.0 and bearing <= -25.0:
			low_columns += 1
			check(p.y <= 0.45 * top + 0.1, "house/Sun sector lowered without squashing")
		v_min = minf(v_min, uvs[i].y)
		v_max = maxf(v_max, uvs[i].y)
	check(low_columns > 0, "forest samples the low sector")
	# The top edge sits just inside the texture: at v = 0 the repeating sampler filters the opaque bottom row in.
	check(is_equal_approx(v_min, 0.02) and is_equal_approx(v_max, 0.67), "forest UV crops bottom third, top edge off the wrap")
	print("triangles ForestEdge/%s: %d" % [loop.name, _triangles(loop.mesh)])
