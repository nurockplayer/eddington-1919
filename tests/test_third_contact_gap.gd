extends SceneTree
## Presentation-only contact gap; the immutable main simulation remains the oracle.
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
	# Main 0d09113: pin the exposure/plate oracle, including its seeded cloud field.
	check(FileAccess.get_sha256("res://scripts/eclipse_sim.gd") == "c6628ffd041798c554ebbe3fddb96ace7101283be89db9f8a13887ecfa566eb7", "simulation is byte-identical to main")
	var shader := FileAccess.get_file_as_string("res://shaders/eclipse_sky.gdshader")
	var shared_cloud := FileAccess.get_file_as_string("res://shaders/eclipse_cloud.gdshaderinc")
	check(shared_cloud.contains("dens = mix(dens, min(dens, 0.55), third_contact_gap * near_contact_sun);"), "shared cloud applies the contact veil")
	var engraving := FileAccess.get_file_as_string("res://shaders/style_engraving.gdshader")
	for source in [shader, engraving]:
		check(source.contains('#include "res://shaders/eclipse_cloud.gdshaderinc"'), "sky and engraving use one cloud rule")
	check(engraving.contains("eclipse_cloud_density(bead_dir)"), "engraving samples the sky cloud over the bead")
	check(engraving.contains("float moon_cover = moon_weight * diamond;"), "diamond continuously opens Moon line weight, reaching the accepted cloud weight at full strength")
	check(engraving.contains("moon_ink = front * step(r, 1.0) * moon_lines;"), "Moon ink has no binary diamond gate")
	for seed_ in [7, 1919]:
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
	# Second contact and mid-totality retain the original cloud. The veil begins
	# only 1 game-second (0.4 real seconds) before third contact.
	for t in [0.0, 151.0, 301.0, 301.5, 302.0, 302.9, 304.4, 310.0]:
		game._apply_light(1.0, 1.0, t, 0.0)
		var gap: float = game.sky_mat.get_shader_parameter("third_contact_gap")
		# _apply_light also runs inside the native contact tween, after _process.
		# No extra _process call may be required to deliver its state to the pass.
		for name in ["third_contact_gap", "cloud_time", "contact"]:
			check(game._style.quad_material.get_shader_parameter(name) == game.sky_mat.get_shader_parameter(name), "seed %d: immediate pass sync %s at %.1f" % [seed_, name, t])
		var density: float = game.sim.cloud_over_sun(t)
		var visible := lerpf(density, minf(density, 0.55), gap)
		check(density == ref.cloud_over_sun(t), "seed %d: physical cloud unchanged at %.1f" % [seed_, t])
		if t <= 301.0 or t >= 310.0:
			check(gap == 0.0 and visible == density, "seed %d: gap closed at %.1f" % [seed_, t])
		if t == 0.0 or t == 151.0:
			check(visible > 0.8, "seed %d: second contact/mid-totality stay clouded at %.1f" % [seed_, t])
		if t == 301.5:
			check(gap > 0.0 and gap < 1.0, "seed %d: cloud thins smoothly just before contact" % seed_)
		if t >= 302.0 and t <= 304.4:
			var alpha := clampf(visible * 1.08, 0.0, 1.0)
			var transmission := (1.0 - alpha) * (1.0 + alpha * 0.15)
			check(is_equal_approx(visible, 0.55) and transmission > 0.4, "seed %d: contact/glint peak density %.3f, transmission %.3f" % [seed_, visible, transmission])
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
	check(var_to_bytes(game.sim.plates) == var_to_bytes(ref.plates), "seed %d: plate bytes identical to main before/at third contact" % seed_)
	check(var_to_bytes(Judgment.grade(game.sim, "hopeful", "measured")) == var_to_bytes(Judgment.grade(ref, "hopeful", "measured")), "seed %d: scoring bytes identical to main" % seed_)
	game.stop_all_audio()
	game.queue_free()
	await process_frame
