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
			if OS.has_environment("HG_NOHAIR") and (nm.begins_with("Hair_") or nm.begins_with("Brow_")):
				mi.visible = false
			if nm.begins_with("HG_Body"):
				if OS.has_environment("HG_NONORMAL"):
					m.normal_enabled = false
				if OS.has_environment("HG_NOROUGH"):
					m.roughness_texture = null
				# a baked roughness map (T-zone, lips) is scaled by m.roughness
				m.roughness = 1.0 if m.roughness_texture else 0.55
				# HG's baked normal carries age lines a 23-year-old should not show
				m.normal_scale = 0.4
				m.subsurf_scatter_enabled = true
				m.subsurf_scatter_strength = 0.12
				m.subsurf_scatter_skin_mode = true
				m.rim_enabled = false
			elif nm.begins_with("Brow_"):
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.albedo_color = Color(0.09, 0.065, 0.05)
				m.roughness = 0.6
			elif nm.begins_with("Hair_"):
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.roughness = 0.42
				m.anisotropy_enabled = true
				m.anisotropy = 0.6
			elif nm.begins_with("Haircards") or nm.begins_with("HG_Haircap"):
				# c04: HG's own cards and haircap, baked colour/alpha/normal. Alpha hash
				# dithered the strands into dust over the face (c04 r3 shots); a scissor
				# with coverage AA keeps them solid, sorted and shadowed.
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
				m.alpha_scissor_threshold = 0.35
				m.alpha_antialiasing_mode = BaseMaterial3D.ALPHA_ANTIALIASING_ALPHA_TO_COVERAGE
				# the baked colour reads lighter and redder in Godot than HG's Blender render
				m.albedo_color = Color(0.55, 0.5, 0.47)
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.roughness = 0.46
				m.anisotropy_enabled = true
				m.anisotropy = 0.4
			elif nm.begins_with("HG_Lab_Coat") or nm.begins_with("HG_Sweater") or nm.begins_with("HG_Chinos") or nm.begins_with("HG_Pirate"):
				# c04: HG garments carry baked normal/roughness maps; cloth, so no rim
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.roughness = 1.0 if m.roughness_texture else 0.88
			elif nm.begins_with("HG_Leather"):
				m.roughness = 1.0 if m.roughness_texture else 0.55
			elif nm.begins_with("HG_Suit"):
				m.cull_mode = BaseMaterial3D.CULL_DISABLED
				m.roughness = 0.88
				m.rim_enabled = true
				m.rim = 0.25
				m.rim_tint = 0.8
			elif nm.begins_with("HG_Eyes") and m.resource_name.contains("Outer"):
				# cornea: exported opaque white (HG's transparent outer shader has
				# no glTF equivalent). Hide it; the wet highlight is a clearcoat on
				# the eyeball below (an additive cornea glowed white under ambient).
				m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				m.albedo_color = Color(1, 1, 1, 0.0)
			elif nm.begins_with("HG_Eyes"):
				m.roughness = 0.35
				m.clearcoat_enabled = true
				m.clearcoat = 0.5
				m.clearcoat_roughness = 0.2
			mi.set_surface_override_material(s, m)
	for c in n.get_children():
		tune_materials(c)
