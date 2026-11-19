extends "survey.gd"
## Native contact route and receipts reused from the director's row survey.
var capture_seed := 7
var horizon := false

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): base = arg.trim_prefix("--out=")
		if arg.begins_with("--sha="): sha = arg.trim_prefix("--sha=")
		if arg.begins_with("--seed="): capture_seed = int(arg.trim_prefix("--seed="))
		if arg == "--horizon": horizon = true
	root.size = Vector2i(1280, 720)
	receipts = FileAccess.open(base.path_join("receipts.jsonl"), FileAccess.WRITE)
	await fresh()
	set_state("totality")
	if horizon:
		aim(Vector3(3, 1.67, 6), Vector3(14, 2.2, 20))
	else:
		aim(Vector3(0, 1.67, -0.9), Vector3(0, 1.67, -0.9) + game.sim.sun_dir * 10)
	game.t_game = game.sim.TOTALITY_S - game.sim.TIME_SCALE - DT * game.sim.TIME_SCALE
	state = "native_third_contact"
	for i in 421:
		game._process(DT)
		await RenderingServer.frame_post_draw
		var front = game._style.impl.get("day_return")
		var radius := -1.0
		var seconds := -1.0 + i * DT
		if is_instance_valid(front):
			radius = front.radius()
			seconds = front.elapsed
		var band: float = deg_to_rad(game._style.params.get("return_width", 2.0))
		snapshot("scratch/f_%05d.png" % i, {"contact_s": seconds, "front_radius": radius, "front_band": band, "params": game._style.params, "sun_dir": xyz(game.sim.sun_dir)})
		await process_frame
	game.stop_all_audio()
	game.free()
	receipts.close()
	print("DAY RETURN CAPTURE COMPLETE JST")
	quit()
