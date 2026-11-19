extends Node
## Presentation-only endpoint renders; the director and exposure oracle keep
## their native light tween. Only visual instances are mirrored, never scripts.
var main: Node
var style: RefCounted
var elapsed := 0.0
var active := false
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
var composite_environment: Environment
var compositor: MeshInstance3D
var compositor_layers := 0
var native_sun_energy := 0.0
var day_sun_energy := 0.0
var native_print := {}


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
		quad.layers = 1 << 19
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
	_sync()


func warm() -> void:
	for viewport in plates:
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	# Compile both endpoint pipelines under second contact's opaque fade.
	RenderingServer.force_draw(false)
	RenderingServer.force_draw(false)
	for viewport in plates:
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
	RenderingServer.frame_pre_draw.connect(_draw_day)
	RenderingServer.frame_post_draw.connect(_restore_native)
	compositor.layers = 1 << 19
	main.player.camera.cull_mask = 1 << 19
	composite_environment = Environment.new()
	composite_environment.background_mode = Environment.BG_COLOR
	main.player.camera.environment = composite_environment
	style.quad_material.set_shader_parameter("return_night", plates[0].get_texture())
	style.quad_material.set_shader_parameter("return_day", plates[1].get_texture())
	style.quad_material.set_shader_parameter("return_band", deg_to_rad(style.params.return_width))
	style.quad_material.set_shader_parameter("day_return_active", true)
	for i in sources.size():
		if sources[i] == main.sun: day_sun_energy = mirrors[1][i].light_energy
	_sync()


func _draw_day() -> void:
	# Keep the exposure oracle's native tween; override only the rendered day.
	native_sun_energy = main.sun.light_energy
	main.sun.light_energy = day_sun_energy
	if settle_started < 0.0:
		for key in ["contact", "cloud_time", "third_contact_gap", "diamond"]:
			native_print[key] = style.quad_material.get_shader_parameter(key)
			style.quad_material.set_shader_parameter(key, materials[1].get_shader_parameter(key))


func _restore_native() -> void:
	main.sun.light_energy = native_sun_energy
	for key in native_print:
		style.quad_material.set_shader_parameter(key, native_print[key])
	native_print.clear()


func _sync() -> void:
	style.quad_material.set_shader_parameter("return_radius", radius())
	var farthest := 0.0
	var camera: Camera3D = main.player.camera
	var size := main.get_viewport().get_visible_rect().size
	var points := [Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)]
	var rays: Array[Vector3] = []
	var forward := -camera.global_basis.z
	for point in points:
		var ray := camera.project_ray_normal(point)
		rays.append(ray / ray.dot(forward))
		farthest = maxf(farthest, ray.angle_to(main.sim.sun_dir))
	for i in 4:
		var start := rays[i]
		var edge := rays[(i + 1) % 4] - start
		var a: float = main.sim.sun_dir.dot(start)
		var b: float = main.sim.sun_dir.dot(edge)
		var denominator := b * start.dot(edge) - a * edge.length_squared()
		if not is_zero_approx(denominator):
			var t := (a * start.dot(edge) - b * start.length_squared()) / denominator
			if t > 0.0 and t < 1.0:
				farthest = maxf(farthest, (start + t * edge).angle_to(main.sim.sun_dir))
	var opposite: Vector3 = camera.global_position - main.sim.sun_dir * 1000.0
	if not camera.is_position_behind(opposite) and Rect2(Vector2.ZERO, size).has_point(camera.unproject_position(opposite)):
		farthest = PI
	var view_is_day := elapsed >= 3.0 and radius() - deg_to_rad(style.params.return_width) >= farthest
	if view_is_day:
		if settle_started < 0.0: settle_started = elapsed
	else:
		settle_started = -1.0
	var blend := -1.0 if settle_started < 0.0 else smoothstep(0.0, 1.5, elapsed - settle_started)
	style.quad_material.set_shader_parameter("return_blend", blend)
	if active:
		plates[0].render_target_update_mode = SubViewport.UPDATE_DISABLED if view_is_day else SubViewport.UPDATE_ALWAYS
		plates[1].render_target_update_mode = SubViewport.UPDATE_ALWAYS if view_is_day else SubViewport.UPDATE_DISABLED
		# The native depth/normal buffers draw daylight silhouettes for the
		# entire return. No geometry renderer changes at the start of the ease.
		camera.cull_mask = camera_mask if started() else 1 << 19
		camera.environment = camera_environment if view_is_day else cameras[1].environment
		compositor.layers = compositor_layers
		cameras[1].cull_mask = 1 << 19
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
		style.quad_material.set_shader_parameter("return_blend", -1.0)
		style.quad_material.set_shader_parameter("day_return_active", false)
		queue_free()
		return
	_sync()


func _exit_tree() -> void:
	if active:
		RenderingServer.frame_pre_draw.disconnect(_draw_day)
		RenderingServer.frame_post_draw.disconnect(_restore_native)
	if is_instance_valid(main.player.camera):
		main.player.camera.cull_mask = camera_mask
		main.player.camera.environment = camera_environment
	if is_instance_valid(compositor): compositor.layers = compositor_layers
