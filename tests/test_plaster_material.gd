extends SceneTree
## Regression checks for Cambridge plaster and smooth night glazing in M1/M2.
## Run: godot --headless --path . --script res://tests/test_plaster_material.gd

const Room := preload("res://scripts/cambridge/room_builder.gd")

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _soft_plaster(material: StandardMaterial3D) -> bool:
	if material == null or not material.detail_albedo is NoiseTexture2D:
		return false
	var texture := material.detail_albedo as NoiseTexture2D
	var noise := texture.noise as FastNoiseLite
	var min_value := 1.0
	var max_value := 0.0
	for color in texture.color_ramp.colors:
		min_value = minf(min_value, color.r)
		max_value = maxf(max_value, color.r)
	return material.detail_enabled and material.uv2_world_triplanar \
		and noise.frequency <= 0.01 and noise.fractal_octaves <= 2 \
		and max_value - min_value <= 0.07


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	var material: StandardMaterial3D = Room._plaster_material(Color(0.43, 0.40, 0.34))
	_check(_soft_plaster(material), "Cambridge plaster must remain broad, soft, and low contrast")
	for departure in [false, true]:
		var room := Node3D.new()
		root.add_child(room)
		var built := Room.build(room, departure)
		for wall_name in ["CorridorPlasterLeft", "CorridorPlasterRight", "CorridorPlasterEnd"]:
			var wall := room.get_node(wall_name).get_child(1) as MeshInstance3D
			_check(_soft_plaster(wall.material_override), "%s must use soft plaster" % wall_name)
		for i in range(3):
			var pane := room.get_node("WindowPane%d" % i) as MeshInstance3D
			var glass := pane.material_override as StandardMaterial3D
			_check(glass == built.window_glass and not glass.detail_enabled \
				and not glass.albedo_texture is NoiseTexture2D,
				"M1/M2 window panes must have smooth glazing without camouflage noise")
			_check(glass.albedo_color.b > glass.albedo_color.r,
				"Night glass must retain its cool blue-black tone")
		var lamp := room.get_node_or_null("DepartureStreetLampPoint") as MeshInstance3D
		_check((lamp != null) == departure, "Only departure night exposes the street lamp")
		if lamp != null:
			var halo := (lamp.material_override as StandardMaterial3D).albedo_texture as GradientTexture2D
			_check(halo != null and halo.fill == GradientTexture2D.FILL_RADIAL \
				and halo.gradient.get_color(halo.gradient.get_point_count() - 1).a == 0.0,
				"Street lamp must soften to a transparent halo")
		var stars := room.get_node_or_null("DepartureWindowStars") as MultiMeshInstance3D
		_check((stars != null) == departure, "Only departure night shows stars through the window")
		if stars != null:
			var spots: Array = stars.get_meta("spots")
			_check(spots.size() == Room.WINDOW_STARS and stars.multimesh.instance_count == spots.size(),
				"Window stars: all %d placed" % Room.WINDOW_STARS)
			var clear := true
			for p in spots:
				clear = clear and p.y > 2.1 and p.y < 2.925 and p.x > -1.275 and p.x < 2.375 \
					and Vector2(p.x - lamp.position.x, p.y - lamp.position.y).length() >= 0.34
			_check(clear, "Window stars sit in the upper sash, clear of the lamp halo")
			_check(stars.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF,
				"Window stars cast no shadow")
		room.free()
	if failures == 0:
		print("PASS: Cambridge room/corridor plaster is broad, soft, and low contrast; M1/M2 glass is smooth; departure lamp has a soft halo")
	quit(1 if failures else 0)
