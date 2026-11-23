extends SceneTree
## Select real field states for the cloud-truth capture evidence.
const Sim := preload("res://scripts/eclipse_sim.gd")

func _initialize() -> void:
	for seed_ in [7, 1919]:
		var sim := Sim.new(seed_)
		var clear_t := 0.0
		var thin_t := 0.0
		for i in range(1201):
			var t := i * 0.25
			if sim.cloud_over_sun(t) < sim.cloud_over_sun(clear_t):
				clear_t = t
			if absf(sim.cloud_over_sun(t) - 0.48) < absf(sim.cloud_over_sun(thin_t) - 0.48):
				thin_t = t
		for state in [["clear", clear_t], ["thin", thin_t], ["thick", 151.0]]:
			print(JSON.stringify({"seed": seed_, "state": state[0], "cloud_t": state[1], "cloud_over_sun": sim.cloud_over_sun(state[1])}))
	quit()
