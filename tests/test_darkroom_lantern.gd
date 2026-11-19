extends SceneTree
## The darkroom safelight has a visible ruby lantern whose glass follows the light.
const World := preload("res://scripts/world_builder.gd")
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
	var root3d := Node3D.new()
	root.add_child(root3d)
	var out: Dictionary = World.new(root3d).build()
	var glass: MeshInstance3D = out.get("safelight_glass")
	var safe: OmniLight3D = out.safelight
	check(glass != null and glass.is_inside_tree(), "the safelight lantern's glass is built")
	if glass == null:
		_finish()
		return
	check(glass.light == safe, "the glass follows the darkroom safelight")
	check(glass.global_position.distance_to(safe.global_position) < 0.1, "the glass sits at the light")
	# Its pane faces the room, not the back wall behind the bench.
	check(glass.global_position.z > safe.global_position.z, "the pane is on the room side")
	var m := glass.material_override as StandardMaterial3D
	safe.light_energy = 0.5
	await process_frame
	await process_frame  # SceneTree.process_frame fires before nodes process
	check(m.emission_enabled and m.emission.r > m.emission.g * 4.0, "the glass glows ruby red")
	check(is_equal_approx(m.emission_energy_multiplier, 0.5 * glass.GLOW), "glow tracks the light: %.2f" % m.emission_energy_multiplier)
	safe.light_energy = 0.0
	await process_frame
	await process_frame  # SceneTree.process_frame fires before nodes process
	check(is_equal_approx(m.emission_energy_multiplier, 0.0), "the glass goes dark with the coda fade")
	var lantern: Node3D = out.oxford_lantern
	var flame: OmniLight3D = out.oxford_lantern_light
	check(not lantern.visible and flame.light_energy == 0.0, "the camp lantern is stowed before night")
	check(is_equal_approx(lantern.position.y, 0.83), "the hurricane lantern stands on the bench")
	check(flame.omni_range == 3.5 and flame.shadow_enabled, "the lantern has a local shadowed pool")
	check(flame.light_cull_mask == 2, "the lantern lights only its bench layer")
	var receivers := 0
	for mesh in root3d.find_children("*", "MeshInstance3D", true, false):
		if mesh.layers & flame.light_cull_mask:
			receivers += 1
			var p: Vector3 = mesh.global_position
			check(p.y >= 0.799 and p.x >= -2.651 and p.x <= -1.349 and p.z >= -3.451 and p.z <= -3.129, "only the bench top and its objects receive the lantern: %s" % p)
	check(receivers == 15, "all fifteen bench and lantern meshes receive the light: %d" % receivers)
	var globe := lantern.get_node("OxfordLanternGlass")
	flame.light_energy = 8.0
	await process_frame
	await process_frame
	var glow := globe.material_override as StandardMaterial3D
	check(glow.emission.r > 0.9 and glow.emission.g > 0.9, "the camp lantern glows neutral paper light")
	check(is_equal_approx(glow.emission_energy_multiplier, 8.0 * globe.GLOW), "the globe follows its own flame")
	root3d.free()
	_finish()


func _finish() -> void:
	print("%d darkroom lantern checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
