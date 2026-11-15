extends SceneTree
## Picked albedo tiles on primitives and imported kit surfaces, beneath UV2 wear.
const World := preload("res://scripts/world_builder.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _path(m: BaseMaterial3D) -> String:
	return m.albedo_texture.resource_path if m.albedo_texture else ""


func _noise(m: BaseMaterial3D) -> bool:
	return m.detail_enabled and m.detail_albedo is NoiseTexture2D and m.detail_uv_layer == BaseMaterial3D.DETAIL_UV_2 and m.detail_blend_mode == BaseMaterial3D.BLEND_MODE_MUL and m.uv2_triplanar and m.uv2_world_triplanar and m.uv2_scale.is_equal_approx(Vector3.ONE * 0.3)


func _run() -> void:
	var root3d := Node3D.new()
	root.add_child(root3d)
	var wb = World.new(root3d)
	var teak: StandardMaterial3D = wb.mat(wb.P("teak"))
	check(_path(teak) == World.TILE_DIR + "teak.jpg", "palette teak picks its tile")
	check(teak.uv1_triplanar and teak.uv1_world_triplanar and teak.uv1_scale.is_equal_approx(Vector3.ONE / 0.9) and is_equal_approx(teak.uv1_triplanar_sharpness, 4.0), "teak has metre-scaled world triplanar projection")
	check(teak.albedo_color.is_equal_approx(Color.WHITE), "exact palette match becomes white")
	check(_noise(teak), "teak retains the UV2 noise detail")
	var dark: StandardMaterial3D = wb.mat(wb.P("teak").darkened(0.1))
	check(dark.albedo_texture == null and _noise(dark), "unnamed tinted colour has noise only")
	var named := StandardMaterial3D.new()
	named.resource_name = "E1919_brick.001"
	named.albedo_color = Color("985B45")
	wb.weather(named)
	check(_path(named) == World.TILE_DIR + "brick.jpg", "kit material suffix resolves to brick")
	var tinted := StandardMaterial3D.new()
	tinted.resource_name = "E1919_brick"
	tinted.albedo_color = wb.P("brick").darkened(0.2)
	wb.weather(tinted)
	check(_path(tinted) == World.TILE_DIR + "brick.jpg" and tinted.albedo_color.is_equal_approx(Color(0.8, 0.8, 0.8)), "named tinted brick retains its channel ratio")
	check(named.albedo_texture == tinted.albedo_texture, "loaded tile textures are shared")
	var evidence: StandardMaterial3D = wb.evidence_mat(wb.P("teak"))
	wb.weather(evidence, "teak")
	check(evidence.albedo_texture == null and not evidence.detail_enabled, "evidence stays clean")
	var metal := StandardMaterial3D.new()
	metal.metallic = 0.85
	metal.albedo_color = wb.P("teak")
	wb.weather(metal, "teak")
	check(metal.albedo_texture == null and not metal.detail_enabled, "metal stays clean")
	var glass := StandardMaterial3D.new()
	glass.resource_name = "E1919_plate_glass"
	glass.albedo_color = wb.P("teak")
	wb.weather(glass, "teak")
	check(glass.albedo_texture == null and not glass.detail_enabled, "plate glass stays clean")
	for id: String in World.TILES:
		var path: String = World.TILE_DIR + id + ".jpg"
		var tex := load(path) as Texture2D
		check(tex != null, "%s loads as Texture2D" % id)
		if tex != null:
			check(tex.get_image().has_mipmaps(), "%s has mipmaps" % id)
		var file := FileAccess.open(path, FileAccess.READ)
		check(file != null and file.get_length() < 1000000, "%s is under 1 MB" % id)
	wb.build()
	var roof_found := false
	var kit_found := false
	for node in root3d.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if mi.position.is_equal_approx(Vector3(10, 2.6, 3)) and mi.mesh is BoxMesh and mi.mesh.size.is_equal_approx(Vector3(4.6, 0.14, 4.0)):
			var roof := mi.material_override as BaseMaterial3D
			roof_found = _path(roof) == World.TILE_DIR + "iron_sheet.jpg" and roof.uv1_scale.is_equal_approx(Vector3.ONE / 0.6)
			check(_noise(roof), "darkroom roof retains UV2 noise")
		for i in mi.mesh.get_surface_count():
			var src := mi.mesh.surface_get_material(i) as BaseMaterial3D
			if src == null or src.resource_name not in ["E1919_teak", "E1919_pine"]:
				continue
			var painted := mi.get_active_material(i) as BaseMaterial3D
			if painted == null:
				continue
			kit_found = kit_found or _path(painted) == World.TILE_DIR + src.resource_name.trim_prefix("E1919_") + ".jpg"
			check(painted.resource_name == src.resource_name, "duplicate preserves kit material name")
	check(roof_found, "built darkroom roof picks iron_sheet at 0.6 metres")
	check(kit_found, "built production kit timber carries its picked tile")
	var source := ArrayMesh.new()
	source.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, BoxMesh.new().get_mesh_arrays())
	var pine := StandardMaterial3D.new()
	pine.resource_name = "E1919_pine"
	pine.albedo_color = wb.P("pine")
	source.surface_set_material(0, pine)
	var painted_mesh: Mesh = wb._weathered_mesh(source)
	var painted_pine := painted_mesh.surface_get_material(0) as BaseMaterial3D
	check(painted_pine.resource_name == pine.resource_name and _path(painted_pine) == World.TILE_DIR + "pine.jpg", "MultiMesh material duplicate preserves name and receives tile")
	check(pine.albedo_texture == null, "original imported material stays untouched")
	root3d.free()
	_check_no_grade()
	print("%d surface tile checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check_no_grade() -> void:
	var root3d := Node3D.new()
	root.add_child(root3d)
	var wb = World.new(root3d)
	wb.look = false
	for id: String in World.TILES:
		var m: StandardMaterial3D = wb.mat(wb.P("teak"), 0.85, 0.0, id)
		check(m.albedo_texture == null and not m.detail_enabled and m.albedo_color == wb.P("teak"), "no-grade keeps original material for explicit %s" % id)
	wb.build()
	for node in root3d.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var m := mi.get_active_material(i) as BaseMaterial3D
			if m != null:
				check(not _path(m).begins_with(World.TILE_DIR), "no-grade built surface has no painted tile")
		if mi.position.is_equal_approx(Vector3(10, 2.6, 3)) and mi.mesh is BoxMesh:
			var roof := mi.material_override as BaseMaterial3D
			check(roof.albedo_color == wb.P("iron").lightened(0.15), "no-grade roof keeps its original albedo")
	for node in root3d.find_children("*", "MultiMeshInstance3D", true, false):
		for i in node.multimesh.mesh.get_surface_count():
			var m := node.multimesh.mesh.surface_get_material(i) as BaseMaterial3D
			if m != null:
				check(not _path(m).begins_with(World.TILE_DIR), "no-grade MultiMesh has no painted tile")
	root3d.free()
