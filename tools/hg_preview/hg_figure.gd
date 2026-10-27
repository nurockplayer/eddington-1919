extends RefCounted
## Runtime loader for the Human Generator prototype GLB (evaluation only; see
## docs/HG_PROTOTYPE.md). The GLB lives outside this public repo (HG licence),
## so it is read with GLTFDocument at runtime instead of being imported.


## Returns the generated scene root, or null if the file is missing or invalid.
static func load_figure(path: String) -> Node3D:
	if not FileAccess.file_exists(path):
		push_error("hg_figure: missing %s" % path)
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	if doc.append_from_file(path, state) != OK:
		push_error("hg_figure: GLTF load failed %s" % path)
		return null
	var root := doc.generate_scene(state) as Node3D
	tune_materials(root)
	return root


## glTF carries only base colour; restore what HG's Blender shaders did.
static func tune_materials(n: Node) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		for s in mi.mesh.get_surface_count():
			var m := mi.get_active_material(s) as StandardMaterial3D
			if m == null:
				continue
			m = m.duplicate()
			var nm := String(mi.name)
			if nm.begins_with("HG_Body"):
				m.roughness = 0.55
				m.subsurf_scatter_enabled = true
				m.subsurf_scatter_strength = 0.2
				m.subsurf_scatter_skin_mode = true
				m.rim_enabled = true
				m.rim = 0.12
				m.rim_tint = 0.6
			elif nm.begins_with("Brow_"):
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.albedo_color = Color(0.09, 0.065, 0.05)
				m.roughness = 0.6
			elif nm.begins_with("Hair_"):
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.roughness = 0.42
				m.anisotropy_enabled = true
				m.anisotropy = 0.6
			elif nm.begins_with("HG_Suit"):
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.roughness = 0.88
				m.rim_enabled = true
				m.rim = 0.25
				m.rim_tint = 0.8
			elif nm.begins_with("HG_Eyes") and m.resource_name.contains("Outer"):
				# cornea: exported opaque white (HG's transparent outer shader
				# has no glTF equivalent); make it a clear, wet highlight layer
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.albedo_color = Color(1, 1, 1, 0.0)
				m.roughness = 0.02
				m.metallic_specular = 1.0
			mi.set_surface_override_material(s, m)
	for c in n.get_children():
		tune_materials(c)
