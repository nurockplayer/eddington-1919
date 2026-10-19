extends Node3D
## Neutral lookdev studio (gate G3 in art/PIPELINE.md). Shows imported assets
## next to fixed scale references (1.75 m figure, 1 m cube, grey and chrome
## balls), on an 18%-grey floor with a 1 m grid, and with the art-bible palette
## chips. Neutral light separates "the asset is wrong" from "the scene lighting
## is wrong"; the in-game benchmark (tests/benchmark.gd) checks the latter.
##
## Run:     godot --path . res://scenes/lookdev.tscn
## Capture: godot --path . --always-on-top res://scenes/lookdev.tscn -- --capture=DIR [--assets=a,b]

const MODELS_DIR := "res://assets/models/"
const PALETTE := "res://art/palette.toml"   # read from source; lookdev is excluded from exports (export_presets.cfg)
const CAMERAS := {
	"front": [Vector3(0.6, 1.1, 4.2), Vector3(0.6, 0.75, 0.0)],
	"three_quarter": [Vector3(3.6, 1.9, 3.4), Vector3(0.4, 0.7, 0.0)],
	"eye_level": [Vector3(0.9, 1.62, 2.6), Vector3(0.6, 1.1, 0.0)],
	"silhouette": [Vector3(0.6, 0.9, 4.6), Vector3(0.6, 0.85, 0.0)],
}

var cam: Camera3D
var key: DirectionalLight3D
var env: Environment
var report := {"assets": []}


func _ready() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		args[kv[0]] = kv[1] if kv.size() > 1 else "1"
	_studio()
	_references()
	_palette_chips()
	var ids: PackedStringArray = args.get("assets", "").split(",", false)
	if ids.is_empty():
		for f in DirAccess.get_files_at(MODELS_DIR):
			if f.ends_with(".glb"):
				ids.append(f.get_basename())
	var x := 0.0
	for id in ids:
		x = _place_asset(id, x) + 0.5
	cam = Camera3D.new()
	cam.fov = 50.0
	add_child(cam)
	_set_camera("three_quarter")
	if args.has("capture"):
		_capture.call_deferred(args.capture)


func _studio() -> void:
	env = Environment.new()
	# Neutral grey sky: metals need something to reflect (r03 finding: with a flat
	# background colour the mirror and chrome ball rendered black).
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.55, 0.56, 0.58)
	sky_mat.sky_horizon_color = Color(0.72, 0.72, 0.72)
	sky_mat.ground_horizon_color = Color(0.45, 0.45, 0.45)
	sky_mat.ground_bottom_color = Color(0.25, 0.25, 0.25)
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.62, 0.64)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES  # same tonemapper as the game
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	key = DirectionalLight3D.new()
	key.light_energy = 1.3
	key.shadow_enabled = true
	add_child(key)
	_key_from(Vector3(-0.6, 0.9, 0.7))
	# 18% grey (linear) floor with a 1 m grid.
	var floor_mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(14, 14)
	floor_mi.mesh = pm
	floor_mi.material_override = _flat(Color(0.46, 0.46, 0.46), 0.9)
	add_child(floor_mi)
	for i in range(-7, 8):
		_line(Vector3(i, 0.002, 0), Vector3(0.012, 0.002, 14))
		_line(Vector3(0, 0.002, i), Vector3(14, 0.002, 0.012))


func _key_from(dir: Vector3) -> void:
	key.look_at_from_position(dir.normalized() * 10.0, Vector3.ZERO, Vector3.UP)


func _flat(c: Color, rough := 0.8, metal := 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _line(pos: Vector3, size: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = _flat(Color(0.3, 0.3, 0.3))
	add_child(mi)


func _references() -> void:
	# 1.75 m figure (the player capsule height), 1 m cube, grey + chrome balls.
	var fig := Node3D.new()
	fig.position = Vector3(-1.4, 0, 0)
	add_child(fig)
	var body := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = 0.22
	cap.height = 1.5
	body.mesh = cap
	body.position.y = 0.75
	body.material_override = _flat(Color(0.55, 0.55, 0.56))
	fig.add_child(body)
	var head := MeshInstance3D.new()
	var hs := SphereMesh.new()
	hs.radius = 0.12
	hs.height = 0.24
	head.mesh = hs
	head.position.y = 1.63
	head.material_override = body.material_override
	fig.add_child(head)
	_label("1.75 m", Vector3(-1.4, 1.9, 0))
	var cube := MeshInstance3D.new()
	var bm := BoxMesh.new()
	cube.mesh = bm
	cube.position = Vector3(-2.7, 0.5, 0)
	cube.material_override = _flat(Color(0.5, 0.5, 0.5))
	add_child(cube)
	_label("1 m", Vector3(-2.7, 1.15, 0))
	for b in [[Vector3(-1.95, 0.15, 0.9), _flat(Color(0.46, 0.46, 0.46), 0.9)], [Vector3(-1.55, 0.15, 0.9), _flat(Color(0.95, 0.95, 0.95), 0.05, 1.0)]]:
		var s := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.15
		sm.height = 0.3
		s.mesh = sm
		s.position = b[0]
		s.material_override = b[1]
		add_child(s)


func _label(text: String, pos: Vector3) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font_size = 48
	l.pixel_size = 0.004
	l.position = pos
	l.modulate = Color(0.95, 0.93, 0.85)
	l.outline_size = 10
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(l)
	return l


## Palette chips along the back edge, straight from art/palette.toml.
func _palette_chips() -> void:
	var f := FileAccess.open(PALETTE, FileAccess.READ)
	if f == null:
		return
	var swatches := []
	var cur := ""
	for line in f.get_as_text().split("\n"):
		line = line.strip_edges()
		if line.begins_with("[swatch."):
			cur = line.trim_prefix("[swatch.").trim_suffix("]")
		elif cur != "" and line.begins_with("hex"):
			swatches.append([cur, Color(line.split("\"")[1])])
	for i in swatches.size():
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.36, 0.36, 0.04)
		mi.mesh = bm
		mi.position = Vector3(-3.0 + (i % 12) * 0.42, 0.25 + (i / 12) * 0.42, -2.0)
		mi.material_override = _flat(swatches[i][1], 0.9)
		add_child(mi)


func _place_asset(id: String, x: float) -> float:
	var path := MODELS_DIR + id + ".glb"
	if not ResourceLoader.exists(path):
		push_warning("lookdev: missing " + path)
		return x
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	add_child(inst)
	var aabb := _aabb(inst)
	inst.position = Vector3(x - aabb.position.x, 0, 0)
	var tris := 0
	var surfaces := 0
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var mesh: Mesh = mi.mesh
		surfaces += mesh.get_surface_count()
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			tris += (idx.size() if idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	var dims := aabb.size
	_label("%s\n%.2f × %.2f × %.2f m" % [id, dims.x, dims.z, dims.y], Vector3(x + dims.x / 2.0, dims.y + 0.3, 0))
	report.assets.append({"id": id, "dims_xzy_m": [snappedf(dims.x, 0.001), snappedf(dims.z, 0.001), snappedf(dims.y, 0.001)],
		"min_y": snappedf(aabb.position.y, 0.001), "triangles": tris, "surfaces": surfaces})
	return x + dims.x


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = mi.global_transform * mi.get_aabb()
		out = b if first else out.merge(b)
		first = false
	return out


func _set_camera(name: String) -> void:
	var c: Array = CAMERAS[name]
	cam.look_at_from_position(c[0], c[1], Vector3.UP)
	if name == "silhouette":
		_key_from(Vector3(0.2, 0.5, -1.0))  # backlight: shape must read with no interior detail
		env.ambient_light_energy = 0.12
	else:
		_key_from(Vector3(-0.6, 0.9, 0.7))
		env.ambient_light_energy = 0.55


func _capture(dir: String) -> void:
	DirAccess.make_dir_recursive_absolute(dir)
	for name in CAMERAS:
		_set_camera(name)
		for i in 12:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(dir.path_join("lookdev_%s.png" % name))
	var f := FileAccess.open(dir.path_join("lookdev.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("[LOOKDEV] ", JSON.stringify(report))
	get_tree().quit()
