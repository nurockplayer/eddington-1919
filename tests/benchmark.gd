extends Node
## In-game visual benchmark (gate G4 in art/PIPELINE.md). It runs inside the
## real game scene with the game's own lighting code: the camera visits fixed
## bookmarks under fixed lighting states, then saves a screenshot and render
## stats for each one. Compare two runs with art/pipeline/compare.py.
##
## Run: godot --path . --always-on-top -- --benchmark=art/validation/<label> [--seed=7]
## Use a fixed --seed so the cloud field is identical between runs.

const SETTLE_FRAMES := 20
const SAMPLE_FRAMES := 90

## name, player position, look target, lighting state
const BOOKMARKS := [
	["arrival", Vector3(2.6, 0.05, 4.2), Vector3(-0.5, 1.3, -4.0), "prep_early"],
	["shelter", Vector3(1.0, 0.05, -0.4), Vector3(-0.3, 1.2, -6.6), "prep_late"],
	["coelostat", Vector3(1.5, 0.05, -4.9), Vector3(0.1, 1.15, -6.6), "prep_early"],
	["house", Vector3(-3.5, 0.05, -5.0), Vector3(-15.0, 3.0, -20.0), "prep_early"],
	["totality_sky", Vector3(0.0, 0.05, -0.9), Vector3.INF, "totality"],
	["totality_horizon", Vector3(3.0, 0.05, 6.0), Vector3(14.0, 2.2, 20.0), "totality"],
	["darkroom", Vector3(9.2, 0.05, 4.2), Vector3(10.6, 0.82, 4.1), "night"],
]

var main
var out_dir := ""


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _light(state: String) -> void:
	var w: Dictionary = main.world
	w.roof.visible = state != "totality"
	w.lamp.light_energy = 1.1 if state == "night" else 0.0
	w.safelight.light_energy = 0.25 if state == "night" else 0.6
	match state:
		"prep_early": main._apply_light(0.62, 0.0, -150.0, 0.0)
		"prep_late": main._apply_light(0.97, 0.38, -10.0, 0.0)
		"totality": main._apply_light(1.0, 1.0, 230.0, 0.0)
		"night": main._apply_light(0.0, 0.0, 400.0, 1.0)


func _shot(path: String) -> void:
	var drawn := [false]
	RenderingServer.frame_post_draw.connect(func(): drawn[0] = true, CONNECT_ONE_SHOT)
	var t0 := Time.get_ticks_msec()
	while not drawn[0] and Time.get_ticks_msec() - t0 < 5000:
		await get_tree().process_frame
	get_viewport().get_texture().get_image().save_png(path)


func _run() -> void:
	main.ui.visible = false
	main.player.can_move = false
	main.player.can_look = false
	var results := []
	for b in BOOKMARKS:
		_light(b[3])
		main.player.global_position = b[1]
		main.player.velocity = Vector3.ZERO
		var target: Vector3 = b[2]
		if target == Vector3.INF:
			target = main.player.camera.global_position + main.sim.sun_dir * 10.0
		await _frames(2)
		main.player.look_at_point(target)
		await _frames(SETTLE_FRAMES)
		var ms := PackedFloat32Array()
		var t := Time.get_ticks_usec()
		for i in SAMPLE_FRAMES:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			ms.append((now - t) / 1000.0)
			t = now
		var sorted_ms := ms.duplicate()
		sorted_ms.sort()
		var total := 0.0
		for v in ms:
			total += v
		var png := "%s.png" % b[0]
		await _shot(out_dir.path_join(png))
		var r := {
			"bookmark": b[0], "lighting": b[3], "screenshot": png,
			"frame_ms_avg": snappedf(total / ms.size(), 0.01),
			"frame_ms_p95": snappedf(sorted_ms[int(ms.size() * 0.95)], 0.01),
			"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
			"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
			"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
			"video_mem_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
		}
		results.append(r)
		print("[BENCH] ", JSON.stringify(r))
	var summary := {
		"godot": Engine.get_version_info().string,
		"renderer": RenderingServer.get_video_adapter_name(),
		"viewport": [get_viewport().size.x, get_viewport().size.y],
		"seed": main.sim.run_seed,
		"bookmarks": results,
	}
	var f := FileAccess.open(out_dir.path_join("benchmark.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(summary, "  "))
	f.close()
	print("[BENCH] done -> ", out_dir)
	get_tree().quit()
