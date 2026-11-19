extends Node
## Presentation-only endpoint renders; the director and exposure oracle keep
## their native light tween. Only visual instances are mirrored, never scripts.
var main: Node
var style: RefCounted
var elapsed := 0.0
var plates: Array[SubViewport] = []
var cameras: Array[Camera3D] = []
var materials: Array[ShaderMaterial] = []
var skies: Array[ShaderMaterial] = []
var sources: Array[VisualInstance3D] = []
var mirrors: Array = []
var frozen_cloud := 0.0


func started() -> bool:
	return elapsed >= 0.24 + style.params.return_delay


func radius() -> float:
	if not started():
		return -1.0
	return main.sim.SUN_R + (elapsed - 0.24 - style.params.return_delay) * (PI / 2.0 - main.sim.SUN_R) / style.params.return_seconds


func setup(game: Node, print_style: RefCounted) -> void:
	main = game
	style = print_style
	frozen_cloud = main.t_game - 0.5 * main.sim.TIME_SCALE
	for visual in main.find_children("*", "VisualInstance3D", true, false):
		if not visual.is_in_group("style_quad"):
			sources.append(visual)
	for index in 2:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = main.get_viewport().get_visible_rect().size
		viewport.msaa_3d = main.get_viewport().msaa_3d
		viewport.scaling_3d_scale = main.get_viewport().scaling_3d_scale
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		add_child(viewport)
		plates.append(viewport)
		var copies: Array[VisualInstance3D] = []
		for source in sources:
			var copy: VisualInstance3D = source.duplicate(0)
			for child in copy.get_children():
				copy.remove_child(child)
				child.free()
			viewport.add_child(copy)
			copy.global_transform = source.global_transform
			if source is MeshInstance3D and source.get_skin_reference() != null:
				RenderingServer.instance_attach_skeleton(copy.get_instance(), source.get_skin_reference().get_skeleton())
			if source == main.sun:
				var density: float = main.sim.cloud_over_sun(main.t_game + 10.0)
				copy.light_energy = 0.0 if index == 0 else (style.params.sun_floor + 1.4 * main._crescent(0.8) * (1.0 - density * 0.85)) * main._look_sun
			copies.append(copy)
		mirrors.append(copies)
		var environment: Environment = main.env.duplicate(true)
		var dark := 1.0 if index == 0 else 0.0
		environment.ambient_light_color = Color(0.55, 0.57, 0.6).lerp(Color(0.10, 0.11, 0.17), dark)
		environment.ambient_light_energy = lerpf(1.0, 0.55, dark) * main._look_ambient
		environment.fog_light_color = Color(0.62, 0.65, 0.68).lerp(Color(0.07, 0.08, 0.12), dark)
		var sky: ShaderMaterial = environment.sky.sky_material
		sky.set_shader_parameter("darkness", dark)
		sky.set_shader_parameter("star_vis", dark)
		sky.set_shader_parameter("contact", 1.0 if index == 0 else 0.8)
		sky.set_shader_parameter("cloud_time", frozen_cloud if index == 0 else main.t_game + 10.0)
		skies.append(sky)
		var camera := Camera3D.new()
		camera.environment = environment
		viewport.add_child(camera)
		cameras.append(camera)
		var quad := MeshInstance3D.new()
		quad.mesh = (main.get_tree().get_first_node_in_group("style_quad") as MeshInstance3D).mesh
		quad.extra_cull_margin = 16384.0
		var material: ShaderMaterial = style.quad_material.duplicate()
		material.set_shader_parameter("day_return_active", false)
		material.set_shader_parameter("darkness", dark)
		material.set_shader_parameter("contact", 1.0 if index == 0 else 0.8)
		material.set_shader_parameter("cloud_time", frozen_cloud if index == 0 else main.t_game + 10.0)
		material.set_shader_parameter("third_contact_gap", 0.0)
		quad.material_override = material
		viewport.add_child(quad)
		materials.append(material)
	style.quad_material.set_shader_parameter("return_night", plates[0].get_texture())
	style.quad_material.set_shader_parameter("return_day", plates[1].get_texture())
	style.quad_material.set_shader_parameter("return_band", deg_to_rad(style.params.return_width))
	style.quad_material.set_shader_parameter("day_return_active", true)
	_sync()


func _sync() -> void:
	style.quad_material.set_shader_parameter("return_radius", radius())
	for index in 2:
		plates[index].size = main.get_viewport().get_visible_rect().size
		cameras[index].global_transform = main.player.camera.global_transform
		cameras[index].fov = main.player.camera.fov
		cameras[index].near = main.player.camera.near
		cameras[index].far = main.player.camera.far
		for i in sources.size():
			mirrors[index][i].global_transform = sources[i].global_transform
			mirrors[index][i].visible = sources[i].is_visible_in_tree()
	# Keep #387's diamond/ruling until the white covers them. Its native
	# uniforms are read independently of whether cloud hides the diamond.
	materials[0].set_shader_parameter("diamond", main.sky_mat.get_shader_parameter("third_contact").y)
	materials[0].set_shader_parameter("contact", main.sky_mat.get_shader_parameter("contact"))
	materials[0].set_shader_parameter("cloud_time", main.sky_mat.get_shader_parameter("cloud_time"))
	materials[0].set_shader_parameter("third_contact_gap", main.sky_mat.get_shader_parameter("third_contact_gap"))
	skies[0].set_shader_parameter("third_contact", main.sky_mat.get_shader_parameter("third_contact"))
	skies[0].set_shader_parameter("third_contact_gap", main.sky_mat.get_shader_parameter("third_contact_gap"))


func _process(delta: float) -> void:
	elapsed += delta
	if elapsed >= maxf(3.0, 0.24 + style.params.return_delay + (PI + deg_to_rad(style.params.return_width)) * style.params.return_seconds / (PI / 2.0 - main.sim.SUN_R)):
		style.quad_material.set_shader_parameter("day_return_active", false)
		queue_free()
		return
	_sync()
