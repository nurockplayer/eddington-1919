extends "/Volumes/KIOXIA/eddington-1919-cache/director/day-returns/aaca5a9/tools/survey.gd"
## Frozen-frame diagnosis: only the camera environment changes between draws.

func pixels(a: Image, b: Image) -> int:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			var d := a.get_pixel(x, y) - b.get_pixel(x, y)
			if maxf(absf(d.r), maxf(absf(d.g), absf(d.b))) >= 16.0 / 255.0:
				count += 1
	return count

func draw_environment(environment: Environment) -> Image:
	game.player.camera.environment = environment
	RenderingServer.force_draw(false)
	return root.get_texture().get_image()

func _run() -> void:
	root.size = Vector2i(1280, 720)
	for horizon in [false, true]:
		await fresh()
		await game._begin_totality()
		set_state("totality")
		if horizon:
			aim(Vector3(3, 1.67, 6), Vector3(14, 2.2, 20))
		else:
			aim(Vector3(0, 1.67, -0.9), Vector3(0, 1.67, -0.9) + game.sim.sun_dir * 10)
		game.t_game = game.sim.TOTALITY_S - game.sim.TIME_SCALE - DT * game.sim.TIME_SCALE
		for i in (298 if horizon else 241):
			game._process(DT)
			await process_frame
		var front = game._style.impl.day_return
		front.set_process(false)
		var day: Environment = front.cameras[1].environment
		var native: Environment = game.env
		print("VIEW ", "horizon" if horizon else "sky", " elapsed=", front.elapsed, " blend=", game._style.quad_material.get_shader_parameter("return_blend"))
		for property in day.get_property_list():
			var key: String = property.name
			if property.usage & PROPERTY_USAGE_STORAGE and day.get(key) != native.get(key):
				print("ENV ", key, " day=", day.get(key), " native=", native.get(key))
		var a := draw_environment(day)
		var b := draw_environment(native)
		var a2 := draw_environment(day)
		print("PIXELS env_switch=", pixels(a, b), " repeated_day=", pixels(a, a2))
		# Copy each differing rendering setting independently onto the day env.
		for property in day.get_property_list():
			var key: String = property.name
			if not property.usage & PROPERTY_USAGE_STORAGE or key in ["resource_name", "resource_path", "resource_local_to_scene", "script"]:
				continue
			if day.get(key) == native.get(key): continue
			var probe: Environment = day.duplicate()
			probe.set(key, native.get(key))
			var image := draw_environment(probe)
			print("PROBE ", key, " vs_day=", pixels(a, image), " vs_native=", pixels(b, image))
		game.stop_all_audio()
		game.free()
		await process_frame
	print("HANDOFF DIAGNOSIS COMPLETE JST")
	quit()
