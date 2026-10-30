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
	root3d.free()
	_finish()


func _finish() -> void:
	print("%d darkroom lantern checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
