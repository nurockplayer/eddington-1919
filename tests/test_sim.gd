extends SceneTree
## Headless logic checks for the simulation and judgment.
## Run: godot --headless --path . --script res://tests/test_sim.gd

const Sim := preload("res://scripts/eclipse_sim.gd")
const Judgment := preload("res://scripts/judgment.gd")

var failures := 0
var checks := 0


func check(cond: bool, msg: String) -> void:
	checks += 1
	if not cond:
		failures += 1
		print("FAIL: ", msg)


func expose(sim, t0: float, dur: float) -> Dictionary:
	sim.open_shutter(t0)
	var t := t0
	while t < t0 + dur:
		sim.accumulate(0.1, sim.cloud_over_sun(t))
		t += 0.1
	return sim.close_shutter(false)


func best_window(sim) -> float:
	var best_t := 0.0
	var best := 9.0
	var t := 0.0
	while t < sim.TOTALITY_S - 10.0:
		var d: float = sim.cloud_over_sun(t)
		if d < best:
			best = d
			best_t = t
		t += 0.5
	return best_t


func _init() -> void:
	# Determinism and gap structure across many seeds.
	var clear_late := 0
	for s in range(1, 41):
		var a = Sim.new(s)
		var b = Sim.new(s)
		check(is_equal_approx(a.cloud_over_sun(123.4), b.cloud_over_sun(123.4)), "deterministic cloud for seed %d" % s)
		var thick := 0
		var n := 0
		var t := 0.0
		while t < 300.0:
			var d: float = a.cloud_over_sun(t)
			n += 1
			if d > 0.7:
				thick += 1
			t += 1.0
		check(float(thick) / n > 0.55, "seed %d: mostly cloudy over the Sun (%.2f)" % [s, float(thick) / n])
		var late: Dictionary = a.gaps[2]
		var mid: float = late.t + late.d * 0.5
		var dm: float = a.cloud_over_sun(mid)
		check(dm < 0.4, "seed %d: late gap actually thins the cloud (%.2f at %.0f s)" % [s, dm, mid])
		if dm < 0.25:
			clear_late += 1
	check(clear_late >= 30, "late window clearly thin on most seeds (%d/40)" % clear_late)

	# Exposure consequences.
	var sim = Sim.new(7)
	sim.drive_wound = true
	sim.drive_rate_checked = true
	var g: Dictionary = sim.gaps[2]
	var good: Dictionary = expose(sim, g.t + 1.0, minf(g.d - 2.0, 10.0))
	var cloudy: Dictionary = expose(sim, 5.0, 12.0)
	check(good.stars >= 5 and good.usable, "exposure inside the late gap records ≥5 stars (%d)" % good.stars)
	check(cloudy.stars < good.stars, "thick-cloud exposure records fewer stars (%d vs %d)" % [cloudy.stars, good.stars])
	check(good.quality == "good", "checked drive + gap → good plate (%s, trail %.2f fog %.2f)" % [good.quality, good.trail, good.fog])

	var sim2 = Sim.new(7)  # same sky, drive not checked
	var g2: Dictionary = sim2.gaps[2]
	var trailed: Dictionary = expose(sim2, g2.t + 1.0, minf(g2.d - 2.0, 10.0))
	check(trailed.trail > good.trail * 3.0, "unchecked drive trails more (%.2f vs %.2f)" % [trailed.trail, good.trail])
	check(trailed.sigma > good.sigma, "trailed plate has a larger error")
	check(trailed.value < good.value + 0.3, "trailed plate biased low (%.2f vs %.2f)" % [trailed.value, good.value])

	var sim3 = Sim.new(7)
	sim3.open_shutter(290.0)
	sim3.accumulate(5.0, 0.2)
	var burnt: Dictionary = sim3.close_shutter(true)
	check(burnt.stars == 0 and burnt.fog == 1.0, "open at third contact ruins the plate")

	# Evidence classification + judgment.
	check(sim3.evidence_class() == "none", "nothing included → none")
	good.included = true
	check(sim.evidence_class() in ["favors_e", "ambiguous"], "one good plate → favors_e or ambiguous (%s)" % sim.evidence_class())
	var r_ok: Dictionary = Judgment.grade(sim, "hopeful", "measured")
	var r_over: Dictionary = Judgment.grade(sim, "confirmed", "corona")
	check(r_over.title == "過早的宣告", "overclaim gets the premature-announcement ending")
	check(r_ok.score > r_over.score, "hedged telegram scores above overclaim")
	var r_none: Dictionary = Judgment.grade(sim, "none", "nostars")
	check(r_none.title == "被丟下的星光", "'no results' with a usable plate is called out")
	# Omitting a good plate and reselecting are noticed.
	var sim4 = Sim.new(11)
	sim4.drive_wound = true
	sim4.drive_rate_checked = true
	var g4: Dictionary = sim4.gaps[2]
	var p1: Dictionary = expose(sim4, g4.t + 0.5, 4.0)
	var p2: Dictionary = expose(sim4, g4.t + 4.5 + sim4.PLATE_CHANGE_S, 4.0)
	p1.included = true
	sim4.reselected_after_seeing = true
	var rep: Dictionary = sim4.selection_report()
	if p2.quality == "good":
		check(rep.omitted_good.has(p2.number), "omitted good plate reported")
	check(rep.reselected, "reselection reported")
	check(not Judgment.grade(sim4, "hopeful", "measured").clean, "reselection breaks a clean selection")

	# Every telegram × reason × evidence combination produces text.
	for t in Judgment.TELEGRAMS:
		for r in Judgment.REASONS:
			var res: Dictionary = Judgment.grade(sim, t.id, r.id)
			check(res.lines.size() >= 2 and res.title != "", "grade %s/%s has lines and a title" % [t.id, r.id])

	print("%d checks, %d failures" % [checks, failures])
	quit(1 if failures > 0 else 0)
