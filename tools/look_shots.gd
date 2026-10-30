extends SceneTree
## Fixed-camera stills of the decorations, for the windowed look (Owner rule:
## windowed runs Mon–Fri 09:00–15:00 JST only). One run captures every view;
## a view whose node is missing (branch not merged) is reported and skipped.
##
## Run: orb-test --heavy --host -- godot --path . --fixed-fps 60 --always-on-top \
##        -s tools/look_shots.gd -- --out=$PWD/build/look [--only=study,departure,night,title,crescents,totality,darkroom]
## Headless the views are still set up and checked, but nothing is saved.

const Look := preload("res://scripts/look.gd")

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
	if _wanted("departure"):
		await _departure()
	if _wanted("night"):
		await _night()
	if _wanted("title"):
		await _title()
	if _wanted("crescents"):
		await _crescents()
	if _wanted("totality"):
		await _totality()
	if _wanted("darkroom"):
		await _darkroom()
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
	if scene.find_child("RainStreaks", true, false):
		# Rain runs down the sash: two stills 0.5 s apart (at --fixed-fps 60).
		_aim(scene, Vector3(0.9, 1.7, -1.2), Vector3(0.9, 2.0, -2.8))
		await frames(6)
		await _save("study_window_rain_a")
		await frames(30)
		await _save("study_window_rain_b")
	else:
		skipped.append("study_window_rain")
	scene.queue_free()
	await frames(4)


func _departure() -> void:
	var scene: Node = load("res://scenes/departure.tscn").instantiate()
	root.add_child(scene)
	await frames(30)
	_hide_ui(scene)
	var stars := scene.find_child("DepartureWindowStars", true, false) as Node3D
	if stars:
		# From mid-room up at the sash: lamp halo bottom-left, stars above it.
		_aim(scene, Vector3(0.55, 1.75, 0.4), Vector3(0.55, 2.4, -2.82))
		await frames(30)
		await _save("departure_window_stars")
	else:
		skipped.append("departure_window_stars")
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
	var ff = main.world.get("fireflies")
	if ff:
		# Low across the nearest palm's foot; give them a few seconds to blink.
		var foot: Vector3 = ff.palms[0]
		foot.y = 1.0
		_aim(main, foot + Vector3(2.6, 0.2, 2.6), foot)
		for label in ["night_fireflies_a", "night_fireflies_b"]:
			await frames(90)
			await _save(label)
	else:
		skipped.append("night_fireflies")
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


func _crescents() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(30)
	var sc = main.world.get("sun_crescents")
	if sc == null:
		skipped.append("crescents")
		main.queue_free()
		await frames(4)
		return
	_hide_ui(main)
	# Mid partial phase at the clearest moment of this run's clouds.
	var clear_t := -60.0
	for t in range(-120, 1):
		if main.sim.cloud_over_sun(float(t)) < main.sim.cloud_over_sun(clear_t):
			clear_t = float(t)
	main._apply_light(0.8, 0.1, clear_t, 0.0)
	if not sc.visible:
		failed.append("crescents_shade (clouded out)")
		main.queue_free()
		await frames(4)
		return
	var spot: Vector3 = sc.spots[0].origin
	_aim(main, spot + Vector3(1.2, 1.6, 1.2), spot)
	await frames(6)
	await _save("crescents_shade")
	# The breeze in the fronds: up at the first crown, two stills 1 s apart.
	var palms := main.get_tree().get_nodes_in_group("veg_palm")
	if main.find_child("PalmSway", true, false) and not palms.is_empty():
		var crown := (palms[0].get_child(1) as Node3D).global_position
		_aim(main, crown + Vector3(4.0, -4.5, 4.0), crown)
		await frames(6)
		await _save("palm_sway_a")
		await frames(60)
		await _save("palm_sway_b")
	else:
		skipped.append("palm_sway")
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
		# The values the third-contact tween passes at the diamond's peak (v = 0.24).
		main._apply_light(0.952, 1.0 - 0.24 * 0.24, clear_t, 0.0)
		main.sky_mat.set_shader_parameter("third_contact", Vector2(0.0, 1.0))
		var eye := Vector3(2.6, 1.65, 4.2)
		var cam := _aim(main, eye, eye + main.sim.sun_dir)
		cam.fov = 18.0  # the Sun's disc and limb, not the whole sky
		await frames(6)
		await _save("totality_diamond_ring")
		cam.fov = 55.0  # context: is anything between the eye and the Sun?
		await frames(6)
		await _save("totality_diamond_ring_wide")
		print("diamond ring view: cloud over Sun %.2f at t=%.0f" % [main.sim.cloud_over_sun(clear_t), clear_t])
	else:
		skipped.append("totality_diamond_ring")
	main.queue_free()
	await frames(4)


# The ruby safelight lantern, at the night's darkroom level (main.gd _begin_night).
func _darkroom() -> void:
	var main: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await frames(30)
	var glass = main.world.get("safelight_glass")
	if glass == null:
		skipped.append("darkroom_safelight")
		main.queue_free()
		await frames(4)
		return
	main._apply_light(0.0, 0.0, 400.0, 1.0)
	_hide_ui(main)
	main.world.lamp.light_energy = 1.1
	main.world.safelight.light_energy = Look.NIGHT_SAFELIGHT
	var eye: Vector3 = main.world.darkroom_spot + Vector3(0, 1.6, 0)
	_aim(main, eye, glass.global_position)
	await frames(6)
	await _save("darkroom_safelight")
	main.queue_free()
	await frames(4)
