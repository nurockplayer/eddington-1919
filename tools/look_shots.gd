extends SceneTree
## Fixed-camera stills of the decorations, for the windowed look (Owner rule:
## windowed runs Mon–Fri 09:00–15:00 JST only). One run captures every view;
## a view whose node is missing (branch not merged) is reported and skipped.
##
## Run: orb-test --heavy --host -- godot --path . --fixed-fps 60 --always-on-top \
##        -s tools/look_shots.gd -- --out=$PWD/build/look [--only=study,night,title]
## Headless the views are still set up and checked, but nothing is saved.


var out_dir := ""
var only := PackedStringArray()
var saved := 0
var skipped: Array[String] = []
var failed: Array[String] = []


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		if kv[0] == "out" and kv.size() > 1:
			out_dir = kv[1]
		elif kv[0] == "only" and kv.size() > 1:
			only = kv[1].split(",", false)
	if out_dir != "":
		DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _wanted(group: String) -> bool:
	return only.is_empty() or group in only


func frames(n: int) -> void:
	for i in n:
		await process_frame


func _hide_ui(scene: Node) -> void:
	for layer in scene.find_children("*", "CanvasLayer", true, false):
		(layer as CanvasLayer).visible = false


func _aim(scene: Node, from: Vector3, at: Vector3) -> Camera3D:
	var cam := Camera3D.new()
	cam.fov = 55.0
	scene.add_child(cam)
	cam.global_position = from
	cam.look_at(at, Vector3.UP if absf((at - from).normalized().y) < 0.99 else Vector3.FORWARD)
	cam.make_current()
	return cam


func _save(label: String) -> void:
	# Headless never draws, so frame_post_draw would never fire.
	if out_dir == "" or DisplayServer.get_name() == "headless":
		print("view ready: ", label)
		return
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	var err := img.save_png(out_dir.path_join(label + ".png"))
	if err != OK:
		failed.append(label)
		print("FAIL: could not save %s (error %d)" % [label, err])
		return
	saved += 1
	print("saved: ", label)


func _run() -> void:
	if _wanted("study"):
		await _study()
	if _wanted("night"):
		await _night()
	if _wanted("title"):
		await _title()
	if _wanted("totality"):
		await _totality()
	print("look shots: %d saved, skipped %s, failed %s" % [saved, skipped, failed])
	quit(1 if failed else 0)


func _study() -> void:
	var scene: Node = load("res://scenes/cambridge.tscn").instantiate()
	root.add_child(scene)
	await frames(30)
	_hide_ui(scene)
	var globe := scene.find_child("CelestialGlobe", true, false) as Node3D
	var chart := scene.find_child("TaurusChart", true, false) as Node3D
	var dust := scene.find_child("LampDust", true, false) as Node3D
	if globe:
		var at := globe.global_position + Vector3(0, 0.14, 0)
		_aim(scene, at + Vector3(-0.75, 0.05, 0.55), at)
		await frames(4)
		await _save("study_globe")
	else:
		skipped.append("study_globe")
	if chart:
		_aim(scene, chart.global_position + Vector3(-1.1, 0.0, 0.0), chart.global_position)
		await frames(4)
		await _save("study_chart")
	else:
		skipped.append("study_chart")
	if dust:
		# Dust is additive and tiny: look past the lamp toward the dark bookcase.
		var at := dust.global_position
		_aim(scene, at + Vector3(0.0, 0.05, 0.8), at)
		await frames(90)
		await _save("study_lamp_dust")
	else:
		skipped.append("study_lamp_dust")
	scene.queue_free()
	await frames(4)


func _night() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(30)
	if main.sky_mat.get_shader_parameter("night_stars") == null:
		skipped.append("night_*")
		main.queue_free()
		await frames(4)
		return
	main._apply_light(0.0, 0.0, 400.0, 1.0)
	_hide_ui(main)
	var eye := Vector3(2.6, 1.65, 4.2)  # the player's start, in the open
	# Toward the galactic centre (Milky Way, Scorpius) and up to Spica near the zenith.
	for view in [["night_milky_way", 21.5, 122.1], ["night_spica", 70.0, 183.9]]:
		_aim(main, eye, eye + _sky_dir(view[1], view[2]))
		await frames(6)
		await _save(view[0])
	main.queue_free()
	await frames(4)


# Same convention as night_sky.gd (loaded by name there; this tool also runs on main).
func _sky_dir(alt: float, az: float) -> Vector3:
	var a := deg_to_rad(alt)
	var z := deg_to_rad(az)
	return Vector3(-sin(z) * cos(a), sin(a), -cos(z) * cos(a))


func _title() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(2)
	var sky = main.ui.find_children("*", "Control", true, false).filter(func(n): return "meteors" in n and n.meteors)
	if sky.is_empty():
		skipped.append("title_meteor")
		main.queue_free()
		await frames(4)
		return
	# The first shooting star starts 4 s in and lives 0.9 s (fade_stars.gd).
	await create_timer(4.0).timeout
	for label in ["title_meteor_a", "title_meteor_b", "title_meteor_c"]:
		await create_timer(0.2).timeout
		await _save(label)
	# The Taurus lines (#46) peak 10 s in, on a 16 s cycle.
	if "figure" in sky[0] and sky[0].figure:
		await create_timer(5.4).timeout
		await _save("title_figure")
	else:
		skipped.append("title_figure")
	main.queue_free()
	await frames(4)


# Shadow bands (#50) on the last sliver, and the diamond ring (#53) at third
# contact. Bands move: these stills only prove they draw; judge them in motion.
func _totality() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(30)
	_hide_ui(main)
	var clear_t := 0.0
	for t in range(-120, 1):
		if main.sim.cloud_over_sun(float(t)) < main.sim.cloud_over_sun(clear_t):
			clear_t = float(t)
	var bands = main.world.get("shadow_bands")
	if bands:
		main._apply_light(0.985, 0.4, clear_t, 0.0)
		var at: Vector3 = main.world.station_pos
		_aim(main, at + Vector3(2.0, 1.6, 2.0), at)
		await frames(6)
		await _save("totality_shadow_bands")
		# Two more 0.4 s apart (at --fixed-fps 60): the bands must drift, not strobe.
		for i in [1, 2]:
			await frames(24)
			await _save("totality_shadow_bands_t%d" % i)
	else:
		skipped.append("totality_shadow_bands")
	# An unset uniform reads back null, so look for it in the shader source.
	if main.sky_mat.shader.code.contains("uniform vec2 third_contact"):
		main._apply_light(0.98, 0.9, clear_t, 0.0)
		main.sky_mat.set_shader_parameter("third_contact", Vector2(0.0, 1.0))
		var eye := Vector3(2.6, 1.65, 4.2)
		var cam := _aim(main, eye, eye + main.sim.sun_dir)
		cam.fov = 18.0  # the Sun's disc and limb, not the whole sky
		await frames(6)
		await _save("totality_diamond_ring")
	else:
		skipped.append("totality_diamond_ring")
	main.queue_free()
	await frames(4)
