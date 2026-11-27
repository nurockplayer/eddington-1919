extends "res://scripts/cambridge/madeira_ink.gd"
## Racecourse cuts and glass prints for the archival reconstruction.

const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Plate := preload("res://scripts/plate_render.gd")

var texture: ImageTexture
var detail := Vector2(0.5, 0.5)
var uncovered := true
var magnified := false
var flipped := false
var prominence := false
var beat := -1


func use_sky(source: ShaderMaterial) -> ShaderMaterial:
	var material := source.duplicate() as ShaderMaterial
	var viewport := SubViewport.new()
	viewport.size = Vector2i(640, 160)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var environment := Environment.new()
	environment.background_mode = Environment.BG_SKY
	environment.sky = Sky.new()
	environment.sky.sky_material = material
	var camera := Camera3D.new()
	camera.environment = environment
	camera.fov = 24.0
	viewport.add_child(camera)
	var direction := Vector3(0, 0.56, -0.83).normalized()
	camera.look_at_from_position(Vector3.ZERO, direction)
	material.set_shader_parameter("sun_dir", direction.rotated(Vector3.UP, -0.22))
	material.set_shader_parameter("sun_r", 0.039)
	material.set_shader_parameter("night", 0.0)
	material.set_shader_parameter("star_vis", 0.0)
	material.set_shader_parameter("third_contact", Vector2.ZERO)
	var sky_print := TextureRect.new()
	sky_print.texture = viewport.get_texture()
	sky_print.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sky_print.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sky_print.show_behind_parent = true
	sky_print.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sky_print)
	return material


func _draw() -> void:
	if subject == "glass":
		_glass()
		return
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(600, 160))
	match subject:
		"station", "sky", "dawn": _racecourse()
		"mailhat": _mailhat()
		"programme": _programme()
	draw_rect(Rect2(1, 1, 598, 158), WASH, false, 1)


func _racecourse() -> void:
	if subject != "sky":
		draw_rect(Rect2(1, 1, 598, 158), WASH.darkened(0.52) if subject == "dawn" else LIGHT)
		for y in range(16, 76, 6):
			_stroke([Vector2(8, y), Vector2(593, y)], WASH, 0.4)
	if subject == "dawn":
		for at in [Vector2(60, 14), Vector2(206, 37), Vector2(311, 14), Vector2(531, 27)]:
			draw_circle(at, 1.6, LIGHT, true, -1, true)
	var silhouette := INK.darkened(0.55) if subject == "sky" else INK
	draw_rect(Rect2(2, 114, 596, 45), WASH.darkened(0.26))
	_shape([Vector2(12, 76), Vector2(41, 57), Vector2(166, 57), Vector2(200, 76)], silhouette)
	draw_rect(Rect2(22, 76, 164, 41), silhouette)
	for i in 10:
		draw_rect(Rect2(29 + 15 * i, 80, 9, 18), WASH)
		_stroke([Vector2(24, 102 + i * 1.4), Vector2(184, 102 + i * 1.4)], WASH, 0.5)
	for station in [[247.0, 150.0, 13.0], [436.0, 106.0, 7.0]]:
		var x: float = station[0]
		var width: float = station[1]
		_shape([Vector2(x, 83), Vector2(x + 22, 67), Vector2(x + width - 14, 67),
			Vector2(x + width, 83)], silhouette)
		for post in [x + 8.0, x + width - 8.0]:
			_stroke([Vector2(post, 82), Vector2(post, 119)], silhouette, 2)
		var pier := Rect2(x + 22, 102, 19, 24)
		draw_rect(pier, silhouette)
		for y in [108, 114, 120]:
			_stroke([Vector2(x + 23, y), Vector2(x + 40, y)], WASH, 0.7)
		_stroke([Vector2(x + 22, 99), Vector2(x + 39, 88)], silhouette, 5)
		draw_rect(Rect2(x + 46, 93, width - 57, station[2]), silhouette)
		draw_rect(Rect2(x + width - 33, 105, 14, 17), silhouette)
		if subject == "dawn":
			_stroke([Vector2(x + 25, 102), Vector2(x + 35, 102)], LIGHT, 1.4)
	for i in 6:
		_stroke([Vector2(2, 130 + i * 3), Vector2(599, 119 + i * 7)], silhouette, 0.7)


func _mailhat() -> void:
	draw_rect(Rect2(2, 2, 596, 156), LIGHT)
	var centre := Vector2(187, 80)
	for i in 96:
		var angle := i * TAU / 96
		var direction := Vector2.from_angle(angle)
		var length := 35.0 + pow(absf(sin(angle + 0.3)), 3.0) * 22.0 + (i * 13) % 11
		_stroke([centre + direction * 29.0, centre + direction.rotated(0.1) * length], WASH, 0.8)
	draw_circle(centre, 29, INK, true, -1, true)
	# The print is an illustrative corona, with the independent instrument at right.
	_stroke([Vector2(356, 105), Vector2(504, 63)], INK, 10)
	_stroke([Vector2(418, 87), Vector2(398, 138)], INK, 3)
	_stroke([Vector2(418, 87), Vector2(449, 138)], INK, 3)
	_stroke([Vector2(418, 87), Vector2(421, 138)], INK, 3)


func _programme() -> void:
	draw_rect(Rect2(2, 2, 596, 156), LIGHT)
	for i in 19:
		var x := 28.0 + i * 29.5
		draw_rect(Rect2(x, 36, 18 if i % 2 else 10, 30), INK if (i + 1) * 320 <= beat * 19 else WASH)
	for i in 8:
		var x := 28.0 + i * 70.0
		draw_rect(Rect2(x, 95, 52, 30), INK if (i + 1) * 320 <= beat * 8 else WASH)
	for i in 11:
		var x := 28.0 + i * 54.5
		var active := beat >= 0 and i <= (10 if beat > 0 and beat % 10 == 0 else beat % 10)
		draw_circle(Vector2(x, 18), 4.0 if i in [0, 10] else 2.5, INK if active else WASH, true, -1, true)


func _glass() -> void:
	var side := minf(size.x - 40, size.y - 40)
	var rect := Rect2((size - Vector2.ONE * side) / 2, Vector2.ONE * side)
	draw_rect(Rect2(Vector2.ZERO, size), Color("544238"))
	Overlay.draw_glass(self, rect)
	if not uncovered:
		draw_rect(rect.grow(-2), WASH)
		for y in range(9, int(side), 6):
			draw_line(rect.position + Vector2(4, y), rect.position + Vector2(side - 4, y), INK, 0.4)
		return
	draw_set_transform(rect.get_center(), 0.0, Vector2(-1, 1) if flipped else Vector2.ONE)
	rect.position = -rect.size / 2.0
	if prominence:
		var radius := side * (0.38 if magnified else 0.31)
		draw_circle(Vector2(-side * 0.34, side * 0.26), radius, INK, true, -1, true)
		draw_arc(Vector2(-side * 0.08, -side * 0.02), side * 0.075, 3.65, 6.11, 24, INK, 4, true)
		for i in 8:
			draw_line(Vector2(-side * 0.5, side * (i / 9.0 - 0.4)),
				Vector2(side * 0.49, side * (i / 9.0 - 0.27)), WASH, 1.8, true)
	elif magnified:
		var crop := Vector2.ONE * Plate.SIZE * 0.24
		draw_texture_rect_region(texture, rect, Rect2(detail * Plate.SIZE - crop / 2, crop))
	else:
		draw_texture_rect(texture, rect, false)
