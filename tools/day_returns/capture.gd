extends "survey.gd"
## Native contact route and receipts reused from the director's row survey.
var capture_seed := 7
var horizon := false
var thick := false
var measure := false
var baseline := false
var cold := false
var ui_only := false

func hud_rects() -> Dictionary:
	var result := {}
	var controls := {"portrait": game.ui.dialogue_portrait, "panel": game.ui.dialog_panel,
		"toast": game.ui.toast, "timer": game.ui.tot_panel, "clock": game.ui.clock_label}
	for key in controls:
		var control: Control = controls[key]
		if not control.is_visible_in_tree(): continue
		var rect := control.get_global_rect()
		var style: StyleBox = control.get_theme_stylebox("normal" if control is Label else "panel")
		result[key] = rect_array(root.get_stretch_transform() * style.get_draw_rect(rect))
	return result

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

func plates_live() -> bool:
	var front = game._style.impl.get("day_return")
	return is_instance_valid(front) and front.active and front.plates[0].render_target_update_mode == SubViewport.UPDATE_ALWAYS and front.plates[1].render_target_update_mode == SubViewport.UPDATE_ALWAYS

func _cost(stage: String) -> void:
	var file := FileAccess.open(base.path_join("cost-" + stage + ".tsv"), FileAccess.WRITE)
	file.store_line("rep\tsample\tforced_draw_ms\tboth_worlds_live")
	for i in 30: RenderingServer.force_draw(false)
	for rep in 3:
		for i in 120:
			var start := Time.get_ticks_usec()
			RenderingServer.force_draw(false)
			var ms := (Time.get_ticks_usec() - start) / 1000.0
			file.store_line("%d\t%d\t%.6f\t%s" % [rep, i, ms, plates_live()])
	file.close()

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): base = arg.trim_prefix("--out=")
		if arg.begins_with("--sha="): sha = arg.trim_prefix("--sha=")
		if arg.begins_with("--seed="): capture_seed = int(arg.trim_prefix("--seed="))
		if arg == "--horizon": horizon = true
		if arg == "--thick": thick = true
		if arg == "--cost": measure = true
		if arg == "--baseline": baseline = true
		if arg == "--cold": cold = true
		if arg == "--ui-only": ui_only = true
	root.size = Vector2i(1280, 720)
	receipts = FileAccess.open(base.path_join("receipts.jsonl"), FileAccess.WRITE)
	await fresh()
	# Use the real second-contact route so cold runs include its warm-up.
	var npc_rotations := [game.world.eddington.rotation, game.world.cottingham.rotation]
	await game._begin_totality()
	game.world.eddington.rotation = npc_rotations[0]
	game.world.cottingham.rotation = npc_rotations[1]
	set_state("totality")
	if thick:
		RenderingServer.frame_pre_draw.connect(_thick_cloud)
	if horizon:
		aim(Vector3(3, 1.67, 6), Vector3(14, 2.2, 20))
	else:
		aim(Vector3(0, 1.67, -0.9), Vector3(0, 1.67, -0.9) + game.sim.sun_dir * 10)
	game.t_game = game.sim.TOTALITY_S - game.sim.TIME_SCALE - DT * game.sim.TIME_SCALE
	state = "native_third_contact"
	var first_frames: FileAccess
	if cold:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		first_frames = FileAccess.open(base.path_join("first-30.tsv"), FileAccess.WRITE)
		first_frames.store_line("frame_after_contact\tforced_draw_ms\tprocess_and_draw_ms")
	var contact_frame := -1
	for i in 431:
		if baseline and i == 59: _cost("totality")
		var process_start := Time.get_ticks_usec()
		game._process(DT)
		if game.tot_done and contact_frame < 0:
			contact_frame = i
		if cold and contact_frame >= 0 and i - contact_frame < 30:
			var draw_start := Time.get_ticks_usec()
			RenderingServer.force_draw(false)
			var end := Time.get_ticks_usec()
			first_frames.store_line("%d\t%.6f\t%.6f" % [i-contact_frame, (end-draw_start)/1000.0, (end-process_start)/1000.0])
		if baseline or cold:
			if contact_frame >= 0 and i == contact_frame + 360 and baseline: _cost("day-plus6")
			await process_frame
			continue
		if ui_only:
			await process_frame
			var original_rects := []
			for control in [game.ui.dialogue_portrait, game.ui.dialog_panel, game.ui.toast]:
				if control.is_visible_in_tree(): original_rects.append(rect_array(root.get_stretch_transform() * control.get_global_rect()))
			receipts.store_line(JSON.stringify({"frame_index": i, "hud_rects": hud_rects(), "ui_rects": original_rects}))
			continue
		await RenderingServer.frame_post_draw
		var front = game._style.impl.get("day_return")
		var radius := -1.0
		if is_instance_valid(front): radius = front.radius()
		var seconds := (i - contact_frame) * DT if contact_frame >= 0 else -1.0 + i * DT
		var band: float = deg_to_rad(game._style.params.return_width)
		var ui_rects := []
		for control in [game.ui.dialogue_portrait, game.ui.dialog_panel, game.ui.toast]:
			if control.is_visible_in_tree(): ui_rects.append(rect_array(root.get_stretch_transform() * control.get_global_rect()))
		snapshot("scratch/f_%05d.png" % i, {"contact_s": seconds, "front_radius": radius,
			"front_band": band, "params": game._style.params, "sun_dir": xyz(game.sim.sun_dir),
			"ui_rects": ui_rects, "practice_cloud": game.sky_mat.get_shader_parameter("practice_cloud"),
			"third_contact_gap": game.sky_mat.get_shader_parameter("third_contact_gap")})
		if -0.2 <= seconds and seconds <= 6.0:
			# Same frame/environment/UI, with both geometry and compositor culled.
			# Identical UI cancels from the scene-presence comparison.
			var camera: Camera3D = game.player.camera
			var saved_mask := camera.cull_mask
			camera.cull_mask = 0
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png(base.path_join("scratch/bare_%05d.png" % i))
			camera.cull_mask = saved_mask
			RenderingServer.force_draw(false)
		if measure and contact_frame >= 0:
			var stages := {42: "bead", 90: "crossing", 210: "crossing-plus3p5" if horizon else "ease-plus3p5", 270: "ease-plus4p5", 360: "day-plus6"}
			for stage in stages:
				if i == contact_frame + stage: _cost(stages[stage])
		if thick and contact_frame >= 0 and i == contact_frame + 42:
			# At the native diamond peak, disable only the burst for a same-frame control.
			front.materials[0].set_shader_parameter("diamond", 0.0)
			RenderingServer.force_draw(false)
			root.get_texture().get_image().save_png(base.path_join("diamond-off.png"))
		await process_frame
	if cold: first_frames.close()
	if thick: RenderingServer.frame_pre_draw.disconnect(_thick_cloud)
	game.stop_all_audio()
	game.free()
	receipts.close()
	print("DAY RETURN CAPTURE COMPLETE JST")
	quit()
