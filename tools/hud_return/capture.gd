extends SceneTree

const Settings := preload("res://scripts/settings.gd")
const SIZE := Vector2i(1280, 720)
const FPS := 60
const CLOUDS := {"clear": 0.0, "thin": 0.35, "thick": 0.97}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	var out := args[0]
	var scale_value := float(args[1])
	var cloud_stills := args[2] == "clouds"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	root.size = SIZE
	root.content_scale_size = SIZE
	load("res://scripts/main.gd").next_seed = 1551
	seed(1551)
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.player.set_physics_process(false)
	await process_frame
	game.ui.start_btn.pressed.emit()
	RenderingServer.render_loop_enabled = false
	while game.phase != game.Phase.TOTALITY or game._busy:
		await process_frame
	while game.sim.TOTALITY_S - game.t_game > game._totality_rate * 3.0 / FPS:
		await process_frame
	RenderingServer.render_loop_enabled = true
	var locale := TranslationServer.get_locale()
	assert(game.sim.run_seed == 1551 and locale == "zh_TW")
	assert(is_equal_approx(Settings.text_scale, scale_value) and not Settings.reduced_motion)

	var frames: Array[Dictionary] = []
	var stills: Array[Dictionary] = []
	while frames.size() <= 10 * FPS:
		await RenderingServer.frame_post_draw
		if game.tot_done:
			var frame := frames.size()
			var panel: Control = game.ui.dialog_panel
			var portrait: Control = game.ui.dialogue_portrait.image
			var panel_rect := panel.get_global_rect()
			var portrait_rect := portrait.get_global_rect()
			# Sample flat paper between the inner rule and text, and a central
			# portion of the oval print inside its transparent edges.
			var panel_crop := Rect2(panel_rect.position + Vector2(7, 8), Vector2(7, 20))
			var portrait_crop := Rect2(portrait_rect.get_center() - Vector2(20, 25), Vector2(40, 50))
			var file := "f_%04d.png" % frame
			if not _save(out.path_join(file)):
				return
			frames.append({"file": file, "contact_s": float(frame) / FPS, "time_jst": _time_jst(),
				"panel": _bounds(panel, panel_crop), "portrait": _bounds(portrait, portrait_crop)})
			if cloud_stills and frame == 6 * FPS:
				var native: float = game.sky_mat.get_shader_parameter("practice_cloud")
				for cloud in CLOUDS:
					game.sky_mat.set_shader_parameter("practice_cloud", CLOUDS[cloud])
					game._sync_style_sky()
					RenderingServer.force_draw(false)
					var still := "%s-c3-plus6.png" % cloud
					if not _save(out.path_join(still)):
						return
					stills.append({"file": still, "contact_s": 6.0, "time_jst": _time_jst(),
						"practice_cloud": CLOUDS[cloud]})
				game.sky_mat.set_shader_parameter("practice_cloud", native)
				game._sync_style_sky()
		await process_frame
	var receipt := FileAccess.open(out.path_join("receipts.json"), FileAccess.WRITE)
	receipt.store_string(JSON.stringify({"state": "totality_live", "seed": 1551, "locale": locale,
		"text_scale": scale_value, "reduced_motion": false, "size": [SIZE.x, SIZE.y], "fps": FPS,
		"frames": frames, "stills": stills}, "\t"))
	receipt.close()
	game.stop_all_audio()
	print("CAPTURE COMPLETE %s: %d frames and %d stills" % [out, frames.size(), stills.size()])
	quit()


func _save(path: String) -> bool:
	var image := root.get_texture().get_image()
	if image.get_size() == SIZE and image.save_png(path) == OK:
		return true
	push_error("Could not save a 1280×720 frame at " + path)
	quit(1)
	return false


func _bounds(control: Control, crop: Rect2) -> Array:
	if not control.is_visible_in_tree():
		return []
	var pixels := root.get_stretch_transform() * crop
	return [roundi(pixels.position.x), roundi(pixels.position.y),
		roundi(pixels.end.x), roundi(pixels.end.y)]


func _time_jst() -> String:
	return Time.get_datetime_string_from_system(false, true) + " JST"
