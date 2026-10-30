extends SceneTree
## Dust motes under the study lamp: present, faint, decoration only.
const Room := preload("res://scripts/cambridge/room_builder.gd")
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
	for departure in [false, true]:
		var room := Node3D.new()
		root.add_child(room)
		var world := Room.build(room, departure)
		var dust: CPUParticles3D = world.lamp_dust
		var lamp: OmniLight3D = world.lamp
		check(dust.emitting and dust.amount <= 48, "a small number of motes is emitting")
		check(dust.global_position.y < lamp.global_position.y and dust.global_position.distance_to(lamp.global_position) < 0.3, "motes sit in the cone under the lamp")
		# Worst case over a whole life: box edge plus full drift (no gravity).
		var drift := dust.initial_velocity_max * dust.lifetime + 0.5 * absf(dust.gravity.y) * dust.lifetime * dust.lifetime
		check(dust.global_position.y - dust.emission_box_extents.y - drift > 0.86, "motes never sink into the desk papers")
		check(dust.global_position.y + dust.emission_box_extents.y + drift < lamp.global_position.y + 0.08, "motes never rise into the shade")
		check(((dust.mesh as QuadMesh).material as StandardMaterial3D).billboard_keep_scale, "billboards keep the per-mote scale")
		check(dust.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "motes cast no shadows")
		var mat := (dust.mesh as QuadMesh).material as StandardMaterial3D
		check(mat.blend_mode == BaseMaterial3D.BLEND_MODE_ADD and mat.vertex_color_use_as_albedo, "motes glint additively with the ramp colour")
		check(dust.color_ramp.sample(0.0).a == 0.0 and dust.color_ramp.sample(1.0).a == 0.0, "motes fade in and out, never pop")
		check(dust.color_ramp.sample(0.5).a > 0.2, "motes are visible mid-life")
		var edge := dust.emission_box_extents + Vector3.ONE * dust.initial_velocity_max * dust.lifetime
		check(dust.visibility_aabb.has_point(edge * 0.99) and dust.visibility_aabb.has_point(-edge * 0.99), "culling box covers the whole drift volume")
		room.free()
	print("%d lamp dust checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
