extends SceneTree
## Third contact keeps the live cloud field and the approved exposure simulation.
const Sim := preload("res://scripts/eclipse_sim.gd")
const Cues := preload("res://scripts/totality_cues.gd")
const Judgment := preload("res://scripts/judgment.gd")
var checks := 0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		print("FAIL: ", message)


func _run() -> void:
	# P2 (#351) intentionally changes drive drift; pin that approved simulation,
	# including the unchanged exposure/plate and seeded cloud model.
	check(FileAccess.get_sha256("res://scripts/eclipse_sim.gd") == "b3a9c3bf179b79d44ecd6bd0f39bf79878884bda1deaa83a9ab88fa7ef451af2", "simulation matches the approved P2 oracle")
	for seed_ in [7, 1551]:
		await _check_seed(seed_)
	print("%d third contact gap checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check_seed(seed_: int) -> void:
	var game: Node = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(game)
	game.set_process(false)
	game.sim = Sim.new(seed_)
	game.sky_mat.set_shader_parameter("cloud_tex", ImageTexture.create_from_image(game.sim.cloud_img))
	var ref = Sim.new(seed_)
	# Exercise the actual accumulation path through the mismatch window, once
	# closing just before contact and once leaving the shutter open at contact.
	game.phase = game.Phase.TOTALITY
	game.tot_done = false
	game._busy = false
	game.plates_left = game.sim.plates_available()
	game.t_game = 300.0
	for sunlit in [false, true]:
		game.sim.open_shutter(game.t_game)
		ref.open_shutter(game.t_game)
		var steps := 7 if not sunlit else 1
		for i in steps:
			game._process_totality(0.25 / Sim.TIME_SCALE)
			ref.accumulate(0.25, ref.cloud_over_sun(game.t_game))
		if not sunlit:
			game._toggle_shutter()
			var p: Dictionary = ref.close_shutter(false)
			p.sky_read = Cues.sky_band(p.clear, p.duration)
		else:
			ref.close_shutter(true)
	check(var_to_bytes(game.sim.plates) == var_to_bytes(ref.plates), "seed %d: plate bytes identical to the simulation oracle before/at third contact" % seed_)
	check(var_to_bytes(Judgment.grade(game.sim, "hopeful", "measured")) == var_to_bytes(Judgment.grade(ref, "hopeful", "measured")), "seed %d: scoring bytes identical to the simulation oracle" % seed_)
	game._day_return.kill()
	game.tot_done = false
	game.t_game = Sim.TOTALITY_S - 3.0 * game._totality_rate
	var step := 1.0 / 60.0
	var peak_gap := 0.0
	while not game.tot_done:
		game._process_totality(step)
		var gap: Variant = game.sky_mat.get_shader_parameter("third_contact_gap")
		if gap != null:
			peak_gap = maxf(peak_gap, float(gap))
	var tween: Tween = game._day_return
	tween.pause()
	var plate: ShaderMaterial = game._style.quad_material
	var previous_darkness: float = plate.get_shader_parameter("darkness")
	for frame in range(1, 13 * 60 + 1):
		if tween.is_valid():
			tween.custom_step(step)
		var t: float = game.sky_mat.get_shader_parameter("cloud_time")
		var gap: Variant = game.sky_mat.get_shader_parameter("third_contact_gap")
		if gap != null:
			peak_gap = maxf(peak_gap, float(gap))
		var darkness: float = plate.get_shader_parameter("darkness")
		check(darkness <= previous_darkness, "seed %d: light front recovers on frame %d" % [seed_, frame])
		check(plate.get_shader_parameter("cloud_time") == t and ref.cloud_over_sun(t) >= 0.92,
			"seed %d: live thick cloud stays in sync on frame %d" % [seed_, frame])
		previous_darkness = darkness
	check(peak_gap == 0.0, "seed %d: real third-contact flow must never force a reveal (peak gap %.3f)" % [seed_, peak_gap])
	check(previous_darkness == 0.0, "seed %d: recovery reaches daylight" % seed_)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
