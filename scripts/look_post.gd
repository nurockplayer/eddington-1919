extends CanvasLayer

const Settings := preload("res://scripts/settings.gd")
const SHADER := preload("res://shaders/look_post.gdshader")

var material: ShaderMaterial


func setup(vignette: float, grain: float) -> void:
	layer = 1
	add_to_group("look_post")
	material = ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("vignette", vignette)
	material.set_shader_parameter("grain", grain)
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.material = material
	add_child(rect)


func _process(_delta: float) -> void:
	if not Settings.reduced_motion:
		material.set_shader_parameter("grain_seed", floor(Time.get_ticks_msec() / 1000.0 * 24.0))
