extends "/Volumes/KIOXIA/eddington-1919-cache/director/day-returns/aaca5a9/tools/survey.gd"
## Frozen-frame diagnosis: compare old/new sky blending at identical geometry.

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
		print("VIEW ", "horizon" if horizon else "sky", " elapsed=", front.elapsed, " blend=", game._style.quad_material.get_shader_parameter("return_blend"))
		var material: ShaderMaterial = game._style.quad_material
		var corrected: Shader = material.shader
		var old := Shader.new()
		old.code = corrected.code.replace("vec3 day_sky = min(texture(return_day, uv).rgb, mix(page, ink_col, clamp(edge * outline, 0.0, 1.0) * ink_strength));", "vec3 day_sky = texture(return_day, uv).rgb;")
		material.set_shader_parameter("return_blend", 0.0)
		var a := draw_environment(day)
		# The first draw also supplies the sky endpoint texture.
		var a2 := draw_environment(day)
		material.set_shader_parameter("return_blend", 0.000001)
		var fixed := draw_environment(day)
		material.shader = old
		var previous := draw_environment(day)
		print("PIXELS old_blend_step=", pixels(a2, previous), " fixed_blend_step=", pixels(a2, fixed), " repeated_day=", pixels(a, a2))
		material.shader = corrected
		game.stop_all_audio()
		game.free()
		await process_frame
	print("HANDOFF DIAGNOSIS COMPLETE JST")
	quit()
