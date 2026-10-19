extends RefCounted
## Builds the Roça Sundy observing site from primitives.
## RECONSTRUCTION: no photographs of the Príncipe station in situ are known; the
## layout (sun-shelter over a horizontal tube fed by a coelostat, a darkroom hut,
## the plantation house) is a plausible stage, not a documented plan.

const Palette := preload("res://scripts/palette.gd")
const MODELS := "res://assets/models/"

var root: Node3D
var _mats := {}


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
	return inst


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


func mat(color: Color, rough := 0.85, metal := 0.0) -> StandardMaterial3D:
	var key := "%s|%s|%s" % [color.to_html(), rough, metal]
	if not _mats.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = rough
		m.metallic = metal
		_mats[key] = m
	return _mats[key]


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
	var m := StandardMaterial3D.new()
	var tex := NoiseTexture2D.new()
	tex.width = 512
	tex.height = 512
	tex.seamless = true
	var n := FastNoiseLite.new()
	n.frequency = 0.02
	tex.noise = n
	var grad := Gradient.new()
	grad.set_color(0, P("foliage_deep").darkened(0.15))
	grad.set_color(1, P("foliage_light").darkened(0.1))
	tex.color_ramp = grad
	m.albedo_texture = tex
	m.uv1_scale = Vector3(18, 18, 1)
	m.roughness = 0.95
	mi.material_override = m
	body.add_child(mi)
	root.add_child(body)
	# Trampled red earth around the instruments and paths (wet after the storm).
	var dirt := P("laterite_wet")
	box(Vector3(7.5, 0.02, 9.5), Vector3(0, 0.01, -3.6), dirt, null, false)
	box(Vector3(10, 0.02, 1.6), Vector3(4.5, 0.012, 1.8), dirt, null, false, Vector3(0, deg_to_rad(-12), 0))
	box(Vector3(1.6, 0.02, 16), Vector3(-6, 0.012, -10), dirt, null, false, Vector3(0, deg_to_rad(35), 0))
	for p in [Vector3(2.6, 0.03, -0.4), Vector3(-2.8, 0.03, -6.8), Vector3(5.2, 0.03, 2.4), Vector3(0.6, 0.03, 3.0)]:
		var puddle := cyl(randf_range(0.4, 0.9), 0.01, p, Color(0.16, 0.17, 0.2))
		(puddle as MeshInstance3D).material_override = mat(Color(0.12, 0.14, 0.18), 0.05, 0.3)


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
	# Sun-shelter over the horizontal tube.
	for x in [-2.3, 2.3]:
		for z in [-0.6, -6.9]:
			cyl(0.07, 2.9, Vector3(x, 1.45, z), wood, null, true)
	# Canvas roof: rolled back before totality so the Sun can be watched.
	var roof := Node3D.new()
	root.add_child(roof)
	box(Vector3(5.2, 0.12, 7.0), Vector3(0, 2.95, -3.75), thatch, roof, false, Vector3(deg_to_rad(4), 0, 0))
	box(Vector3(5.4, 0.35, 0.1), Vector3(0, 2.75, -0.25), thatch.darkened(0.2), roof, false)
	out.roof = roof
	box(Vector3(5.2, 0.3, 0.3), Vector3(0, 2.95, -7.1), thatch.darkened(0.25), null, false)
	# Coelostat on its pier (the mirror turns with clockwork to follow the Sun).
	var drive: Node3D
	var coelostat := model("coelostat", Vector3(0, 0, -6.6))
	if coelostat:
		# Production model (art/assets.toml: coelostat). Colliders stay simple boxes.
		collider(Vector3(1.0, 1.06, 1.0), Vector3(0, 0.53, -6.6))
		drive = hotspot(Vector3(0.46, 0.4, 0.38), Vector3(0.62, 0.92, -6.6), "drive", "時鐘驅動")
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
	var tube_col := P("iron")
	box(Vector3(0.46, 0.46, 3.5), Vector3(0, 1.35, -3.75), tube_col)
	cyl(0.25, 0.14, Vector3(0, 1.35, -5.55), P("brass"), null, false, Vector3(deg_to_rad(90), 0, 0))
	for z in [-5.0, -2.5]:
		box(Vector3(0.7, 1.12, 0.12), Vector3(0, 0.56, z), wood)
	# Plate carrier at the eye end.
	var carrier := box(Vector3(0.6, 0.6, 0.18), Vector3(0, 1.35, -1.92), P("teak_dark"))
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
	var wall := P("teak")
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
	box(Vector3(0.5, 0.02, 0.4), c + Vector3(0.6, 0.86, 1.1), Color(0.85, 0.85, 0.8), null, false)
	interactable(mtable, "measure", "測量桌")
	out.measure_pos = c + Vector3(0.6, 0.82, 1.1)
	var lamp := OmniLight3D.new()
	lamp.position = c + Vector3(0.9, 1.5, 1.0)
	lamp.light_color = Color(1.0, 0.72, 0.42)
	lamp.light_energy = 0.0
	lamp.light_volumetric_fog_energy = 0.0
	lamp.omni_range = 5.0
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
	out.darkroom_spot = c + Vector3(-0.8, 0, 1.2)
	out.eddington_night = c + Vector3(1.3, 0, 0.3)
	return out


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
	root.add_child(p)
	cyl(0.16, h, Vector3(0, h * 0.5, 0), Color(0.42, 0.34, 0.24), p, false, Vector3.ZERO, 0.11)
	for i in 8:
		var leaf := Node3D.new()
		leaf.position = Vector3(0, h, 0)
		leaf.rotation = Vector3(deg_to_rad(randf_range(-35, -15)), i * TAU / 8.0, 0)
		p.add_child(leaf)
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
	# Low cocoa-like shrubs and banana clumps around the edges.
	for i in 70:
		var a := randf() * TAU
		var d := randf_range(13.0, 40.0)
		var pos := Vector3(cos(a) * d, 0, sin(a) * d)
		if pos.distance_to(Vector3(-15, 0, -20)) < 10.0:
			continue
		var s := randf_range(0.8, 1.8)
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = s
		sm.height = s * 1.6
		mi.mesh = sm
		mi.position = pos + Vector3(0, s * 0.6, 0)
		mi.material_override = mat(P("foliage_deep").lerp(P("foliage_light"), randf() * 0.5))
		root.add_child(mi)


func _props() -> void:
	# [size, base centre, yaw]: stacked crates sit on the one below.
	var crates := [
		[Vector3(0.7, 0.5, 0.5), Vector3(3.2, 0.0, -5.5), 0.0],
		[Vector3(0.6, 0.45, 0.5), Vector3(3.3, 0.5, -5.4), 8.0],
		[Vector3(0.9, 0.6, 0.6), Vector3(6.6, 0.0, 4.6), -15.0],
		[Vector3(0.5, 0.4, 0.4), Vector3(-3.4, 0.0, -1.2), 25.0],
	]
	for c in crates:
		var size: Vector3 = c[0]
		# One kit model, uniformly scaled to each crate's width (art/assets.toml: packing_crate).
		if model("packing_crate", c[1], c[2], size.x / 0.7):
			collider(Vector3(size.x, size.x / 0.7 * 0.5, size.x / 0.7 * 0.5), c[1] + Vector3(0, size.x / 0.7 * 0.25, 0), c[2])
		else:
			box(size, c[1] + Vector3(0, size.y / 2.0, 0), P("pine"), null, true, Vector3(0, deg_to_rad(c[2]), 0))
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
	# Hats: a pith helmet for one, a straw boater-like hat for the other (RECONSTRUCTION).
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
	var tag := Label3D.new()
	tag.text = name
	tag.font_size = 30
	tag.pixel_size = 0.0007
	tag.fixed_size = true
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = Vector3(0, 2.05, 0)
	tag.modulate = Color(1, 0.95, 0.8, 0.85)
	tag.outline_size = 8
	body.add_child(tag)
	interactable(body, id, name)
	return body
