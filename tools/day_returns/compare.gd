extends "survey.gd"

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): base = arg.trim_prefix("--out=")
		if arg.begins_with("--sha="): sha = arg.trim_prefix("--sha=")
	root.size = Vector2i(1280, 720)
	receipts = FileAccess.open(base.path_join("receipts.jsonl"), FileAccess.WRITE)
	await fresh()
	state = "second_contact"
	aim(Vector3(0, 1.67, -0.9), Vector3(0, 1.67, -0.9) + game.sim.sun_dir * 10)
	game.prep_left = DT
	for i in 300:
		game._process(DT)
		game.player.rotation.y = game.player.yaw
		game.player.camera.rotation.x = game.player.pitch
		await RenderingServer.frame_post_draw
		if i % 5 == 0: snapshot("frames/second_%03d.png" % i)
		await process_frame
	await evidence()
	game.stop_all_audio()
	game.free()
	receipts.close()
	print("UNCHANGED CAPTURE COMPLETE JST")
	quit()
