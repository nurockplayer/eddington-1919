extends Node
## Asset Factory in-game QA (art/factory/README.md). Runs inside the real game
## scene with the game's own lighting (main._apply_light via benchmark._light),
## grade, SSAO and imported-model weathering. Candidates are placed only for the
## run, without colliders or interactables, so gameplay cannot change.
##
##   1. one shot per candidate from player eye height (3/4 front, only that
##      candidate and its support visible), under its declared lighting state
##   2. wide "dressed" views with every candidate placed, each rendered with and
##      without the candidates: draw calls, primitives and forced-draw time
##      (single run: indicative only, not a G4 performance claim)
##
## Run: godot --path . --always-on-top -- --factory-qa=art/factory/af01/qa \
##          --qa-manifest=art/factory/af01/qa_manifest.json --seed=7
## The manifest is written by `art/pipeline/factory.py qa` from the batch registry.

const World := preload("res://scripts/world_builder.gd")
const Bench := preload("res://tests/benchmark.gd")
const SETTLE_FRAMES := 20
const FORCED_FRAMES := 120

var main
var out_dir := ""
var manifest_path := ""
var bench  # benchmark.gd instance, used only for its _light(state)
var placed := {}  # id -> Node3D


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _shot(path: String) -> void:
	var drawn := [false]
	RenderingServer.frame_post_draw.connect(func(): drawn[0] = true, CONNECT_ONE_SHOT)
	var t0 := Time.get_ticks_msec()
	while not drawn[0] and Time.get_ticks_msec() - t0 < 5000:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)


func _aabb(n: Node) -> AABB:
	var box := AABB()
	var first := true
	for mi in n.find_children("*", "MeshInstance3D", true, false):
		var b: AABB = (mi as MeshInstance3D).global_transform * (mi as MeshInstance3D).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box


func _place(wb, a: Dictionary) -> Node3D:
	var path: String = a.glb
	if not ResourceLoader.exists(path):
		push_warning("factory_qa: missing " + path)
		return null
	var inst: Node3D = (load(path) as PackedScene).instantiate()
	var y := 0.0
	if a.get("on", "") != "" and placed.has(a.on):
		y = _aabb(placed[a.on]).end.y
	inst.position = Vector3(a.pos[0], y, a.pos[1])
	inst.rotation.y = deg_to_rad(a.get("yaw", 0.0))
	inst.rotation.x = deg_to_rad(-a.get("lean", 0.0))
	main.add_child(inst)
	wb.weather_model(inst)
	return inst


func _stats() -> Dictionary:
	var forced := PackedFloat32Array()
	for i in FORCED_FRAMES:
		var f0 := Time.get_ticks_usec()
		RenderingServer.force_draw(false)
		forced.append((Time.get_ticks_usec() - f0) / 1000.0)
	var total := 0.0
	for v in forced:
		total += v
	return {
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"forced_draw_ms_avg": snappedf(total / FORCED_FRAMES, 0.01),
	}


func _view(eye: Vector3, target: Vector3, light: String) -> void:
	bench._light(light)
	main.player.global_position = eye
	main.player.velocity = Vector3.ZERO
	await _frames(2)
	main.player.look_at_point(target)
	await _frames(SETTLE_FRAMES)


func _run() -> void:
	var f := FileAccess.open(manifest_path, FileAccess.READ)
	if f == null:
		push_error("factory_qa: cannot read manifest " + manifest_path)
		get_tree().quit(1)
		return
	var m: Dictionary = JSON.parse_string(f.get_as_text())
	bench = Bench.new()
	bench.main = main
	var wb = World.new(main)
	main.ui.visible = false
	main.player.can_move = false
	main.player.can_look = false
	# Supports first, so "on" placements can stand on them.
	var order: Array = m.assets.filter(func(a): return a.get("on", "") == "")
	order += m.assets.filter(func(a): return a.get("on", "") != "")
	for a in order:
		var n := _place(wb, a)
		if n:
			placed[a.id] = n
	await _frames(2)
	var results := []
	# 1. per-candidate shots
	for a in m.assets:
		if not placed.has(a.id):
			results.append({"id": a.id, "missing": true})
			continue
		for id in placed:
			placed[id].visible = id == a.id or id == a.get("on", "")
		var box := _aabb(placed[a.id])
		var centre := box.get_center()
		var size := box.size.length()
		var yaw := deg_to_rad(a.get("yaw", 0.0) + 35.0)
		# Fit the bounding sphere in ~60% of the 72° vertical FOV, from eye height.
		var dist := clampf(size * 0.5 / tan(deg_to_rad(36.0)) / 0.6, 1.3, 16.0)
		var eye := Vector3(centre.x, 0.05, centre.z) + Vector3(sin(yaw), 0, cos(yaw)) * dist
		if a.has("eye") and a.eye is Array and a.eye.size() == 3:
			eye = Vector3(a.eye[0], a.eye[1], a.eye[2])  # e.g. indoor assets
		var target := centre if box.size.y < 3.0 else Vector3(centre.x, box.size.y * 0.42, centre.z)
		await _view(eye, target, a.get("light", "prep_early"))
		var png := "%s.png" % a.id
		await _shot(out_dir.path_join(png))
		# Detail: same eye, 30° FOV (a long lens) so form and material can be judged.
		var fov: float = main.player.camera.fov
		main.player.camera.fov = 30.0
		await _frames(3)
		await _shot(out_dir.path_join("%s-detail.png" % a.id))
		main.player.camera.fov = fov
		results.append({"id": a.id, "screenshot": png, "light": a.get("light", "prep_early"),
			"aabb_m": [snappedf(box.size.x, 0.01), snappedf(box.size.y, 0.01), snappedf(box.size.z, 0.01)],
			"camera_dist_m": snappedf(dist, 0.01),
			"camera_at": [snappedf(main.player.camera.global_position.x, 0.01), snappedf(main.player.camera.global_position.y, 0.01), snappedf(main.player.camera.global_position.z, 0.01)],
			"asset_centre": [snappedf(centre.x, 0.01), snappedf(centre.y, 0.01), snappedf(centre.z, 0.01)]})
		print("[FQA] ", a.id)
	# 2. dressed views: with vs without all candidates
	var views := []
	for v in m.views:
		var eye := Vector3(v.eye[0], v.eye[1], v.eye[2])
		var target := Vector3(v.target[0], v.target[1], v.target[2])
		var rec := {"view": v.name, "light": v.light}
		for state in ["without", "with"]:
			for id in placed:
				placed[id].visible = state == "with"
			await _view(eye, target, v.light)
			rec[state] = _stats()
			await _shot(out_dir.path_join("view-%s-%s.png" % [v.name, state]))
		views.append(rec)
		print("[FQA] view ", JSON.stringify(rec))
	var summary := {"batch": m.batch, "godot": Engine.get_version_info().string,
		"seed": main.sim.run_seed, "assets": results, "views": views}
	var out := FileAccess.open(out_dir.path_join("qa.json"), FileAccess.WRITE)
	out.store_string(JSON.stringify(summary, "  "))
	out.close()
	print("[FQA] done -> ", out_dir)
	# Let in-flight frames and shader compiles drain: quitting mid-compile has
	# crashed MoltenVK at teardown (af01 run 3, signal 11 after all output was written).
	await _frames(10)
	get_tree().quit()
