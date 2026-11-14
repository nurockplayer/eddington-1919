extends Node
const Look := preload("res://scripts/look.gd")
const Settings := preload("res://scripts/settings.gd")
const Sim := preload("res://scripts/eclipse_sim.gd")
## In-game visual benchmark (gate G4 in art/PIPELINE.md). It runs inside the
## real game scene with the game's own lighting code: the camera visits fixed
## bookmarks under fixed lighting states, then saves a screenshot and render
## stats for each one. Compare two runs with art/pipeline/compare.py.
##
## Run: godot --path . --always-on-top -- --benchmark=art/validation/<label> [--seed=7]
## Use a fixed --seed so the cloud field is identical between runs.
## Cost attribution: --bench-hide=group[,group] hides every node in those scene
## groups (e.g. veg_shrub, veg_palm from world_builder.gd) before measuring, so
## two runs show what a layer costs in draw calls and primitives.
##
## Timing: wall-clock frame time is capped by the display (~8.3 ms at 120 Hz on
## the reference Mac even with vsync off), so it cannot show rendering savings.
## Each bookmark therefore also records the viewport's measured CPU and GPU
## render time (RenderingServer.viewport_get_measured_render_time_*), which is
## not capped. Report geometry, draw calls and times separately; fewer
## primitives is not, by itself, a frame-rate claim (art/PIPELINE.md G4).
##
## Key-art capture (store capsules, Library Hero): the same bookmarks, shot at
## another size or cloud time. These change the picture, so a run that uses
## them is not a G4 benchmark and its numbers do not compare with a baseline.
##   --bench-only=name[,name]  shoot only these bookmarks
##   --bench-cloud-t=<s>       cloud time of the "totality" lighting state (default
##                             230, thick cloud over the Sun; the density at a time
##                             is eclipse_sim.cloud_over_sun(t))
##   --bench-size=WxH          render the root viewport at this size whatever the
##                             window is (e.g. 3840x2160; the window shows it scaled)

const SETTLE_FRAMES := 20
const SAMPLE_FRAMES := 180
const FORCED_FRAMES := 240

## name, player position, look target, lighting state
const BOOKMARKS := [
	["arrival", Vector3(2.6, 0.05, 4.2), Vector3(-0.5, 1.3, -4.0), "prep_early"],
	["shelter", Vector3(1.0, 0.05, -0.4), Vector3(-0.3, 1.2, -6.6), "prep_late"],
	["coelostat", Vector3(1.5, 0.05, -4.9), Vector3(0.1, 1.15, -6.6), "prep_early"],
	["house", Vector3(-3.5, 0.05, -5.0), Vector3(-15.0, 3.0, -20.0), "prep_early"],
	["totality_sky", Vector3(0.0, 0.05, -0.9), Vector3.INF, "totality"],
	["totality_horizon", Vector3(3.0, 0.05, 6.0), Vector3(14.0, 2.2, 20.0), "totality"],
	["darkroom", Vector3(9.2, 0.05, 4.2), Vector3(10.6, 0.82, 4.1), "night"],
	# r06: conversation distance to Eddington (faces, clothes, look-at).
	["eddington_talk", Vector3(-1.1, 0.05, 0.9), Vector3(-1.1, 1.55, -0.9), "prep_early"],
	["cottingham_talk", Vector3(2.3, 0.05, -4.6), Vector3(1.35, 1.5, -6.1), "prep_early"],
	["totality_live", Vector3(0.0, 0.05, -0.9), Vector3.INF, "totality"],
]

var main
var out_dir := ""
var totality_cloud_t := 230.0
var only := PackedStringArray()
var capture_args := false


static func quality_arg(args: PackedStringArray) -> String:
	for arg in args:
		if arg.begins_with("--bench-quality="):
			var quality := arg.trim_prefix("--bench-quality=")
			if quality in ["low", "standard"]:
				return quality
	return ""


func apply_quality_arg(args: PackedStringArray) -> void:
	var quality := quality_arg(args)
	if quality != "":
		Settings.quality = quality
		Settings.apply_quality(get_tree())


static func cloud_t_arg(args: PackedStringArray) -> float:
	for arg in args:
		if arg.begins_with("--bench-cloud-t="):
			var value := arg.trim_prefix("--bench-cloud-t=")
			if value.is_valid_float():
				return value.to_float()
	return NAN


static func only_arg(args: PackedStringArray) -> PackedStringArray:
	for arg in args:
		if arg.begins_with("--bench-only="):
			return arg.trim_prefix("--bench-only=").split(",", false)
	return PackedStringArray()


static func size_arg(args: PackedStringArray) -> Vector2i:
	for arg in args:
		if arg.begins_with("--bench-size="):
			var parts := arg.trim_prefix("--bench-size=").split("x")
			if parts.size() == 2 and parts[0].is_valid_int() and parts[1].is_valid_int():
				var size := Vector2i(parts[0].to_int(), parts[1].to_int())
				if size.x >= 64 and size.y >= 64 and size.x <= 7680 and size.y <= 4320:
					return size
	return Vector2i.ZERO


## The bookmarks named in `names`, in bookmark order; all of them when `names`
## is empty. An unknown name selects nothing, so a typo cannot pass as a short run.
static func selected(bookmarks: Array, names: PackedStringArray) -> Array:
	if names.is_empty():
		return bookmarks
	var known := bookmarks.map(func(b): return b[0])
	for wanted in names:
		if not wanted in known:
			return []
	return bookmarks.filter(func(b): return b[0] in names)


func apply_capture_args(args: PackedStringArray) -> void:
	var cloud_t := cloud_t_arg(args)
	if not is_nan(cloud_t):
		totality_cloud_t = cloud_t
	only = only_arg(args)
	var size := size_arg(args)
	if size != Vector2i.ZERO:
		# Viewport stretch sets the root viewport to the base size and scales that
		# to the window, so the saved image can be larger than the display.
		var window := get_window()
		window.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		window.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
		window.content_scale_size = size
	capture_args = not is_nan(cloud_t) or not only.is_empty() or size != Vector2i.ZERO


## The bookmarks this run shoots; quits with exit code 1 when --bench-only names none.
func _shots(bookmarks: Array) -> Array:
	var shots := selected(bookmarks, only)
	if shots.is_empty():
		push_error("--bench-only names an unknown bookmark: " + ",".join(only))
		get_tree().quit(1)
	return shots


func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	apply_quality_arg(OS.get_cmdline_user_args())
	apply_capture_args(OS.get_cmdline_user_args())
	# --bench-stress=N renders the 3D scene at N× resolution scale (N² pixels) so the
	# GPU, not the display refresh, limits the frame: frame time then reflects scene cost.
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bench-stress="):
			get_viewport().scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
			get_viewport().scaling_3d_scale = float(a.trim_prefix("--bench-stress="))
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _light(state: String) -> void:
	var w: Dictionary = main.world
	w.roof.visible = state != "totality"
	w.lamp.light_energy = 1.1 if state == "night" else 0.0
	w.safelight.light_energy = (Look.NIGHT_SAFELIGHT if main._look_ambient < 1.0 else 0.25) if state == "night" else 0.6
	match state:
		"prep_early": main._apply_light(0.62, 0.0, -150.0, 0.0)
		"prep_late": main._apply_light(0.97, 0.38, -10.0, 0.0)
		"totality": main._apply_light(1.0, 1.0, totality_cloud_t, 0.0)
		"night": main._apply_light(0.0, 0.0, 400.0, 1.0)


func _shot(path: String) -> bool:
	if DisplayServer.get_name() == "headless":
		return false
	var drawn := [false]
	RenderingServer.frame_post_draw.connect(func(): drawn[0] = true, CONNECT_ONE_SHOT)
	var t0 := Time.get_ticks_msec()
	while not drawn[0] and Time.get_ticks_msec() - t0 < 5000:
		await get_tree().process_frame
	return get_viewport().get_texture().get_image().save_png(path) == OK


func _avg(a: PackedFloat32Array) -> float:
	var total := 0.0
	for v in a:
		total += v
	return snappedf(total / maxf(a.size(), 1), 0.01)


func _p95(a: PackedFloat32Array) -> float:
	var s := a.duplicate()
	s.sort()
	return snappedf(s[int(s.size() * 0.95)], 0.01)


func _hide_groups() -> Array:
	var hidden := []
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--bench-hide="):
			for g in a.trim_prefix("--bench-hide=").split(",", false):
				var nodes := get_tree().get_nodes_in_group(g)
				for n in nodes:
					n.visible = false
				hidden.append({"group": g, "nodes": nodes.size()})
	return hidden


func _run() -> void:
	var hidden := _hide_groups()
	main.ui.visible = false
	# Name tags are HUD text: fixed-size, unlike the painted signs.
	for tag in main.find_children("*", "Label3D", true, false):
		tag.visible = not tag.fixed_size
	main.player.can_move = false
	main.player.can_look = false
	var results := []
	var shots := _shots(BOOKMARKS)
	if shots.is_empty():
		return
	var run_seed: int = main.sim.run_seed
	for b in shots:
		if b[0] == "totality_live":
			await _setup_totality_live()
		else:
			_light(b[3])
		main.player.global_position = b[1]
		main.player.velocity = Vector3.ZERO
		var target: Vector3 = b[2]
		if target == Vector3.INF:
			target = main.player.camera.global_position + main.sim.sun_dir * 10.0
		await _frames(2)
		main.player.look_at_point(target)
		var r := await _sample_bookmark(b[0], b[3])
		r["seed"] = main.sim.run_seed
		results.append(r)
		print("[BENCH] ", JSON.stringify(r))
	_write_summary(results, run_seed, hidden)


func _setup_totality_live() -> void:
	# The live case has its own repeatable cloud field, even without --seed.
	main.sim = Sim.new(1919)
	main.sky_mat.set_shader_parameter("cloud_tex", ImageTexture.create_from_image(main.sim.cloud_img))
	main._start_game()
	main.sim.plates_carried = main.sim.MAX_EXTRA_PLATES
	main.ui.visible = true
	await main._begin_totality()
	main.t_game = totality_cloud_t
	main.player.can_move = false
	main.player.can_look = false
	main.set_process(false)
	main._toggle_shutter()


func _live_frame(i: int) -> void:
	# Fixed 60 Hz gameplay time makes the same plate change occur even headless.
	if i == 5:
		main._toggle_shutter()
	if i > 5 and main.change_left <= 0.0 and not main.sim.is_exposing():
		main._toggle_shutter()
	main._process(1.0 / 60.0)


func _sample_bookmark(bookmark: String, lighting: String) -> Dictionary:
	await _frames(SETTLE_FRAMES)
	var ms := PackedFloat32Array()
	var cpu := PackedFloat32Array()
	var gpu := PackedFloat32Array()
	var vp := get_viewport().get_viewport_rid()
	var t := Time.get_ticks_usec()
	for i in SAMPLE_FRAMES:
		await get_tree().process_frame
		if bookmark == "totality_live":
			_live_frame(i)
		var now := Time.get_ticks_usec()
		ms.append((now - t) / 1000.0)
		t = now
		cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(vp))
		gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(vp))
	# Uncapped render cost: draw without presenting (swap_buffers=false), so the
	# display refresh does not pace it. Frames in flight make single samples
	# noisy; the average over FORCED_FRAMES is the throughput figure.
	var forced := PackedFloat32Array()
	for i in FORCED_FRAMES:
		var f0 := Time.get_ticks_usec()
		RenderingServer.force_draw(false)
		forced.append((Time.get_ticks_usec() - f0) / 1000.0)
	var png := "%s.png" % bookmark
	var captured := await _shot(out_dir.path_join(png))
	var r := {
		"bookmark": bookmark, "lighting": lighting, "screenshot": png if captured else "",
		"frame_ms_avg": _avg(ms),
		"frame_ms_p95": _p95(ms),
		"forced_draw_ms_avg": _avg(forced),
		"forced_draw_ms_p95": _p95(forced),
		"render_cpu_ms_avg": _avg(cpu),
		"render_cpu_ms_p95": _p95(cpu),
		"render_gpu_ms_avg": _avg(gpu),
		"render_gpu_ms_p95": _p95(gpu),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"objects": Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME),
		"video_mem_mb": snappedf(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0, 0.1),
	}
	return r


func _summary(results: Array, seed_: int, hidden: Array, chapter := "") -> Dictionary:
	var summary := {
		"godot": Engine.get_version_info().string,
		"renderer": RenderingServer.get_video_adapter_name(),
		"viewport": [get_viewport().size.x, get_viewport().size.y],
		"seed": seed_,
		"quality": Settings.quality,
		"hidden_groups": hidden,
		"scaling_3d_scale": get_viewport().scaling_3d_scale,
		"bookmarks": results,
	}
	if chapter != "":
		summary["chapter"] = chapter
	if capture_args:
		var image := get_viewport().get_texture().get_size()
		summary["capture"] = {"only": only, "totality_cloud_t": totality_cloud_t, "image": [image.x, image.y]}
	return summary


func _write_summary(results: Array, seed_: int, hidden: Array, chapter := "") -> void:
	var summary := _summary(results, seed_, hidden, chapter)
	var f := FileAccess.open(out_dir.path_join("benchmark.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(summary, "  "))
	f.close()
	print("[BENCH] done -> ", out_dir)
	get_tree().quit()
