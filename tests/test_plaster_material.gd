extends SceneTree
## Regression check for the Cambridge room's soft, broad plaster weathering.
## Run: godot --headless --path . --script res://tests/test_plaster_material.gd

const Room := preload("res://scripts/cambridge/room_builder.gd")


func _initialize() -> void:
	var material: StandardMaterial3D = Room._plaster_material(Color(0.43, 0.40, 0.34))
	var texture := material.detail_albedo as NoiseTexture2D
	var noise := texture.noise as FastNoiseLite
	var colors: PackedColorArray = texture.color_ramp.colors
	var min_value := 1.0
	var max_value := 0.0
	for color in colors:
		min_value = minf(min_value, color.r)
		max_value = maxf(max_value, color.r)
	var ok := material.detail_enabled \
		and material.uv2_world_triplanar \
		and noise.frequency <= 0.01 \
		and noise.fractal_octaves <= 2 \
		and max_value - min_value <= 0.07
	if not ok:
		push_error("Cambridge plaster weathering must remain broad, soft, and low contrast")
		quit(1)
		return
	print("PASS: Cambridge plaster weathering is broad, soft, and low contrast")
	quit(0)
