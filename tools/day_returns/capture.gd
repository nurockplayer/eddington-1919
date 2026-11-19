extends "survey.gd"
## Native contact route and receipts reused from the director's row survey.
var capture_seed := 7
var horizon := false
var thick := false
var measure := false

func _thick_cloud() -> void:
	# Rehearsal fixture: an optically opaque cloud instead of the authored gap.
	# The simulation and #387's bead size/growth are untouched.
	game.sky_mat.set_shader_parameter("practice_cloud", 0.97)
	game.sky_mat.set_shader_parameter("third_contact_gap", 0.0)
	game._sync_style_sky()
	var front = game._style.impl.day_return
	if is_instance_valid(front):
		for material in front.skies + front.materials:
			material.set_shader_parameter("practice_cloud", 0.97)
			material.set_shader_parameter("third_contact_gap", 0.0)

func _cost() -> void:
	var file := FileAccess.open(base.path_join("cost.tsv"), FileAccess.WRITE)
	file.store_line("rep\tsample\tforced_draw_ms\tboth_worlds_live")
	for rep in 3:
		for i in 120:
			var start := Time.get_ticks_usec()
			RenderingServer.force_draw(false)
			var ms := (Time.get_ticks_usec() - start) / 1000.0
			file.store_line("%d\t%d\t%.6f\ttrue" % [rep, i, ms])
	file.close()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): base = arg.trim_prefix("--out=")
		if arg.begins_with("--sha="): sha = arg.trim_prefix("--sha=")
		if arg.begins_with("--seed="): capture_seed = int(arg.trim_prefix("--seed="))
		if arg == "--horizon": horizon = true
		if arg == "--thick": thick = true
		if arg == "--cost": measure = true
	root.size = Vector2i(1280, 720)
	receipts = FileAccess.open(base.path_join("receipts.jsonl"), FileAccess.WRITE)
	await fresh()
	set_state("totality")
	if thick:
		RenderingServer.frame_pre_draw.connect(_thick_cloud)
	if horizon:
		aim(Vector3(3, 1.67, 6), Vector3(14, 2.2, 20))
	else:
		aim(Vector3(0, 1.67, -0.9), Vector3(0, 1.67, -0.9) + game.sim.sun_dir * 10)
	game.t_game = game.sim.TOTALITY_S - game.sim.TIME_SCALE - DT * game.sim.TIME_SCALE
	state = "native_third_contact"
	var contact_frame := -1
	for i in 421:
		game._process(DT)
		if game.tot_done and contact_frame < 0:
			contact_frame = i
		await RenderingServer.frame_post_draw
		var front = game._style.impl.get("day_return")
		var radius := -1.0
		if is_instance_valid(front): radius = front.radius()
		var seconds := (i - contact_frame) * DT if contact_frame >= 0 else -1.0 + i * DT
		var band: float = deg_to_rad(game._style.params.return_width)
		var ui_rects := []
		for control in [game.ui.dialogue_portrait, game.ui.dialog_panel, game.ui.toast]:
			if control.is_visible_in_tree(): ui_rects.append(rect_array(control.get_global_rect()))
		snapshot("scratch/f_%05d.png" % i, {"contact_s": seconds, "front_radius": radius,
			"front_band": band, "params": game._style.params, "sun_dir": xyz(game.sim.sun_dir),
			"ui_rects": ui_rects, "practice_cloud": game.sky_mat.get_shader_parameter("practice_cloud"),
			"third_contact_gap": game.sky_mat.get_shader_parameter("third_contact_gap")})
		if measure and i == contact_frame + 90: _cost()
		if thick and i == contact_frame + 42:
			# At the native diamond peak, disable only the burst for a same-frame control.
			front.materials[0].set_shader_parameter("diamond", 0.0)
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png(base.path_join("diamond-off.png"))
		await process_frame
	if thick: RenderingServer.frame_pre_draw.disconnect(_thick_cloud)
	game.stop_all_audio()
	game.free()
	receipts.close()
	print("DAY RETURN CAPTURE COMPLETE JST")
	quit()
