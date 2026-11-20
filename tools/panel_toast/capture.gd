extends SceneTree
## Seed-7 totality_live, native contact route and tweens stepped at 60 Hz.
const DT := 1.0 / 60.0
var out := ""


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	root.size = Vector2i(1280, 720)
	L.apply("zh_TW")
	seed(7)
	load("res://scripts/main.gd").next_seed = 7
	var game: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.player.set_physics_process(false)
	game.ui.set_process(false)
	for i in 20:
		await process_frame
	game._start_game()
	game.player.can_move = false
	game.player.can_look = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.ui.show_toast("", 0.0)
	game.ui.toast.modulate.a = 0.0
	game.player.global_position = Vector3(0, 0.05, -0.9)
	game.player.look_at_point(game.player.camera.global_position + game.sim.sun_dir * 10.0)
	game.prep_left = 0.35
	var fade: Tween
	var contact := -1
	var records: Array = []
	var index := 0
	while contact < 0 or index <= contact + 180:
		game._process(DT)
		game.ui._process(DT)
		if game._busy and fade == null:
			fade = get_processed_tweens().back()
			fade.pause()
		if fade != null and fade.is_valid():
			# Avoid a floating-point extra frame at an exact tween boundary.
			fade.custom_step(DT + 0.000000001)
		if contact < 0 and not game.world.roof.visible:
			contact = index
			fade = get_processed_tweens().back()
			fade.pause()
		game.player.rotation.y = game.player.yaw
		game.player.camera.rotation.x = game.player.pitch
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("f_%05d.png" % index))
		var rects := {}
		for key in ["toast", "tot_panel", "clock_label", "prompt_label", "dialog_panel"]:
			var control: Control = game.ui.get(key)
			var rect := control.get_global_rect()
			if key == "toast":
				var paper: StyleBoxFlat = control.get_theme_stylebox("normal")
				rect = rect.grow_individual(paper.expand_margin_left, paper.expand_margin_top,
					paper.expand_margin_right, paper.expand_margin_bottom)
			rect = root.get_stretch_transform() * rect
			rects[key] = {"rect": [rect.position.x, rect.position.y, rect.size.x, rect.size.y],
				"visible": control.is_visible_in_tree(), "alpha": control.modulate.a}
		records.append({"frame": index, "fade": game.ui.fade.color.a, "hud": rects})
		index += 1
		await process_frame
	var receipt := FileAccess.open(out.path_join("capture.json"), FileAccess.WRITE)
	receipt.store_string(JSON.stringify({"seed": game.sim.run_seed, "bookmark": "totality_live",
		"contact_frame": contact, "content_scale_size": [root.content_scale_size.x, root.content_scale_size.y],
		"viewport": [root.size.x, root.size.y], "frames": records}))
	receipt.close()
	game.stop_all_audio()
	print("panel-toast capture: %d frames, contact frame %d, seed %d" % [index, contact, game.sim.run_seed])
	quit()
