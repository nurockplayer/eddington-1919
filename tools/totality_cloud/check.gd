extends SceneTree
## Windowed regression: read back the production shader's cloud_body, then
## compare it to independently sampled, quantized simulation texture values.
const Sim := preload("res://scripts/eclipse_sim.gd")
var failures := 0
var out := ""
var source := "res://shaders/style_engraving.gdshader"

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cloud-check-out="):
			out = arg.trim_prefix("--cloud-check-out=")
		if arg.begins_with("--cloud-check-source="):
			source = arg.trim_prefix("--cloud-check-source=")
	assert(out.begins_with("/Volumes/KIOXIA/"), "evidence belongs on KIOXIA")
	_run.call_deferred()

func _draw() -> Image:
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _density(sim: RefCounted, ray: Vector3, t: float) -> float:
	var uv: Vector2 = Vector2(ray.x, ray.z) / maxf(ray.y, 0.06) * sim.CLOUD_SCALE - sim.wind * t
	var p: Vector2 = uv * sim.TEX_SIZE - Vector2(0.5, 0.5)
	var x := int(floor(p.x))
	var y := int(floor(p.y))
	var a: float = sim.cloud_img.get_pixel(posmod(x, 256), posmod(y, 256)).r
	var b: float = sim.cloud_img.get_pixel(posmod(x + 1, 256), posmod(y, 256)).r
	var c: float = sim.cloud_img.get_pixel(posmod(x, 256), posmod(y + 1, 256)).r
	var d: float = sim.cloud_img.get_pixel(posmod(x + 1, 256), posmod(y + 1, 256)).r
	var density := lerpf(lerpf(a, b, p.x - x), lerpf(c, d, p.x - x), p.y - y)
	return lerpf(density, 0.97, smoothstep(0.35, 0.05, ray.y))

func _agreement(image: Image, game: Node, t: float) -> Dictionary:
	var count := 0
	var matched := 0
	var sun_count := 0
	var sun_matched := 0
	for y in range(2, image.get_height(), 4):
		for x in range(2, image.get_width(), 4):
			var pixel := image.get_pixel(x, y)
			if pixel.g < 0.5:
				continue # The diagnostic's green channel identifies actual sky pixels.
			var ray: Vector3 = game.player.camera.project_ray_normal(Vector2(x + 0.5, y + 0.5))
			var density := _density(game.sim, ray, t)
			if absf(density - 0.35) < 0.02:
				continue # Exclude the one-pixel antialiasing boundary from binary agreement.
			var agrees := (pixel.r >= 0.5) == (density >= 0.35)
			count += 1
			matched += int(agrees)
			if ray.dot(game.sim.sun_dir) > cos(game.sim.SUN_R):
				sun_count += 1
				sun_matched += int(agrees)
	return {"samples": count, "agreement_pct": 100.0 * matched / count,
		"sun_samples": sun_count, "sun_agreement_pct": 100.0 * sun_matched / sun_count}

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(out)
	root.content_scale_mode = Window.CONTENT_SCALE_MODE_DISABLED
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.set_process(false)
	game.player.can_move = false
	game.player.can_look = false
	game.ui.hide()
	game.world.roof.hide()
	game.player.global_position = Vector3(0.0, 0.05, -0.9)
	game.player.look_at_point(game._totality_aim_point())
	game.player.rotation.y = game.player.yaw
	game.player.camera.rotation.x = game.player.pitch
	game.player.set_physics_process(false)
	var text := FileAccess.get_file_as_string(source)
	assert(text.contains("float cloud_weight ="), "shader has a drawn cloud mask")
	# Instrument the mask actually used for hatching; no alternate cloud formula.
	text = text.replace("float sky_white = 0.0;", "float sky_white = 0.0; float measured_cloud = 0.0;")
	text = text.replace("float cloud_weight =", "measured_cloud = cloud_body; float cloud_weight =")
	text = text.replace("ALBEDO = mix(print_colour, paper, bead);", "ALBEDO = vec3(measured_cloud, sky ? 1.0 : 0.0, 0.0);")
	var shader := Shader.new()
	shader.code = text
	game._style.quad_material.shader = shader
	var results := []
	for seed_ in [7, 1919]:
		game.sim = Sim.new(seed_)
		game.sky_mat.set_shader_parameter("cloud_tex", ImageTexture.create_from_image(game.sim.cloud_img))
		var times := [217.0, 124.0, 151.0] if seed_ == 7 else [217.0, 227.5, 151.0]
		for i in times.size():
			var t: float = times[i]
			game._apply_light(1.0, 1.0, t, 0.0)
			await _draw()
			var image := await _draw()
			var result := _agreement(image, game, t)
			result.merge({"seed": seed_, "cloud_t": t, "cloud_over_sun": game.sim.cloud_over_sun(t)})
			results.append(result)
			print(JSON.stringify(result))
			image.save_png(out.path_join("seed-%d-t-%s-mask.png" % [seed_, t]))
			if result.agreement_pct < 99.5 or result.sun_agreement_pct < 99.0 or result.sun_samples < 10:
				failures += 1
	FileAccess.open(out.path_join("agreement.json"), FileAccess.WRITE).store_string(JSON.stringify(results, "  "))
	game.stop_all_audio()
	game.free()
	print("totality_cloud: 6 states, %d failures" % failures)
	quit(1 if failures else 0)
