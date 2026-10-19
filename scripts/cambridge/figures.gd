extends RefCounted
## Cambridge-only 1917 people, built from a few shared-material meshes.
## Clothing and hair shapes below are RECONSTRUCTION, not documented portraits
## or costume records (art/BIBLE.md S4; docs/PROVENANCE.md).

const SKIN := Color(0.65, 0.49, 0.39)
const TROUSERS := Color(0.16, 0.16, 0.17)
const DARK_HAIR := Color(0.12, 0.115, 0.11)
const GREY_HAIR := Color(0.34, 0.34, 0.32)
const WAISTCOAT := Color(0.34, 0.29, 0.23)
const BRASS := Color(0.48, 0.39, 0.25)


## Returns a StaticBody3D compatible with WorldBuilder.npc(): same 1.8 m
## conversation collider, name tag, and interact_id/prompt metadata. `w` is the
## existing WorldBuilder instance so its material cache and ray interaction stay
## in use. Facing is -Z, matching the room's current character staging.
static func build(w, display_name: String, pos: Vector3, coat: Color, shirt: Color, id: String) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = "CambridgeFigure_" + id
	var cs := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.25
	capsule.height = 1.8
	cs.shape = capsule
	cs.position.y = 0.9
	body.add_child(cs)
	body.position = pos
	_build_clothes(body, id, coat, shirt)
	_add_name_tag(body, display_name, w)
	w.root.add_child(body)
	w.interactable(body, id, display_name)
	return body


static func _build_clothes(body: Node3D, id: String, coat: Color, shirt: Color) -> void:
	# Group the small parts by material; keep the tapered torso as one primitive.
	# Lapels are thin two-sided cloth, unlike the solid body meshes. These are deliberately broad readable forms.
	var coats: Array = []
	var trousers: Array = []
	var skin_parts: Array = []
	var shirts: Array = []
	var hair: Array = []
	var lapels: Array = []
	var details: Array = []
	var stoop := id == "mentor" or id == "ashby"
	var torso_transform := Transform3D(Basis.from_scale(Vector3(1, 1, 0.5)), Vector3(0, 1.14, 0))

	# Tapered frock coat: broad shoulders, fitted waist and slightly flared hem.
	# CylinderMesh has Godot-authored winding/normals; its eight-sided elliptical
	# cross-section avoids the custom SurfaceTool torso that disappeared in game.
	# Keep this one piece as a direct MeshInstance so it never passes through the
	# batched SurfaceTool normal-generation path.
	# Shirt front is a short chest panel; the full-height strip read like an exposed neck.
	shirts.append(_part(_box(Vector3(0.14, 0.25, 0.025)), Transform3D(Basis.IDENTITY, Vector3(0, 1.32, -0.174))))
	# Two lapels break the shirt front and read clearly at room distance.
	lapels.append(_part(_wedge(Vector3(-0.12, 1.47, -0.18), Vector3(-0.025, 1.38, -0.195), Vector3(-0.105, 1.23, -0.195), Vector3(-0.18, 1.40, -0.18)), Transform3D.IDENTITY))
	lapels.append(_part(_wedge(Vector3(0.12, 1.47, -0.18), Vector3(0.025, 1.38, -0.195), Vector3(0.105, 1.23, -0.195), Vector3(0.18, 1.40, -0.18)), Transform3D.IDENTITY))
	# Sleeves and visible cuffs/hands hang beside the coat rather than merging into it.
	for side in [-1.0, 1.0]:
		var sleeve := _box(Vector3(0.14, 0.52, 0.16))
		coats.append(_part(sleeve, Transform3D(Basis.from_euler(Vector3(0, 0, deg_to_rad(side * -3.0))), Vector3(side * 0.28, 1.15, 0))))
		shirts.append(_part(_box(Vector3(0.145, 0.065, 0.17)), Transform3D(Basis.IDENTITY, Vector3(side * 0.28, 0.865, 0))))
		skin_parts.append(_part(_sphere(0.075, 0.13), Transform3D(Basis.IDENTITY, Vector3(side * 0.28, 0.765, -0.008))))
		# Trouser legs are tapered and spaced enough to preserve the walking silhouette.
		trousers.append(_part(_frustum(0.105, 0.085, 0.77), Transform3D(Basis.IDENTITY, Vector3(side * 0.105, 0.39, 0.005))))
		trousers.append(_part(_box(Vector3(0.14, 0.09, 0.28)), Transform3D(Basis.IDENTITY, Vector3(side * 0.105, 0.055, -0.035))))

	# Neck, head and simple hair mass. Kit keeps the same neutral short silhouette.
	skin_parts.append(_part(_cylinder(0.085, 0.15), Transform3D(Basis.IDENTITY, Vector3(0, 1.56, 0))))
	skin_parts.append(_part(_sphere(0.13, 0.29), Transform3D(Basis.IDENTITY, Vector3(0, 1.69, -0.036))))
	skin_parts.append(_part(_sphere(0.026, 0.075), Transform3D(Basis.IDENTITY, Vector3(0, 1.68, -0.162))))
	var hair_color := GREY_HAIR if id == "mentor" or id == "ashby" else DARK_HAIR
	# A close-cropped mass follows the scalp and sits slightly behind the face,
	# avoiding the detached flat-cap shape of a small sphere perched on top.
	hair.append(_part(_sphere(0.135, 0.30), Transform3D(Basis.IDENTITY, Vector3(0, 1.72, -0.01))))
	for side in [-1.0, 1.0]:
		hair.append(_part(_sphere(0.027, 0.095), Transform3D(Basis.IDENTITY, Vector3(side * 0.118, 1.675, 0.002))))
		# Restrained brows and eyes: tiny dark shapes set into the upper face.
		hair.append(_part(_box(Vector3(0.043, 0.009, 0.009)), Transform3D(Basis.IDENTITY, Vector3(side * 0.047, 1.723, -0.165))))
		hair.append(_part(_sphere(0.011, 0.023), Transform3D(Basis.IDENTITY, Vector3(side * 0.047, 1.697, -0.17))))

	if id == "mentor" or id == "ashby":
		# A shallow overlay panel and buttons let the waistcoat read below the lapels.
		details.append(_part(_box(Vector3(0.26, 0.30, 0.012)), Transform3D(Basis.IDENTITY, Vector3(0, 1.08, -0.18))))
		for y in [1.03, 1.12, 1.21]:
			details.append(_part(_sphere(0.012, 0.025), Transform3D(Basis.IDENTITY, Vector3(0, y, -0.19))))
	if stoop:
		var pivot := Vector3(0, 1.08, 0)
		var rotation := Basis.from_euler(Vector3(deg_to_rad(6.0), 0, 0))
		var around_pivot := Transform3D(rotation, pivot - rotation * pivot)
		torso_transform = around_pivot * torso_transform
		for group in [coats, shirts, skin_parts, hair, details]:
			for part in group:
				part.transform = around_pivot * part.transform

	# Waistcoat stays a distinct value; chest, coat, trousers, skin and hair each
	# share one material-backed mesh, keeping figure draw calls modest.
	_emit_torso(body, _coat_mesh(), torso_transform, coat)
	_emit(body, coats, coat)
	_emit(body, lapels, coat.lightened(0.06), true)
	_emit(body, trousers, TROUSERS)
	_emit(body, skin_parts, SKIN)
	_emit(body, shirts, shirt)
	_emit(body, hair, hair_color)
	if not details.is_empty():
		_emit(body, details, WAISTCOAT)
	if id == "eddington":
		_add_spectacles(body)


static func _add_spectacles(body: Node3D) -> void:
	var wire := StandardMaterial3D.new()
	wire.albedo_color = BRASS
	wire.metallic = 0.42
	wire.roughness = 0.58
	for x in [-0.055, 0.055]:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.035
		ring.outer_radius = 0.043
		ring.rings = 8
		ring.ring_segments = 10
		var glass := MeshInstance3D.new()
		glass.mesh = ring
		glass.material_override = wire
		glass.position = Vector3(x, 1.69, -0.164)
		glass.rotation.x = deg_to_rad(90)
		body.add_child(glass)
	var bridge := MeshInstance3D.new()
	bridge.mesh = _box(Vector3(0.04, 0.012, 0.009))
	bridge.material_override = wire
	bridge.position = Vector3(0, 1.69, -0.169)
	body.add_child(bridge)


static func _add_name_tag(body: Node3D, display_name: String, w) -> void:
	var tag := Label3D.new()
	tag.text = display_name
	tag.font_size = 30
	tag.pixel_size = 0.0007
	tag.fixed_size = true
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.05, 0)
	tag.modulate = Color(1, 0.95, 0.8, 0.85)
	tag.outline_size = 8
	tag.visibility_range_end = 9.0 if w.look else 0.0
	tag.visibility_range_end_margin = 3.0
	tag.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	body.add_child(tag)


static func _emit(parent: Node3D, parts: Array, color: Color, two_sided := false) -> void:
	if parts.is_empty():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for part in parts:
		st.append_from(part.mesh, 0, part.transform)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	if two_sided:
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = mat
	parent.add_child(mi)


static func _emit_torso(parent: Node3D, mesh: Mesh, transform: Transform3D, color: Color) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.transform = transform
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.9
	mi.material_override = mat
	parent.add_child(mi)


static func _part(mesh: Mesh, transform: Transform3D) -> Dictionary:
	return {"mesh": mesh, "transform": transform}


static func _box(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _sphere(radius: float, height: float) -> SphereMesh:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 8
	return mesh


static func _cylinder(radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius * 0.92
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	return mesh


static func _frustum(bottom: float, top: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 8
	return mesh


static func _coat_mesh() -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.23
	mesh.bottom_radius = 0.29
	mesh.height = 0.71
	mesh.radial_segments = 8
	return mesh


static func _wedge(a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(a)
	st.add_vertex(c)
	st.add_vertex(b)
	st.add_vertex(a)
	st.add_vertex(d)
	st.add_vertex(c)
	st.generate_normals()
	return st.commit()


