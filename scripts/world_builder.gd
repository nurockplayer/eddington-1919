extends RefCounted
## Builds the Roça Sundy observing site.
## RECONSTRUCTION: no photographs of the Príncipe station in situ are known; the
## layout (sun-shelter over a horizontal tube fed by a coelostat, a darkroom hut,
## the plantation house) is a plausible stage, not a documented plan.

const Palette := preload("res://scripts/palette.gd")
const PalmSway := preload("res://scripts/palm_sway.gd")
const SafelightGlass := preload("res://scripts/safelight_glass.gd")
const Look := preload("res://scripts/look.gd")
const Settings := preload("res://scripts/settings.gd")
const Fonts := preload("res://scripts/fonts.gd")
const MODELS := "res://assets/models/"
const FOLIAGE := "res://assets/textures/principe/foliage/"
const FoliageCard := preload("res://shaders/foliage_card.gdshader")

var root: Node3D
var _mats := {}
## r05 art pass (BIBLE §3a). main.gd sets false for --no-grade, so that flag
## gives a complete before/after: environment look AND these material changes.
var look := true
var palm_crowns: Array[Vector3] = []  # crown centres, for the pinhole crescents
var palm_sway: Node  # moves every frond; built on the first palm


func _init(p_root: Node3D) -> void:
	root = p_root


## Palette colour by swatch name (art/palette.toml → scripts/palette.gd).
func P(key: String) -> Color:
	return Palette.C[key]


## Imported production model (art/PIPELINE.md), or null so the caller can fall
## back to primitives. Models face +Z with the origin at bottom-centre.
func model(id: String, pos: Vector3, rot_y_deg := 0.0, scale := 1.0) -> Node3D:
	var path := MODELS + id + ".glb"
	if not ResourceLoader.exists(path):
		return null
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	inst.position = pos
	inst.rotation.y = deg_to_rad(rot_y_deg)
	inst.scale = Vector3.ONE * scale
	root.add_child(inst)
	weather_model(inst)
	return inst


## Instanced copies of an imported production model: one MultiMeshInstance3D per
## mesh in the model, with an instance per transform. Returns them (empty if the
## model is missing, so the caller can fall back to primitives).
func multimesh(id: String, xforms: Array, group := "") -> Array:
	var path := MODELS + id + ".glb"
	var out := []
	if xforms.is_empty() or not ResourceLoader.exists(path):
		return out
	var scene: Node = (load(path) as PackedScene).instantiate()
	for node in scene.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		var local := Transform3D.IDENTITY  # the mesh's transform relative to the model root
		var n: Node = mi
		while n != scene:
			local = (n as Node3D).transform * local
			n = n.get_parent()
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = _weathered_mesh(mi.mesh)
		mm.instance_count = xforms.size()
		for i in xforms.size():
			mm.set_instance_transform(i, xforms[i] * local)
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "%s_multi" % id
		mmi.multimesh = mm
		if group:
			mmi.add_to_group(group)
		root.add_child(mmi)
		out.append(mmi)
	scene.free()
	return out


## Invisible solid collider (pairs with an imported model's visual mesh).
func collider(size: Vector3, pos: Vector3, rot_y_deg := 0.0) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	body.rotation.y = deg_to_rad(rot_y_deg)
	root.add_child(body)
	return body


## Invisible solid cylinder collider (same shape as cyl(..., collide = true)).
func cyl_collider(radius: float, height: float, pos: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = radius
	sh.height = height
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	root.add_child(body)
	return body


func mat(color: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [color.to_html(), rough, metal]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rough
		m.metallic = metal
		weather(m)
		_mats[key] = m
	return _mats[key]


## Unweathered material for evidence surfaces (measuring sheet, plates).
func evidence_mat(color: Color, rough := 0.85) -> StandardMaterial3D:
	var key := "evidence|%s|%s" % [color.to_html(), rough]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rough
		m.set_meta("evidence", true)
		_mats[key] = m
	return _mats[key]


var _weather_tex: NoiseTexture2D
var _weathered := {}   # original imported material → weathered copy (keeps instancing)


## r05 anti-toy layer (BIBLE §3): a world-space grime/wear multiply on every
## non-metal, non-evidence surface, so large flat palette fills read as worn
## timber, plaster and canvas. No authored textures; one shared noise texture.
func weather(m: BaseMaterial3D) -> void:
	# Metals keep clean reflections; evidence stays clean (BIBLE S1). Evidence is
	# marked explicitly (evidence_mat(), palette role "evidence"), not inferred from
	# brightness: a brightness cutoff also skipped whitewash and canvas (PR #6 review).
	if not look or m.metallic > 0.5 or m.has_meta("evidence") or m.resource_name.begins_with("E1919_plate_glass"):
		return
	if _weather_tex == null:
		# try4 (0.06 freq, 5 octaves, 0.70–1.04) read as speckled camouflage: keep it broad and soft.
		_weather_tex = _noise_tex(0.02, 3, [Color(0.82, 0.80, 0.78), Color(0.95, 0.94, 0.93), Color(1.02, 1.02, 1.01)])
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_albedo = _weather_tex
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.uv2_triplanar = true
	m.uv2_world_triplanar = true
	m.uv2_scale = Vector3(0.3, 0.3, 0.3)


## Mesh copy whose surface materials are the shared weathered copies (for
## MultiMesh, which cannot take per-surface overrides). Arrays stay shared.
func _weathered_mesh(src: Mesh) -> Mesh:
	if not look:
		return src
	var m := src.duplicate() as Mesh
	for i in m.get_surface_count():
		var mat_i := m.surface_get_material(i) as BaseMaterial3D
		if mat_i == null:
			continue
		if not _weathered.has(mat_i):
			var w := mat_i.duplicate() as BaseMaterial3D
			weather(w)
			_weathered[mat_i] = w
		(m as ArrayMesh).surface_set_material(i, _weathered[mat_i])
	return m


## Apply weather() to an imported model's materials (shared copies per source material).
func weather_model(n: Node) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		for i in mesh.get_surface_count():
			var src := mesh.surface_get_material(i) as BaseMaterial3D
			if src == null:
				continue
			if not _weathered.has(src):
				var w := src.duplicate() as BaseMaterial3D
				weather(w)
				_weathered[src] = w
			mi.set_surface_override_material(i, _weathered[src])


## Night dress keeps a dim coat with a lit edge under the existing lamps.
static func night_dress(n: Node3D, heading: float, offset: Vector3) -> void:
	var figure := n.get_node_or_null("figure") as Node3D
	if figure == null:
		return  # primitive fallback
	figure.rotation_degrees.y = heading - n.rotation_degrees.y
	figure.position = n.basis.inverse() * offset
	var collision := n.get_child(0) as CollisionShape3D
	collision.position = figure.position + Vector3.UP * 0.9
	var pose := figure.find_child("WorkingPose", true, false) as WorkingPose
	pose.work_yaw = figure.rotation.y
	if n.get_meta("interact_id") == "eddington":
		pose.set_work_pose(EDDINGTON_NIGHT_POSE)
	_tone_linen(figure, Look.NIGHT_LINEN_DIM, true)


static func _tone_linen(n: Node3D, value: float, night: bool) -> void:
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		if not night:
			mi.mesh = mi.mesh.duplicate()
		var mesh: Mesh = mi.mesh
		for i in mesh.get_surface_count():
			var src := mesh.surface_get_material(i) as BaseMaterial3D
			if src == null or src.resource_name != "E1919_linen":
				continue
			var cloth := src.duplicate() as BaseMaterial3D
			cloth.albedo_color = Color(src.albedo_color.r * value, src.albedo_color.g * value, src.albedo_color.b * value, src.albedo_color.a)
			cloth.rim_enabled = night
			cloth.rim = 0.4
			cloth.rim_tint = 0.0
			if night:
				mi.set_surface_override_material(i, cloth)
			else:
				mesh.surface_set_material(i, cloth)


func box(size: Vector3, pos: Vector3, color: Color, parent: Node3D = null, collide := true, rot := Vector3.ZERO) -> Node3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat(color)
	var holder: Node3D = mi
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		body.add_child(cs)
		body.add_child(mi)
		holder = body
	holder.position = pos
	holder.rotation = rot
	(parent if parent else root).add_child(holder)
	return holder


func cyl(radius: float, height: float, pos: Vector3, color: Color, parent: Node3D = null, collide := false, rot := Vector3.ZERO, top := -1.0) -> Node3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.bottom_radius = radius
	cm.top_radius = radius if top < 0.0 else top
	cm.height = height
	mi.mesh = cm
	mi.material_override = mat(color)
	var holder: Node3D = mi
	if collide:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = radius
		sh.height = height
		cs.shape = sh
		body.add_child(cs)
		body.add_child(mi)
		holder = body
	holder.position = pos
	holder.rotation = rot
	(parent if parent else root).add_child(holder)
	return holder


func interactable(node: Node3D, id: String, prompt: String) -> Node3D:
	node.set_meta("interact_id", id)
	node.set_meta("prompt", prompt)
	return node


## Invisible collider used purely as an interaction target.
func hotspot(size: Vector3, pos: Vector3, id: String, prompt: String) -> Node3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	body.add_child(cs)
	body.position = pos
	body.collision_layer = 2  # not solid for the player (layer 1), still hit by the ray
	root.add_child(body)
	return interactable(body, id, prompt)


func build() -> Dictionary:
	var out := {}
	_ground()
	_sea_and_hills()
	out.merge(_shelter_and_instrument())
	out.merge(_darkroom())
	_plantation_house()
	_vegetation()
	_forest_edge()
	out.merge(_props())
	_bounds()
	randomize()  # vegetation reseeded the global RNG; don't leak that into "new sky" restarts
	out.eddington = npc(L.t("Eddington"), Vector3(-1.1, 0, -0.9), Color(0.16, 0.15, 0.16), Color(0.85, 0.83, 0.78), "eddington")
	out.cottingham = npc(L.t("Cottingham"), Vector3(1.35, 0, -6.1), Color(0.42, 0.36, 0.28), Color(0.88, 0.86, 0.8), "cottingham")
	out.cottingham.rotation.y = deg_to_rad(-60)
	return out


const ENGRAVING_SURFACE := preload("res://shaders/engraving_surface.gdshader")
const PILOT_MATERIALS := "engraving_pilot_materials"
const EARTH := Color("e2d1b3")
const LAND := Color("efe6d2")
enum Swatch { PAPER, TIMBER, CANVAS, DENSE, TELESCOPE }
var engraving_pilot := false
var _pilot_materials := {}


func _pilot_surface(mesh: MeshInstance3D, surface: int, swatch: int, stock: Color,
		earth := false, daylight_stock := Color.WHITE, daylight_pitch := 0.0) -> void:
	if not engraving_pilot:
		return
	var key := [swatch, stock, earth, daylight_stock, daylight_pitch]
	if not _pilot_materials.has(key):
		var material := ShaderMaterial.new()
		material.shader = ENGRAVING_SURFACE
		material.set_shader_parameter("swatch", swatch)
		material.set_shader_parameter("stock", stock)
		material.set_shader_parameter("earth", earth)
		material.set_shader_parameter("daylight_stock", daylight_stock)
		material.set_shader_parameter("daylight_pitch", daylight_pitch)
		_pilot_materials[key] = material
	var original := mesh.material_override if surface < 0 else mesh.get_surface_override_material(surface)
	var materials: Array = mesh.get_meta(PILOT_MATERIALS, [])
	materials.append([surface, original, _pilot_materials[key]])
	mesh.set_meta(PILOT_MATERIALS, materials)


static func print_pilot(source: MeshInstance3D, target: MeshInstance3D, day: bool) -> void:
	for entry in source.get_meta(PILOT_MATERIALS):
		var material: Material = entry[2] if day else entry[1]
		if entry[0] < 0:
			target.material_override = material
		else:
			target.set_surface_override_material(entry[0], material)


func _pilot_model(node: Node3D, swatches: Dictionary) -> void:
	if not engraving_pilot:
		return
	for mi: MeshInstance3D in node.find_children("*", "MeshInstance3D", true, false):
		for i in mi.mesh.get_surface_count():
			var name_ := mi.mesh.surface_get_material(i).resource_name.trim_prefix("E1919_")
			if swatches.has(name_):
				var swatch: int = swatches[name_]
				var stock := EARTH if swatch == Swatch.TIMBER or name_ == "brick" else Color("efe6d2")
				_pilot_surface(mi, i, swatch, stock)


## Invisible walls so the player cannot walk off the island.
func _bounds() -> void:
	for w in [[Vector3(0, 2, -42), Vector3(90, 4, 1)], [Vector3(0, 2, 42), Vector3(90, 4, 1)], [Vector3(-42, 2, 0), Vector3(1, 4, 90)], [Vector3(42, 2, 0), Vector3(1, 4, 90)]]:
		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = w[1]
		cs.shape = sh
		body.add_child(cs)
		body.position = w[0]
		root.add_child(body)


func _ground() -> void:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(140, 1, 140)
	cs.shape = sh
	cs.position.y = -0.5
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(140, 140)
	pm.subdivide_width = 60
	pm.subdivide_depth = 60
	mi.mesh = pm
	# r05: world-space macro patches (albedo) + fine breakup (detail), so the
	# ground reads as a worn, rain-soaked clearing rather than a blurred carpet.
	mi.material_override = _ground_material() if look else _ground_material_v04()
	_pilot_surface(mi, -1, Swatch.PAPER, LAND, true)
	body.add_child(mi)
	root.add_child(body)
	_paths()


func _ground_material_v04() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _noise_tex(0.02, 5, [P("foliage_deep").darkened(0.15), P("foliage_light").darkened(0.1)])
	m.uv1_scale = Vector3(18, 18, 1)
	m.roughness = 0.95
	return m


func _ground_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = _noise_tex(0.012, 4, [P("foliage_deep").darkened(0.3), P("foliage_deep"), P("foliage_light").darkened(0.15)])
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.035, 0.035, 0.035)
	m.detail_enabled = true
	m.detail_blend_mode = BaseMaterial3D.BLEND_MODE_MUL
	m.detail_albedo = _noise_tex(0.09, 3, [Color(0.78, 0.78, 0.78), Color(1.08, 1.08, 1.08)])
	m.detail_uv_layer = BaseMaterial3D.DETAIL_UV_2
	m.uv2_triplanar = true
	m.uv2_world_triplanar = true
	m.uv2_scale = Vector3(0.45, 0.45, 0.45)
	m.roughness = 0.92
	return m


func _paths() -> void:
	# Trampled red earth around the instruments and paths, wet after the storm
	# (HISTORICAL_RECORD: rain ~10:00–11:30).
	var dirt_mat := StandardMaterial3D.new()
	# Broad, low-contrast blotches only (try2's finer noise read as pink cobbles);
	# the wetness lives in roughness, which picks up the overcast sky.
	dirt_mat.albedo_texture = _noise_tex(0.012, 2, [P("laterite_wet").darkened(0.18), P("laterite_wet").darkened(0.06), P("laterite_wet")])
	dirt_mat.uv1_triplanar = true
	dirt_mat.uv1_world_triplanar = true
	dirt_mat.uv1_scale = Vector3(0.1, 0.1, 0.1)
	dirt_mat.roughness = 0.75
	dirt_mat.roughness_texture = _noise_tex(0.02, 2, [Color(0.3, 0.3, 0.3), Color(1.0, 1.0, 1.0)])
	for d in [[Vector3(7.5, 0.02, 9.5), Vector3(0, 0.01, -3.6), 0.0], [Vector3(10, 0.02, 1.6), Vector3(4.5, 0.012, 1.8), -12.0], [Vector3(1.6, 0.02, 16), Vector3(-6, 0.012, -10), 35.0]]:
		var path := box(d[0], d[1], P("laterite_wet"), null, false, Vector3(0, deg_to_rad(d[2]), 0))
		if look:
			(path as MeshInstance3D).material_override = dirt_mat
		_pilot_surface(path as MeshInstance3D, -1, Swatch.PAPER, EARTH, true)
	# Preserve the random sequence used by the remaining scene.
	randf_range(0.4, 0.9)
	for p in [Vector3(-2.8, 0.03, -6.8), Vector3(5.2, 0.03, 2.4), Vector3(0.6, 0.03, 3.0)]:
		var puddle := cyl(randf_range(0.4, 0.9), 0.01, p, Color(0.16, 0.17, 0.2))
		(puddle as MeshInstance3D).material_override = mat(Color(0.12, 0.14, 0.18), 0.05, 0.3)


## Seamless noise texture through a colour ramp (evenly spaced stops).
func _noise_tex(freq: float, octaves: int, stops: Array) -> NoiseTexture2D:
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = freq
	n.fractal_octaves = octaves
	tex.noise = n
	var offs := PackedFloat32Array()
	var cols := PackedColorArray()
	for i in stops.size():
		offs.append(float(i) / maxf(stops.size() - 1, 1))
		cols.append(stops[i])
	var g := Gradient.new()
	g.offsets = offs
	g.colors = cols
	tex.color_ramp = g
	return tex


func _sea_and_hills() -> void:
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(1400, 1400)
	sea.mesh = pm
	sea.position.y = -0.4
	sea.material_override = mat(P("sea_slate"), 0.12, 0.1)
	root.add_child(sea)
	var ridges := model("principe_ridges", Vector3.ZERO)
	if ridges:
		ridges.name = "FarRidges"
		ridges.add_to_group("far_ridges")
		for mi in ridges.find_children("*", "MeshInstance3D", true, false):
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
		for i in 5:
			randf()  # the hemispheres drew five values: keep the global RNG stream as it was
		return
	var green := P("hill_far")
	for h in [[Vector3(-60, -6, -70), 30.0], [Vector3(25, -10, -90), 40.0], [Vector3(-95, -4, 10), 26.0], [Vector3(70, -8, -40), 30.0], [Vector3(-30, -12, -120), 50.0]]:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = h[1]
		sm.height = h[1] * 1.3
		mi.mesh = sm
		mi.position = h[0]
		mi.material_override = mat(green.darkened(randf() * 0.2))
		root.add_child(mi)


func _shelter_and_instrument() -> Dictionary:
	var out := {}
	var wood := P("teak")
	var thatch := P("canvas")
	# Sun-shelter over the horizontal tube. Canvas roof: rolled back before totality
	# so the Sun can be watched (main.gd hides `roof`).
	var roof := Node3D.new()
	root.add_child(roof)
	out.roof = roof
	var shelter := model("sun_shelter", Vector3(0, 0, -3.75))
	if shelter:
		_pilot_model(shelter, {"canvas": Swatch.CANVAS})
		# Production model (art/assets.toml: sun_shelter). The canvas moves under `roof`
		# so the game's existing roof toggle hides it; the rolled canvas on the rear
		# beam shows exactly while the roof is hidden.
		var canvas: Node3D = shelter.find_child("sun_shelter_roof", true, false)
		var roll: Node3D = shelter.find_child("sun_shelter_roll", true, false)
		if canvas:  # re-home under `roof` (at the origin), keeping its placement
			var xf := shelter.transform * canvas.transform
			canvas.get_parent().remove_child(canvas)
			roof.add_child(canvas)
			canvas.transform = xf
		if roll:
			roll.visible = not roof.visible
			roof.visibility_changed.connect(func(): roll.visible = not roof.visible)
		for x in [-2.3, 2.3]:
			for z in [-0.6, -6.9]:
				cyl_collider(0.07, 2.9, Vector3(x, 1.45, z))
	else:
		for x in [-2.3, 2.3]:
			for z in [-0.6, -6.9]:
				cyl(0.07, 2.9, Vector3(x, 1.45, z), wood, null, true)
		box(Vector3(5.2, 0.12, 7.0), Vector3(0, 2.95, -3.75), thatch, roof, false, Vector3(deg_to_rad(4), 0, 0))
		box(Vector3(5.4, 0.35, 0.1), Vector3(0, 2.75, -0.25), thatch.darkened(0.2), roof, false)
		box(Vector3(5.2, 0.3, 0.3), Vector3(0, 2.95, -7.1), thatch.darkened(0.25), null, false)
	# Coelostat on its pier (the mirror turns with clockwork to follow the Sun).
	var drive: Node3D
	var coelostat := model("coelostat", Vector3(0, 0, -6.6))
	if coelostat:
		_pilot_model(coelostat, {
			"brick": Swatch.PAPER, "stone": Swatch.PAPER, "mirror": Swatch.PAPER,
			"iron": Swatch.DENSE, "brass": Swatch.DENSE, "teak_dark": Swatch.TIMBER,
		})
		# Production model (art/assets.toml: coelostat). Colliders stay simple boxes.
		collider(Vector3(1.0, 1.06, 1.0), Vector3(0, 0.53, -6.6))
		# The drive housing stays solid AND interactable, like the old primitive box.
		drive = interactable(collider(Vector3(0.42, 0.36, 0.34), Vector3(0.62, 0.92, -6.6)), "drive", L.t("時鐘驅動"))
	else:
		var brick := P("brick")
		box(Vector3(1.0, 1.05, 1.0), Vector3(0, 0.525, -6.6), brick)
		cyl(0.08, 0.35, Vector3(0, 1.22, -6.6), P("iron"))
		var mirror := cyl(0.24, 0.05, Vector3(0, 1.4, -6.6), P("mirror"), null, false, Vector3(deg_to_rad(62), 0, deg_to_rad(12)))
		(mirror as MeshInstance3D).material_override = mat(P("mirror"), 0.05, 0.95)
		cyl(0.26, 0.07, Vector3(0, 1.4, -6.6), P("brass"), null, false, Vector3(deg_to_rad(62), 0, deg_to_rad(12)), 0.26)
		# Clock-drive box with winding crank.
		drive = box(Vector3(0.42, 0.36, 0.34), Vector3(0.62, 0.92, -6.6), P("teak_dark"))
		box(Vector3(0.05, 0.05, 0.2), Vector3(0.86, 0.95, -6.6), P("brass"), null, false)
		cyl(0.05, 0.6, Vector3(0.6, 0.45, -6.6), P("iron"))  # weight chain housing
		interactable(drive, "drive", L.t("時鐘驅動"))
	out.drive_pos = Vector3(0.62, 0.92, -6.6)
	# Horizontal tube (lens near the coelostat, plate end toward the shelter front).
	var carrier: Node3D
	var telescope := model("horizontal_tube", Vector3(0, 0, -3.75))
	if telescope:
		_pilot_model(telescope, {"iron": Swatch.TELESCOPE, "brass": Swatch.TELESCOPE, "ebonite": Swatch.TELESCOPE, "teak_dark": Swatch.TELESCOPE})
		# Production model (art/assets.toml: horizontal_tube); the same box colliders.
		collider(Vector3(0.46, 0.46, 3.5), Vector3(0, 1.35, -3.75))
		for z in [-5.0, -2.5]:
			collider(Vector3(0.7, 1.12, 0.12), Vector3(0, 0.56, z))
		carrier = collider(Vector3(0.6, 0.6, 0.18), Vector3(0, 1.35, -1.92))
	else:
		box(Vector3(0.46, 0.46, 3.5), Vector3(0, 1.35, -3.75), P("iron"))
		cyl(0.25, 0.14, Vector3(0, 1.35, -5.55), P("brass"), null, false, Vector3(deg_to_rad(90), 0, 0))
		for z in [-5.0, -2.5]:
			box(Vector3(0.7, 1.12, 0.12), Vector3(0, 0.56, z), wood)
		carrier = box(Vector3(0.6, 0.6, 0.18), Vector3(0, 1.35, -1.92), P("teak_dark"))
	# Plate carrier at the eye end.
	interactable(carrier, "station", L.t("底片架"))
	out.station_look = Vector3(0, 1.35, -1.92)
	out.station_pos = Vector3(0.0, 0.0, -0.9)
	# Rack where delivered plate holders accumulate.
	box(Vector3(0.8, 0.06, 0.5), Vector3(0.95, 0.9, -1.9), wood)
	for x in [0.62, 1.28]:
		box(Vector3(0.05, 0.9, 0.05), Vector3(x, 0.45, -1.9), wood, null, false)
	var rack := Node3D.new()
	rack.position = Vector3(0.95, 0.93, -1.9)
	root.add_child(rack)
	out.rack = rack
	# Observing table: exposure plan, chronometer, metronome.
	# Layer 2 receives the Oxford lantern; the floor, legs and roof do not.
	box(Vector3(1.3, 0.06, 0.75), Vector3(-1.9, 0.8, -3.4), wood).find_children("*", "MeshInstance3D", true, false)[0].layers = 3
	for dx in [-0.58, 0.58]:
		for dz in [-0.3, 0.3]:
			box(Vector3(0.06, 0.8, 0.06), Vector3(-1.9 + dx, 0.4, -3.4 + dz), wood, null, false)
	var plan := box(Vector3(0.34, 0.03, 0.26), Vector3(-2.2, 0.845, -3.35), P("canvas"))
	plan.find_children("*", "MeshInstance3D", true, false)[0].layers = 3
	interactable(plan, "plan", L.t("曝光計畫"))
	var chrono := box(Vector3(0.22, 0.12, 0.22), Vector3(-1.65, 0.89, -3.45), Color(0.33, 0.22, 0.12))
	chrono.find_children("*", "MeshInstance3D", true, false)[0].layers = 3
	cyl(0.08, 0.02, Vector3(-1.65, 0.96, -3.45), Color(0.92, 0.9, 0.82)).layers = 3
	interactable(chrono, "chronometer", L.t("天文鐘"))
	var metro := MeshInstance3D.new()
	var pr := PrismMesh.new()
	pr.size = Vector3(0.12, 0.24, 0.1)
	metro.mesh = pr
	metro.layers = 3
	metro.material_override = mat(Color(0.25, 0.15, 0.08))
	metro.position = Vector3(-1.35, 0.95, -3.3)
	root.add_child(metro)
	out.metronome = metro
	return out


func _darkroom() -> Dictionary:
	var out := {}
	var wall := P("teak_dark") if look else P("teak")  # r05: darker boards so the lamp makes a pool
	var roof := P("iron").lightened(0.15)  # corrugated iron (RECONSTRUCTION)
	var c := Vector3(10.0, 0, 3.0)
	# Walls: 4 × 3.4 footprint, door gap on the west (-x) side.
	box(Vector3(0.12, 2.5, 3.4), c + Vector3(2.0, 1.25, 0), wall)
	box(Vector3(4.0, 2.5, 0.12), c + Vector3(0, 1.25, -1.7), wall)
	box(Vector3(4.0, 2.5, 0.12), c + Vector3(0, 1.25, 1.7), wall)
	box(Vector3(0.12, 2.5, 1.1), c + Vector3(-2.0, 1.25, -1.15), wall)
	box(Vector3(0.12, 2.5, 1.1), c + Vector3(-2.0, 1.25, 1.15), wall)
	box(Vector3(0.12, 0.5, 1.2), c + Vector3(-2.0, 2.25, 0), wall)
	box(Vector3(4.6, 0.14, 4.0), c + Vector3(0, 2.6, 0), roof, null, false, Vector3(0, 0, deg_to_rad(-6)))
	box(Vector3(4.0, 0.04, 3.4), c + Vector3(0, 0.02, 0), Color(0.3, 0.24, 0.18), null, false)
	# Shelf with the plate box.
	var shelf_wood := P("teak_dark")
	box(Vector3(0.5, 0.05, 1.6), c + Vector3(1.65, 1.0, -0.6), shelf_wood)
	var pbox := box(Vector3(0.36, 0.3, 0.5), c + Vector3(1.65, 1.18, -0.75), Color(0.22, 0.16, 0.1))
	interactable(pbox, "plate_box", L.t("底片匣箱"))
	out.plate_box_pos = c + Vector3(1.65, 1.18, -0.75)
	# Developing bench with trays.
	box(Vector3(1.4, 0.06, 0.6), c + Vector3(0.2, 0.85, -1.3), shelf_wood)
	var tray_positions := [-0.28, 0.17, 0.62]
	var tray_yaws := [4.0, -3.0, 2.0]
	var fallback_positions := [-0.35, 0.15, 0.6]
	for i in 3:
		var tray := model("dr_tray", c + Vector3(tray_positions[i], 0.88, -1.3), tray_yaws[i])
		if tray:
			tray.name = "DrTray%d" % i
			tray.add_to_group("darkroom_props")
		else:
			box(Vector3(0.36, 0.06, 0.3), c + Vector3(fallback_positions[i], 0.9, -1.3), Color(0.75, 0.73, 0.68), null, false)
	var props := [
		["DrBottle0", "dr_bottle", Vector3(-0.40, 0.88, -1.53), 20.0],
		["DrBottle1", "dr_bottle", Vector3(-0.05, 0.88, -1.54), 140.0],
		["DrBottle2", "dr_bottle", Vector3(0.40, 0.88, -1.53), 260.0],
		["DrBottle3", "dr_bottle", Vector3(1.70, 1.025, -1.22), 80.0],
		["DrPlateRack", "dr_plate_rack", Vector3(1.66, 1.025, -0.32), 90.0],
		["DrPlateHolder", "dr_plate_holder", Vector3(1.64, 1.025, 0.03), 90.0],
		["DrPail", "dr_pail", Vector3(-0.25, 0.04, -1.3), 30.0],
		["DrJug", "dr_jug", Vector3(0.30, 0.04, -1.35), -40.0],
		["DrPlateBox0", "dr_plate_box", Vector3(0.72, 0.04, -1.3), 0.0],
		["DrPlateBox1", "dr_plate_box", Vector3(0.72, 0.11, -1.3), 12.0],
	]
	for spec in props:
		var prop := model(spec[1], c + spec[2], spec[3])
		if prop:
			prop.name = spec[0]
			prop.add_to_group("darkroom_props")
	# Measuring table (used the night after).
	var mtable := box(Vector3(1.2, 0.06, 0.8), c + Vector3(0.6, 0.82, 1.1), shelf_wood)
	var sheet := box(Vector3(0.5, 0.02, 0.4), c + Vector3(0.6, 0.86, 1.1), Color(0.85, 0.85, 0.8), null, false)
	(sheet as MeshInstance3D).material_override = evidence_mat(Color(0.85, 0.85, 0.8))  # measuring sheet = evidence
	interactable(mtable, "measure", L.t("測量桌"))
	out.measure_pos = c + Vector3(0.6, 0.82, 1.1)
	var lamp := OmniLight3D.new()
	lamp.position = c + Vector3(0.9, 1.5, 1.0)
	lamp.light_color = Color(1.0, 0.80, 0.58) if look else Color(1.0, 0.72, 0.42)  # r05: a pool of light
	lamp.light_energy = 0.0
	lamp.light_volumetric_fog_energy = 0.0
	lamp.omni_range = 3.6 if look else 5.0
	lamp.omni_attenuation = 1.6 if look else 1.0
	# light_size (PCSS soft shadow) cost +2 ms forced-draw for a barely visible edge: off (perf-r05).
	lamp.shadow_enabled = true
	lamp.set_meta("standard_shadow", lamp.shadow_enabled)
	lamp.add_to_group("quality_shadow")
	root.add_child(lamp)
	out.lamp = lamp
	# Daylight enters through the west doorway; the bench lamp stays off.
	var doorway := SpotLight3D.new()
	doorway.name = "DoorwayDaylight"
	doorway.position = Vector3(8.05, 1.8, 3.0)
	doorway.rotation_degrees = Vector3(-18, -90, 0)
	doorway.light_color = Color(1.0, 0.93, 0.78)
	doorway.light_energy = 0.0
	doorway.light_indirect_energy = 0.0
	doorway.light_volumetric_fog_energy = 0.0
	doorway.spot_range = 4.0
	doorway.spot_angle = 65.0
	doorway.spot_attenuation = 1.0
	doorway.shadow_enabled = true
	root.add_child(doorway)
	out.doorway_daylight = doorway
	var safe := OmniLight3D.new()
	safe.position = c + Vector3(0.2, 2.0, -1.0)
	safe.light_color = Color(1.0, 0.15, 0.08)
	safe.light_energy = 0.6
	safe.omni_range = 3.5
	root.add_child(safe)
	out.safelight = safe
	out.safelight_glass = _safelight_lantern(safe)
	out.darkroom_spot = c + Vector3(-0.8, 0, 1.2)
	out.eddington_night = c + Vector3(1.3, 0, 0.3)
	return out


## The ruby lantern the safelight shines from: an iron box hung on a wire from
## the roof, its red pane facing the room (RECONSTRUCTION, a generic period lamp).
func _safelight_lantern(safe: OmniLight3D) -> MeshInstance3D:
	var iron := Color(0.12, 0.11, 0.1)
	var p := safe.position
	box(Vector3(0.16, 0.22, 0.14), p, iron, null, false)
	cyl(0.035, 0.06, p + Vector3(0, 0.14, 0), iron)  # chimney
	cyl(0.004, 0.36, p + Vector3(0, 0.35, 0), iron)  # wire to the roof
	var glass := SafelightGlass.new()
	var pane := BoxMesh.new()
	pane.size = Vector3(0.11, 0.15, 0.01)
	glass.mesh = pane
	glass.name = "SafelightGlass"
	glass.position = p + Vector3(0, 0, 0.072)
	glass.light = safe
	root.add_child(glass)
	return glass


func _plantation_house() -> void:
	var house := (preload("res://assets/models/sundy_house.glb") as PackedScene).instantiate() as Node3D
	house.name = "SundyHouse"
	house.position = Vector3(-15, 0, -20)
	house.rotation_degrees.y = 24.0
	root.add_child(house)

	if engraving_pilot:
		var stock := {
			"whitewash": [Swatch.PAPER, LAND, LAND, 0.34],
			"stone": [Swatch.PAPER, Color("bdb29c"), Color("b3b0a7"), 0.30],
			"roof_tile": [Swatch.TIMBER, Color("ae9278"), Color("55534e"), 0.42],
			"teak": [Swatch.TIMBER, Color("b4a089"), Color("827f78"), 0.0],
			"teak_dark": [Swatch.TIMBER, Color("87725d"), Color("6b6963"), 0.0],
			"iron": [Swatch.TIMBER, Color("625549"), Color("62605a"), 0.0],
		}
		for mesh: MeshInstance3D in house.find_children("*", "MeshInstance3D", true, false):
			mesh.add_to_group(&"sundy_print")
			for i in mesh.mesh.get_surface_count():
				var name_ := mesh.mesh.surface_get_material(i).resource_name.trim_prefix("E1919_")
				var swatch: Array = stock[name_]
				_pilot_surface(mesh, i, swatch[0], swatch[1], false, swatch[2], swatch[3])

	# The board is fixed to the verandah fascia above the entrance.
	var board := box(Vector3(4.15, 0.56, 0.09), Vector3(0, 3.70, 6.735), LAND, house, false) as MeshInstance3D
	board.name = "Nameboard"
	_pilot_surface(board, -1, Swatch.PAPER, LAND)
	var sign := Label3D.new()
	sign.name = "PaintedName"
	sign.text = "ROÇA SUNDY"
	sign.font = Fonts.paper_serif(Fonts.cjk())
	sign.font_size = 96
	sign.pixel_size = 0.0055
	sign.position = Vector3(0, 0, 0.047)
	sign.modulate = Color("221c18")
	sign.outline_size = 0
	sign.shaded = true
	sign.double_sided = false
	sign.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	board.add_child(sign)

	# Closed masonry shell, raised verandah, and rails with a gap at the stair.
	var yaw := house.rotation_degrees.y
	collider(Vector3(14, 5.05, 8), house.to_global(Vector3(0, 2.525, 0)), yaw)
	collider(Vector3(14.48, 0.9, 2.44), house.to_global(Vector3(0, 0.45, 5.22)), yaw)
	for side in [-1, 1]:
		collider(Vector3(5.82, 1.05, 0.22), house.to_global(Vector3(side * 4.25, 1.425, 6.23)), yaw)
		collider(Vector3(0.22, 1.05, 2.23), house.to_global(Vector3(side * 7.05, 1.425, 5.115)), yaw)

	# The player has no step-up motion. A slope through the tread nosings
	# connects grade to the deck while the visual stairs keep their risers.
	var stair := StaticBody3D.new()
	stair.name = "Stair"
	var cs := CollisionShape3D.new()
	var ramp := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	for x in [-1.34, 1.34]:
		for point in [Vector2(0.0, 6.4), Vector2(0.0, 8.04), Vector2(0.90, 6.4)]:
			points.append(Vector3(x, point.x, point.y))
	ramp.points = points
	cs.shape = ramp
	stair.add_child(cs)
	house.add_child(stair)

	var sundy := hotspot(Vector3(2.0, 2.5, 0.5), house.to_global(Vector3(0, 1.5, 5.8)), "sundy", L.t("Roça Sundy"))
	sundy.rotation_degrees.y = yaw
	sundy.name = "SundyHotspot"


func _card_mat(key: String, tex_a: String, tex_b := "", custom := false, sway := 0.0, backlight := 0.3, tex_c := "") -> ShaderMaterial:
	if not _mats.has(key):
		var m := ShaderMaterial.new()
		m.shader = FoliageCard
		m.set_shader_parameter("tex_v1", load(FOLIAGE + tex_a))
		m.set_shader_parameter("tex_v2", load(FOLIAGE + (tex_a if tex_b.is_empty() else tex_b)))
		m.set_shader_parameter("tex_v3", load(FOLIAGE + (tex_a if tex_c.is_empty() else tex_c)))
		m.set_shader_parameter("use_custom_variant", custom)
		m.set_shader_parameter("sway", sway)
		m.set_shader_parameter("backlight", backlight)
		_mats[key] = m
	return _mats[key]


static var _frond_mesh: ArrayMesh
static var _cocoa_mesh: ArrayMesh


## A folded strip along the original rachis, shared by every palm.
static func _palm_frond_mesh() -> ArrayMesh:
	if _frond_mesh == null:
		_frond_mesh = _folded_card(26, 2.6, 10.0, -65.0, 0.65, 28.0)
	return _frond_mesh


static func _folded_card(segments: int, length: float, pitch_a: float, pitch_b: float, half_width: float, fold: float) -> ArrayMesh:
	var spine := PackedVector3Array([Vector3.ZERO])
	for i in segments:
		var angle := deg_to_rad(lerpf(pitch_a, pitch_b, (i + 0.5) / segments))
		spine.append(spine[-1] + Vector3(0, sin(angle), cos(angle)) * (length / segments))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var across := half_width * cos(deg_to_rad(fold))
	var drop := half_width * sin(deg_to_rad(fold))
	for i in segments:
		for side in 2:
			var offsets := [Vector3(-across, -drop, 0), Vector3.ZERO, Vector3(across, -drop, 0)]
			for corner: Vector2i in [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0)]:
				var row := i + corner.x
				var col := side + corner.y
				st.set_uv(Vector2(float(row) / segments, col * 0.5))
				st.add_vertex(spine[row] + offsets[col])
	st.generate_normals()
	return st.commit()


func palm(pos: Vector3, h: float) -> void:
	var lean := Vector3(randf_range(-0.18, 0.18), randf() * TAU, randf_range(-0.18, 0.18))
	var p := Node3D.new()
	p.position = pos
	p.rotation = lean
	p.add_to_group("veg_palm")  # cost attribution: benchmark --bench-hide=veg_palm
	palm_crowns.append(pos + p.basis * Vector3(0, h, 0))  # the crown leans with the trunk
	root.add_child(p)
	if palm_sway == null:
		palm_sway = PalmSway.new()
		palm_sway.name = "PalmSway"
		root.add_child(palm_sway)
	cyl(0.16, h, Vector3(0, h * 0.5, 0), Color(0.42, 0.34, 0.24), p, false, Vector3.ZERO, 0.11)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(pos)
	var dead_count := rng.randi_range(2, 3) if rng.randf() < 0.4 else 0
	for i in 12 + dead_count:
		var leaf := Node3D.new()
		leaf.position = Vector3(0, h, 0)
		# Keep the original eight pitch/tint pairs in the global RNG stream.
		var pitch := randf_range(-35, -15) if i < 8 else rng.randf_range(-35, -15)
		var upper := i < 6
		var yaw := (i % 6) * TAU / 6.0 + (0.3 if not upper else 0.0)
		pitch = pitch * 0.55 if upper else pitch + 45.0
		if i >= 12:
			pitch = rng.randf_range(55.0, 70.0)
			yaw = rng.randf() * TAU
			leaf.scale = Vector3.ONE * rng.randf_range(0.45, 0.65)
		leaf.rotation = Vector3(deg_to_rad(pitch), yaw + rng.randf_range(-0.12, 0.12), 0)
		p.add_child(leaf)
		palm_sway.add(leaf, palm_crowns.size(), i)
		var tint := randf() * 0.12 if i < 8 else rng.randf() * 0.12
		var mesh := MeshInstance3D.new()
		mesh.mesh = _palm_frond_mesh()
		mesh.material_override = _card_mat("frond", "coconut_frond-v1.png", "coconut_frond-v2.png", false, 0.0, 0.35, "coconut_frond_dry-v1.png")
		mesh.set_instance_shader_parameter("pick", 2.0 if i >= 12 else float((palm_crowns.size() + i) % 2))
		mesh.set_instance_shader_parameter("tint", Color.WHITE.darkened(tint))
		leaf.add_child(mesh)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 0.2
	sh.height = 3.0
	cs.shape = sh
	cs.position.y = 1.5
	body.add_child(cs)
	body.position = pos
	root.add_child(body)


func _vegetation() -> void:
	seed(5291919)
	var spots := [Vector3(-6, 0, 2), Vector3(-8, 0, -4), Vector3(6, 0, -9), Vector3(14, 0, -3), Vector3(16, 0, 8),
		Vector3(-4, 0, 9), Vector3(4, 0, 11), Vector3(-11, 0, -9), Vector3(9, 0, -14), Vector3(-2, 0, -14),
		Vector3(20, 0, 2), Vector3(-18, 0, 0), Vector3(12, 0, 13), Vector3(-12, 0, 12), Vector3(24, 0, -12)]
	for s in spots:
		palm(s, randf_range(6.0, 9.5))
	# Preserve the original per-kind transforms and global RNG stream.
	var kit := {}  # model id -> Array[Transform3D]
	for i in 70:
		var a := randf() * TAU
		var d := randf_range(13.0, 40.0)
		var pos := Vector3(cos(a) * d, 0, sin(a) * d)
		if pos.distance_to(Vector3(-15, 0, -20)) < 10.0:
			continue
		var s := randf_range(0.8, 1.8)
		var _tint := randf() * 0.5  # preserve the original RNG draw
		var banana := i % 3 == 0
		var id := "banana_clump" if banana else "shrub_cocoa"
		var k := (0.75 + 0.25 * s) if banana else s  # banana clumps vary less in size
		var xf := Transform3D(Basis(Vector3.UP, fmod(i * 2.39996, TAU)).scaled(Vector3.ONE * k), pos)
		if not kit.has(id):
			kit[id] = []
		kit[id].append(xf)
	for id in kit:
		if id == "banana_clump":
			multimesh(id, kit[id], "veg_shrub")
		else:
			card_multimesh(id + "_multi", _cocoa_card_mesh(), kit[id], "veg_shrub")


func card_multimesh(name: String, mesh: Mesh, xforms: Array, group: String) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = mesh
	mm.instance_count = xforms.size()
	for j in xforms.size():
		mm.set_instance_transform(j, xforms[j])
		mm.set_instance_custom_data(j, Color(float(j % 2), 0, 0, 1))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = name
	mmi.multimesh = mm
	mmi.add_to_group(group)
	root.add_child(mmi)
	return mmi


static func _vertical_card(width: float, height: float, centered: bool) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for uv in [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 0), Vector2(1, 1), Vector2(0, 1)]:
		st.set_uv(uv)
		if centered:
			st.add_vertex(Vector3((uv.x - 0.5) * width, (1.0 - uv.y) * height, 0))
		else:
			st.add_vertex(Vector3(0, (0.5 - uv.y) * height, uv.x * width))
	st.generate_normals()
	return st.commit()


func _cocoa_card_mesh() -> ArrayMesh:
	if _cocoa_mesh != null:
		return _cocoa_mesh
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.05
	trunk.bottom_radius = 0.05
	trunk.height = 1.1
	trunk.radial_segments = 6
	trunk.rings = 0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.append_from(trunk, 0, Transform3D(Basis.IDENTITY, Vector3(0, 0.55, 0)))
	st.set_material(mat(P("teak_dark")))
	_cocoa_mesh = st.commit()
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var branch := _vertical_card(1.5, 1.0, false)
	var yaws := [0.0, 95.0, 185.0, 275.0]
	for k in 4:
		var basis := Basis(Vector3.UP, deg_to_rad(yaws[k])) * Basis(Vector3.RIGHT, deg_to_rad(12.0))
		st.append_from(branch, 0, Transform3D(basis, Vector3(0, 0.9 + k * 0.15, 0)))
	st.set_material(_card_mat("cacao", "cacao_branch-v1.png", "cacao_branch-v2.png", true, 0.03))
	st.commit(_cocoa_mesh)
	st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var foot := _vertical_card(1.2, 0.82, true)
	for yaw in [30.0, 120.0]:
		st.append_from(foot, 0, Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), Vector3(0, -0.05, 0)))
	st.set_material(_card_mat("undergrowth", "undergrowth-v1.png", "undergrowth-v2.png", true, 0.04))
	st.commit(_cocoa_mesh)
	return _cocoa_mesh


func _forest_edge() -> void:
	var band := Node3D.new()
	band.name = "ForestEdge"
	band.add_to_group("veg_forest_edge")
	root.add_child(band)
	for spec in [["Front", 47.0, 12.0, 5.0, "v1"], ["Back", 57.0, 16.0, 7.0, "v2"]]:
		var mi := MeshInstance3D.new()
		mi.name = spec[0]
		mi.mesh = _forest_loop(spec[1], spec[2], -0.6, spec[3])
		mi.material_override = _card_mat("forest_edge_" + spec[4], "forest_edge-" + spec[4] + ".png", "", false, 0.0, 0.2)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		band.add_child(mi)


static func _forest_loop(half_side: float, radius: float, bottom: float, top: float) -> ArrayMesh:
	var straight := 2.0 * (half_side - radius)
	var quarter := straight + PI * radius * 0.5
	var perimeter := 4.0 * quarter
	var columns := ceili(perimeter / 2.0)
	var tiles := maxi(3, roundi(perimeter / ((top - bottom) * 9.0)))
	var points := PackedVector3Array()
	var normals := PackedVector3Array()
	var shifts := PackedFloat32Array()
	for i in columns + 1:
		var distance := perimeter * i / columns
		var side := mini(3, int(distance / quarter))
		var along := distance - side * quarter
		var p: Vector2
		if along <= straight:
			p = Vector2(-half_side + radius + along, -half_side)
		else:
			var angle := -PI * 0.5 + (along - straight) / radius
			p = Vector2(half_side - radius, -half_side + radius) + Vector2(cos(angle), sin(angle)) * radius
		p = p.rotated(side * PI * 0.5)
		var point := Vector3(p.x, 0, p.y)
		points.append(point)
		normals.append((-point.normalized() + Vector3.UP).normalized())
		var bearing := rad_to_deg(atan2(point.x, -point.z))
		var ramp := clampf((absf(bearing + 38.0) - 24.0) / 10.0, 0.0, 1.0)
		shifts.append(0.55 * (top - bottom) * (0.5 + 0.5 * cos(PI * ramp)))
	# Copy the first column to close the seam exactly, including its normal and dip.
	points[columns] = points[0]
	normals[columns] = normals[0]
	shifts[columns] = shifts[0]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in columns:
		for corner: Vector2i in [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 0), Vector2i(1, 1), Vector2i(0, 1)]:
			var col := i + corner.x
			# The top edge stays off v = 0: the repeating sampler would filter the opaque
			# bottom row into it and draw a thin fringe across the sky.
			st.set_uv(Vector2(float(col) / columns * tiles, lerpf(0.02, 0.67, corner.y)))
			st.set_normal(normals[col])
			st.add_vertex(points[col] + Vector3.UP * ((top if corner.y == 0 else bottom) - shifts[col]))
	return st.commit()


func _props() -> Dictionary:
	# One kit model, uniformly scaled per crate. CRATE is the shipped mesh's measured
	# size (art/validation/packing_crate.g2.json), so colliders match the visuals.
	const CRATE := Vector3(0.74, 0.49, 0.50)
	# [scale, base centre, yaw]: the second crate is stacked on the first.
	var crates := [
		[1.0, Vector3(3.2, 0.0, -5.5), 0.0],
		[0.85, Vector3(3.3, CRATE.y, -5.4), 8.0],
		[1.25, Vector3(6.6, 0.0, 4.6), -15.0],
		[0.7, Vector3(-3.4, 0.0, -1.2), 25.0],
	]
	for c in crates:
		var size: Vector3 = CRATE * float(c[0])
		var centre: Vector3 = c[1] + Vector3(0, size.y / 2.0, 0)
		var crate := model("packing_crate", c[1], c[2], c[0])
		if crate:
			_pilot_model(crate, {"pine": Swatch.TIMBER, "teak_dark": Swatch.TIMBER, "iron": Swatch.DENSE})
			collider(size, centre, c[2])
		else:
			box(size, centre, P("pine"), null, true, Vector3(0, deg_to_rad(c[2]), 0))
	var label := Label3D.new()
	label.text = "R.A.S. ECLIPSE\nPRINCIPE"
	label.font_size = 40
	label.pixel_size = 0.004
	label.position = Vector3(3.2, 0.3, -5.24)
	label.modulate = Color(0.12, 0.08, 0.05)
	root.add_child(label)
	# Comparison-plate case from Oxford.
	var case_node := box(Vector3(0.4, 0.22, 0.32), Vector3(-2.65, 0.95, -3.45), Color(0.15, 0.18, 0.22))
	case_node.find_children("*", "MeshInstance3D", true, false)[0].layers = 3
	interactable(case_node, "oxford_case", L.t("牛津比對底片盒"))
	var props := _hurricane_lantern()
	props.crate_label = label
	return props


## A paraffin hurricane lantern on the observing bench (period reconstruction).
func _hurricane_lantern() -> Dictionary:
	var lantern := Node3D.new()
	lantern.name = "OxfordLantern"
	lantern.position = Vector3(-1.85, 0.83, -3.13)
	root.add_child(lantern)
	var iron := Color(0.12, 0.11, 0.10)
	# Eight-sided tank, chimney and two guards; no imported mesh.
	for part in [[0.085, 0.06, 0.03, 0.085], [0.075, 0.045, 0.29, 0.045], [0.035, 0.04, 0.33, 0.035]]:
		var mesh := CylinderMesh.new()
		mesh.bottom_radius = part[0]
		mesh.top_radius = part[3]
		mesh.height = part[1]
		mesh.radial_segments = 8
		mesh.rings = 1
		var mi := MeshInstance3D.new()
		mi.mesh = mesh
		mi.material_override = mat(iron)
		mi.position.y = part[2]
		lantern.add_child(mi)
	for x in [-0.075, 0.075]:
		box(Vector3(0.012, 0.25, 0.018), Vector3(x, 0.17, 0), iron, lantern, false)
	for x in [-0.055, 0.055]:
		box(Vector3(0.008, 0.10, 0.008), Vector3(x, 0.39, 0), iron, lantern, false)
	box(Vector3(0.118, 0.008, 0.008), Vector3(0, 0.44, 0), iron, lantern, false)
	var light := OmniLight3D.new()
	light.name = "OxfordLanternLight"
	light.position.y = 0.18
	light.light_color = Color(0.55, 0.66, 1.0)  # plate response prints this pool white
	light.light_energy = 0.0
	light.light_cull_mask = 2
	light.light_indirect_energy = 0.0
	light.light_volumetric_fog_energy = 0.0
	light.omni_range = 3.5
	light.omni_attenuation = 1.0
	light.shadow_enabled = true
	lantern.add_child(light)
	var glass := SafelightGlass.new()
	glass.name = "OxfordLanternGlass"
	var globe := CylinderMesh.new()
	globe.top_radius = 0.045
	globe.bottom_radius = 0.06
	globe.height = 0.20
	globe.radial_segments = 8
	globe.rings = 1
	glass.mesh = globe
	glass.position.y = 0.17
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glass.glass_colour = Color(0.65, 0.62, 0.52)
	glass.glow_colour = Color(1.0, 0.93, 0.78)
	glass.light = light
	lantern.add_child(glass)
	for mesh in lantern.find_children("*", "MeshInstance3D", true, false):
		mesh.layers = 3
	# Stowed until night: even an unlit new silhouette would alter totality.
	lantern.hide()
	return {"oxford_lantern": lantern, "oxford_lantern_light": light}


func npc(name: String, pos: Vector3, coat: Color, shirt: Color, id: String) -> Node3D:
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CapsuleShape3D.new()
	sh.radius = 0.3
	sh.height = 1.8
	cs.shape = sh
	cs.position.y = 0.9
	body.add_child(cs)
	body.position = pos
	root.add_child(body)
	if _person(id, body):
		cs.position = (body.get_node("figure") as Node3D).position + Vector3.UP * 0.9
		_tag(body, name)
		interactable(body, id, name)
		return body
	var trousers := Color(0.2, 0.19, 0.18)
	box(Vector3(0.14, 0.85, 0.16), Vector3(-0.1, 0.43, 0), trousers, body, false)
	box(Vector3(0.14, 0.85, 0.16), Vector3(0.1, 0.43, 0), trousers, body, false)
	box(Vector3(0.44, 0.62, 0.26), Vector3(0, 1.17, 0), coat, body, false)
	box(Vector3(0.16, 0.2, 0.02), Vector3(0, 1.35, -0.13), shirt, body, false)
	for sx in [-0.28, 0.28]:
		box(Vector3(0.11, 0.58, 0.13), Vector3(sx, 1.15, 0), coat, body, false)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.13
	hs.height = 0.28
	head.mesh = hs
	head.material_override = mat(Color(0.86, 0.7, 0.58))
	head.position = Vector3(0, 1.62, 0)
	body.add_child(head)
	# Fallback figures only (r06 characters replace them when the GLBs exist): RECONSTRUCTION hats.
	if id == "eddington":
		cyl(0.2, 0.03, Vector3(0, 1.73, 0), Color(0.86, 0.82, 0.7), body)
		var dome := MeshInstance3D.new()
		var ds := SphereMesh.new()
		ds.radius = 0.15
		ds.height = 0.2
		dome.mesh = ds
		dome.material_override = mat(Color(0.86, 0.82, 0.7))
		dome.position = Vector3(0, 1.78, 0)
		body.add_child(dome)
		cyl(0.012, 0.02, Vector3(-0.05, 1.63, -0.12), Color(0.1, 0.1, 0.1), body, false, Vector3(deg_to_rad(90), 0, 0))
		cyl(0.012, 0.02, Vector3(0.05, 1.63, -0.12), Color(0.1, 0.1, 0.1), body, false, Vector3(deg_to_rad(90), 0, 0))
	else:
		cyl(0.22, 0.02, Vector3(0, 1.72, 0), Color(0.85, 0.75, 0.5), body)
		cyl(0.13, 0.1, Vector3(0, 1.77, 0), Color(0.85, 0.75, 0.5), body)
	_tag(body, name)
	interactable(body, id, name)
	return body


func _tag(body: Node3D, name: String) -> void:
	var tag := Label3D.new()
	tag.text = name
	tag.font = Fonts.cjk()
	tag.font_size = 30
	tag.pixel_size = 0.0007
	tag.fixed_size = true
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.05, 0)
	tag.modulate = Color(1, 0.95, 0.8, 0.85)
	tag.outline_size = 8
	# r05: name tags fade out beyond conversation distance, so vistas carry no HUD text.
	tag.visibility_range_end = 9.0 if look else 0.0
	tag.visibility_range_end_margin = 3.0
	tag.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	body.add_child(tag)


# Bone-local axis times degrees, relative to the baked idle. The day hand
# reaches the side of the plate holder. Both night palms meet the table edge.
const EDDINGTON_DAY_POSE := {
	"spine_01": Vector3(12, 0, 0), "neck_01": Vector3(9, 0, 0),
	"upperarm_l": Vector3(76.5, 0, 1.7), "lowerarm_l": Vector3(64.7, 0, -4.1),
	"hand_l": Vector3(-81.5, 41.9, -40.5),
}
const EDDINGTON_NIGHT_POSE := {
	"spine_01": Vector3(22, 0, 0), "neck_01": Vector3(20, 0, 0),
	"upperarm_l": Vector3(9, 0, 5.7), "lowerarm_l": Vector3(40, 0, -9.6),
	"hand_l": Vector3(-29.5, 121.8, 23.7),
	"upperarm_r": Vector3(9, 0, -5.7), "lowerarm_r": Vector3(40, 0, 9.6),
	"hand_r": Vector3(-29.5, -121.8, -23.7),
}


class WorkingPose extends SkeletonModifier3D:
	const RELAXED_FINGERS := {
		"index_01": Vector3(1.1, 0, 10.6), "middle_01": Vector3(-2.5, 0, 25.5),
		"ring_01": Vector3(0.2, 0, 35.5), "pinky_01": Vector3(3.3, 0, 41.3),
		"thumb_01": Vector3(35.4, 0, -30.3),
	}

	var figure: Node3D
	var work_yaw: float
	var work_weight := 1.0
	var _work_rotations: Dictionary[int, Quaternion] = {}
	var _finger_rotations: Dictionary[int, Quaternion] = {}
	var _turn: Tween
	var _hat: Node3D
	var _hat_seat: Transform3D

	func _ready() -> void:
		figure = get_skeleton().find_parent("figure") as Node3D
		work_yaw = figure.rotation.y
		for finger in RELAXED_FINGERS:
			var left: Vector3 = RELAXED_FINGERS[finger]
			_set_rotation(_finger_rotations, finger + "_l", left)
			_set_rotation(_finger_rotations, finger + "_r", Vector3(left.x, -left.y, -left.z))

	func _set_rotation(rotations: Dictionary[int, Quaternion], bone: String, turn: Vector3) -> void:
		var index := get_skeleton().find_bone(bone)
		assert(index >= 0, "Working pose cannot find bone: " + bone)
		rotations[index] = Quaternion(turn.normalized(), deg_to_rad(turn.length()))

	func set_work_pose(turns: Dictionary) -> void:
		_work_rotations.clear()
		for bone in turns:
			_set_rotation(_work_rotations, bone, turns[bone])

	func face_player(eye: Vector3) -> void:
		var body := figure.get_parent() as Node3D
		var direction := body.to_local(eye) - figure.position
		_turn_to(atan2(direction.x, direction.z), 0.0)

	func restore_work() -> void:
		_turn_to(work_yaw, 1.0)

	func seat_hat(hat: Node3D) -> void:
		_hat = hat
		_hat_seat = hat.transform
		get_skeleton().skeleton_updated.connect(_level_hat)

	func _level_hat() -> void:
		# As the head bows, the top of the skull rolls back under the brim.
		var posed := (_hat.get_parent() as Node3D).global_transform * _hat_seat
		var up := posed.basis.y.normalized()
		var centre := posed.origin + Vector3.UP * (0.08 * (1.0 - up.y)) - up.slide(Vector3.UP) * 0.058
		_hat.global_transform = Transform3D(Basis.looking_at(-posed.basis.z.slide(Vector3.UP)), centre)

	func _turn_to(yaw: float, weight: float) -> void:
		if _turn:
			_turn.kill()
		if Settings.reduced_motion:
			figure.rotation.y = yaw
			work_weight = weight
			return
		var target := lerp_angle(figure.rotation.y, yaw, 1.0)
		_turn = create_tween().set_parallel().set_trans(Tween.TRANS_SINE)
		_turn.tween_property(figure, "rotation:y", target, 0.32)
		_turn.tween_property(self, "work_weight", weight, 0.32)

	func _process_modification_with_delta(_delta: float) -> void:
		var rig := get_skeleton()
		for index in _finger_rotations:
			rig.set_bone_pose_rotation(index, rig.get_bone_pose_rotation(index) * _finger_rotations[index])
		if work_weight == 0.0:
			return
		for index in _work_rotations:
			var turn: Quaternion = _work_rotations[index]
			if work_weight < 1.0:
				turn = Quaternion.IDENTITY.slerp(turn, work_weight)
			rig.set_bone_pose_rotation(index, rig.get_bone_pose_rotation(index) * turn)


## r06: production character (art/people/, MPFB route) in place of the primitive
## figure. Collider, interaction and tag stay on the body exactly as before. The
## model plays its baked "idle" loop and gets a head look-at (target set by main).
## Characters are not weathered: grime noise on faces reads as blotches.
func _person(id: String, body: Node3D) -> bool:
	var path := MODELS + id + ".glb"
	if not ResourceLoader.exists(path):
		return false
	var scene := load(path) as PackedScene
	if scene == null:
		return false  # exists but failed to load: keep the primitive figure
	var fig: Node3D = scene.instantiate()
	fig.name = "figure"
	var observer := id == "eddington"
	# Headings relative to the unchanged interaction bodies: tube and drive.
	fig.rotation_degrees.y = -53.0 if observer else -35.0
	if observer:
		# Eddington's prep body heads south (PI) once the world is built.
		fig.position = Vector3(-0.44, 0, 0.43)
	body.add_child(fig)
	_tone_linen(fig, 0.48 if observer else 0.61, false)
	# The brim and faired skin carry the face contour.
	for mi in fig.find_children("*", "MeshInstance3D", true, false):
		if mi.name.ends_with("_eyes") or mi.name.ends_with("_irises") or mi.name.ends_with("_eyebrows"):
			mi.hide()
	for ap in fig.find_children("*", "AnimationPlayer", true, false):
		var player := ap as AnimationPlayer
		if player.has_animation("idle"):
			player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			player.play("idle")
			player.seek(randf() * 3.0, true)  # the two men do not breathe in sync
	for sk in fig.find_children("*", "Skeleton3D", true, false):
		var pose := WorkingPose.new()
		pose.name = "WorkingPose"
		sk.add_child(pose)
		pose.set_work_pose(EDDINGTON_DAY_POSE if observer else {
			"spine_01": Vector3(5, 0, 0), "lowerarm_l": Vector3(37.9, -2.2, 2.2),
		})
		var look := LookAtModifier3D.new()
		look.name = "look_at"
		look.bone_name = "head"
		look.forward_axis = SkeletonModifier3D.BONE_AXIS_PLUS_Z
		look.primary_rotation_axis = Vector3.AXIS_Y
		look.use_angle_limitation = true
		look.symmetry_limitation = true
		look.primary_limit_angle = deg_to_rad(35.0)
		look.secondary_limit_angle = deg_to_rad(20.0)
		look.duration = 0.6
		look.influence = 0.0
		sk.add_child(look)
		if observer:
			pose.seat_hat(fig.find_child("eddington_hat", true, false) as Node3D)
	return true
