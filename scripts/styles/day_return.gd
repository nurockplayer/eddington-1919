extends Node
## Presentation-only endpoint renders; the director and exposure oracle keep
## their native light tween. Only visual instances are mirrored, never scripts.
var main: Node
var style: RefCounted
var elapsed := 0.0
var active := false
var live_sky: SubViewport
var live_camera: Camera3D
var plates: Array[SubViewport] = []
var cameras: Array[Camera3D] = []
var materials: Array[ShaderMaterial] = []
var skies: Array[ShaderMaterial] = []
var sources: Array[VisualInstance3D] = []
var mirrors: Array = []
var frozen_cloud := 0.0
var settle_started := -1.0
var camera_mask := 0
var camera_environment: Environment
var compositor: MeshInstance3D
var compositor_layers := 0


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
	compositor = main.get_tree().get_first_node_in_group("style_quad")
	compositor_layers = compositor.layers
	camera_mask = main.player.camera.cull_mask
	camera_environment = main.player.camera.environment
	for index in 2:
		var viewport := SubViewport.new()
		viewport.own_world_3d = true
		viewport.size = main.get_viewport().size
		viewport.msaa_3d = main.get_viewport().msaa_3d
		viewport.scaling_3d_scale = main.get_viewport().scaling_3d_scale
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
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
	# The ease needs two sky prints, but only one geometry/light/shadow pass.
	live_sky = SubViewport.new()
	live_sky.own_world_3d = true
	live_sky.size = main.get_viewport().size
	live_sky.use_hdr_2d = true
	live_sky.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(live_sky)
	live_camera = Camera3D.new()
	live_camera.environment = main.env
	live_sky.add_child(live_camera)
	materials[1].set_shader_parameter("return_live_sky", live_sky.get_texture())
	_sync()


func warm() -> void:
	for viewport in plates + [live_sky]:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Compile both endpoint pipelines under second contact's opaque fade.
	RenderingServer.force_draw(false)
	RenderingServer.force_draw(false)
	for viewport in plates + [live_sky]:
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


func activate() -> void:
	active = true
	elapsed = 0.0
	frozen_cloud = main.t_game - 0.5 * main.sim.TIME_SCALE
	for index in 2:
		var cloud_t: float = frozen_cloud if index == 0 else main.t_game + 10.0
		skies[index].set_shader_parameter("cloud_time", cloud_t)
		materials[index].set_shader_parameter("cloud_time", cloud_t)
		skies[index].set_shader_parameter("third_contact_gap", main.sky_mat.get_shader_parameter("third_contact_gap"))
		for i in sources.size():
			if sources[i] == main.sun:
				var density: float = main.sim.cloud_over_sun(cloud_t)
				mirrors[index][i].light_energy = 0.0 if index == 0 else (style.params.sun_floor + 1.4 * main._crescent(0.8) * (1.0 - density * 0.85)) * main._look_sun
	compositor.layers = 1 << 19
	main.player.camera.cull_mask = 1 << 19
	var empty := Environment.new()
	empty.background_mode = Environment.BG_COLOR
	main.player.camera.environment = empty
	style.quad_material.set_shader_parameter("return_night", plates[0].get_texture())
	style.quad_material.set_shader_parameter("return_day", plates[1].get_texture())
	style.quad_material.set_shader_parameter("return_band", deg_to_rad(style.params.return_width))
	style.quad_material.set_shader_parameter("day_return_active", true)
	_sync()


func _sync() -> void:
	style.quad_material.set_shader_parameter("return_radius", radius())
	var farthest := 0.0
	var camera: Camera3D = main.player.camera
	for corner in [Vector2.ZERO, Vector2(main.get_viewport().size.x, 0), Vector2(main.get_viewport().size), Vector2(0, main.get_viewport().size.y)]:
		farthest = maxf(farthest, camera.project_ray_normal(corner).angle_to(main.sim.sun_dir))
	var view_is_day := elapsed >= 3.0 and radius() - deg_to_rad(style.params.return_width) >= farthest
	if view_is_day:
		if settle_started < 0.0: settle_started = elapsed
	else:
		settle_started = -1.0
	var blend := -1.0 if settle_started < 0.0 else smoothstep(0.0, 1.5, elapsed - settle_started)
	style.quad_material.set_shader_parameter("return_blend", blend)
	materials[1].set_shader_parameter("return_blend", blend)
	if active:
		plates[0].render_target_update_mode = SubViewport.UPDATE_DISABLED if view_is_day else SubViewport.UPDATE_ALWAYS
		plates[1].render_target_update_mode = SubViewport.UPDATE_ALWAYS if started() else SubViewport.UPDATE_DISABLED
		live_sky.render_target_update_mode = SubViewport.UPDATE_ALWAYS if view_is_day else SubViewport.UPDATE_DISABLED
	live_sky.size = main.get_viewport().size
	live_camera.global_transform = camera.global_transform
	live_camera.fov = camera.fov
	live_camera.near = camera.near
	live_camera.far = camera.far
	for index in 2:
		plates[index].size = main.get_viewport().size
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
	if not active: return
	elapsed += delta
	if settle_started >= 0.0 and elapsed >= maxf(3.0, settle_started + 1.5) and radius() > PI + deg_to_rad(style.params.return_width):
		style.quad_material.set_shader_parameter("day_return_active", false)
		queue_free()
		return
	_sync()


func _exit_tree() -> void:
	if is_instance_valid(main.player.camera):
		main.player.camera.cull_mask = camera_mask
		main.player.camera.environment = camera_environment
	if is_instance_valid(compositor): compositor.layers = compositor_layers
