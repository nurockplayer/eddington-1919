extends RefCounted
## Builds the Roça Sundy observing site from primitives.
## RECONSTRUCTION: no photographs of the Príncipe station in situ are known; the
## layout (sun-shelter over a horizontal tube fed by a coelostat, a darkroom hut,
## the plantation house) is a plausible stage, not a documented plan.

const Palette := preload("res://scripts/palette.gd")
const PalmSway := preload("res://scripts/palm_sway.gd")
const SafelightGlass := preload("res://scripts/safelight_glass.gd")
const MODELS := "res://assets/models/"

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
	_props()
	_bounds()
	randomize()  # vegetation reseeded the global RNG; don't leak that into "new sky" restarts
	out.eddington = npc("Eddington", Vector3(-1.1, 0, -0.9), Color(0.16, 0.15, 0.16), Color(0.85, 0.83, 0.78), "eddington")
	out.cottingham = npc("Cottingham", Vector3(1.35, 0, -6.1), Color(0.42, 0.36, 0.28), Color(0.88, 0.86, 0.8), "cottingham")
	out.cottingham.rotation.y = deg_to_rad(-60)
	return out


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
	for p in [Vector3(2.6, 0.03, -0.4), Vector3(-2.8, 0.03, -6.8), Vector3(5.2, 0.03, 2.4), Vector3(0.6, 0.03, 3.0)]:
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
		# Production model (art/assets.toml: coelostat). Colliders stay simple boxes.
		collider(Vector3(1.0, 1.06, 1.0), Vector3(0, 0.53, -6.6))
		# The drive housing stays solid AND interactable, like the old primitive box.
		drive = interactable(collider(Vector3(0.42, 0.36, 0.34), Vector3(0.62, 0.92, -6.6)), "drive", "時鐘驅動")
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
		interactable(drive, "drive", "時鐘驅動")
	out.drive_pos = Vector3(0.62, 0.92, -6.6)
	# Horizontal tube (lens near the coelostat, plate end toward the shelter front).
	var carrier: Node3D
	if model("horizontal_tube", Vector3(0, 0, -3.75)):
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
	interactable(carrier, "station", "底片架")
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
	box(Vector3(1.3, 0.06, 0.75), Vector3(-1.9, 0.8, -3.4), wood)
	for dx in [-0.58, 0.58]:
		for dz in [-0.3, 0.3]:
			box(Vector3(0.06, 0.8, 0.06), Vector3(-1.9 + dx, 0.4, -3.4 + dz), wood, null, false)
	var plan := box(Vector3(0.34, 0.03, 0.26), Vector3(-2.2, 0.845, -3.35), P("canvas"))
	interactable(plan, "plan", "曝光計畫")
	var chrono := box(Vector3(0.22, 0.12, 0.22), Vector3(-1.65, 0.89, -3.45), Color(0.33, 0.22, 0.12))
	cyl(0.08, 0.02, Vector3(-1.65, 0.96, -3.45), Color(0.92, 0.9, 0.82))
	interactable(chrono, "chronometer", "天文鐘")
	var metro := MeshInstance3D.new()
	var pr := PrismMesh.new()
	pr.size = Vector3(0.12, 0.24, 0.1)
	metro.mesh = pr
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
	interactable(pbox, "plate_box", "底片匣箱")
	out.plate_box_pos = c + Vector3(1.65, 1.18, -0.75)
	# Developing bench with trays.
	box(Vector3(1.4, 0.06, 0.6), c + Vector3(0.2, 0.85, -1.3), shelf_wood)
	for dx in [-0.35, 0.15, 0.6]:
		box(Vector3(0.36, 0.06, 0.3), c + Vector3(dx, 0.9, -1.3), Color(0.75, 0.73, 0.68), null, false)
	# Measuring table (used the night after).
	var mtable := box(Vector3(1.2, 0.06, 0.8), c + Vector3(0.6, 0.82, 1.1), shelf_wood)
	var sheet := box(Vector3(0.5, 0.02, 0.4), c + Vector3(0.6, 0.86, 1.1), Color(0.85, 0.85, 0.8), null, false)
	(sheet as MeshInstance3D).material_override = evidence_mat(Color(0.85, 0.85, 0.8))  # measuring sheet = evidence
	interactable(mtable, "measure", "測量桌")
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
	root.add_child(lamp)
	out.lamp = lamp
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
	var c := Vector3(-15, 0, -20)
	var wall := P("whitewash")
	box(Vector3(14, 5, 8), c + Vector3(0, 2.5, 0), wall)
	var roof := MeshInstance3D.new()
	var pr := PrismMesh.new()
	pr.size = Vector3(15, 2.4, 9)
	roof.mesh = pr
	roof.material_override = mat(P("roof_tile"))
	roof.position = c + Vector3(0, 6.2, 0)
	root.add_child(roof)
	for i in 7:
		box(Vector3(1.0, 1.6, 0.05), c + Vector3(-6 + i * 2, 3.1, 4.03), Color(0.22, 0.3, 0.28), null, false)
		cyl(0.1, 2.5, c + Vector3(-6.5 + i * 2.2, 1.25, 6.2), Color(0.9, 0.88, 0.82), null, true)
	box(Vector3(15, 0.2, 2.6), c + Vector3(0, 2.6, 5.3), P("roof_tile"), null, false)
	box(Vector3(15, 0.3, 2.6), c + Vector3(0, 0.15, 5.3), Color(0.6, 0.55, 0.5))
	var sign := Label3D.new()
	sign.text = "ROÇA SUNDY"
	sign.font_size = 160
	sign.pixel_size = 0.006
	sign.position = c + Vector3(0, 4.4, 4.1)
	sign.modulate = Color(0.25, 0.2, 0.15)
	root.add_child(sign)


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
	for i in 8:
		var leaf := Node3D.new()
		leaf.position = Vector3(0, h, 0)
		leaf.rotation = Vector3(deg_to_rad(randf_range(-35, -15)), i * TAU / 8.0, 0)
		p.add_child(leaf)
		palm_sway.add(leaf, palm_crowns.size(), i)
		box(Vector3(0.45, 0.03, 2.4), Vector3(0, -0.25, 1.15), P("foliage_deep").lightened(randf() * 0.12), leaf, false, Vector3(deg_to_rad(18), 0, 0))
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
	# Low cocoa-like shrubs and banana clumps around the edges. With the foliage kit
	# (art/assets.toml) they are instanced: one MultiMesh per model. All 70 together
	# are ~12k triangles, so finer chunks for culling only add draw calls (r04 G4:
	# quadrant chunks cost +26 draw calls looking up at totality). RNG use per shrub
	# is unchanged, so the layout matches the v0.1 baseline; kind and yaw come from
	# the index instead.
	var kit := {}  # model id -> Array[Transform3D]
	var spheres := []  # primitive fallback: [pos, size, tint]
	for i in 70:
		var a := randf() * TAU
		var d := randf_range(13.0, 40.0)
		var pos := Vector3(cos(a) * d, 0, sin(a) * d)
		if pos.distance_to(Vector3(-15, 0, -20)) < 10.0:
			continue
		var s := randf_range(0.8, 1.8)
		var tint := randf() * 0.5
		spheres.append([pos, s, tint])
		var banana := i % 3 == 0
		var id := "banana_clump" if banana else "shrub_cocoa"
		var k := (0.75 + 0.25 * s) if banana else s  # banana clumps vary less in size
		var xf := Transform3D(Basis(Vector3.UP, fmod(i * 2.39996, TAU)).scaled(Vector3.ONE * k), pos)
		if not kit.has(id):
			kit[id] = []
		kit[id].append(xf)
	var instanced := ResourceLoader.exists(MODELS + "shrub_cocoa.glb") and ResourceLoader.exists(MODELS + "banana_clump.glb")
	if instanced:
		for id in kit:
			multimesh(id, kit[id], "veg_shrub")
		return
	for sp in spheres:
		var s: float = sp[1]
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = s
		sm.height = s * 1.6
		mi.mesh = sm
		mi.position = sp[0] + Vector3(0, s * 0.6, 0)
		mi.material_override = mat(P("foliage_deep").lerp(P("foliage_light"), sp[2]))
		mi.add_to_group("veg_shrub")  # cost attribution: benchmark --bench-hide=veg_shrub
		root.add_child(mi)


func _props() -> void:
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
		if model("packing_crate", c[1], c[2], c[0]):
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
	interactable(case_node, "oxford_case", "牛津比對底片盒")


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
	fig.rotation.y = PI  # models face +Z; NPC bodies face -Z (v0.1 convention)
	body.add_child(fig)
	for ap in fig.find_children("*", "AnimationPlayer", true, false):
		var player := ap as AnimationPlayer
		if player.has_animation("idle"):
			player.get_animation("idle").loop_mode = Animation.LOOP_LINEAR
			player.play("idle")
			player.seek(randf() * 3.0, true)  # the two men do not breathe in sync
	for sk in fig.find_children("*", "Skeleton3D", true, false):
		var look := LookAtModifier3D.new()
		look.name = "look_at"
		look.bone_name = "head"
		look.forward_axis = SkeletonModifier3D.BONE_AXIS_PLUS_Z
		look.primary_rotation_axis = Vector3.AXIS_Y
		look.use_angle_limitation = true
		look.symmetry_limitation = true
		look.primary_limit_angle = deg_to_rad(110.0)
		look.secondary_limit_angle = deg_to_rad(50.0)
		look.duration = 0.6
		look.influence = 0.0
		sk.add_child(look)
	return true
