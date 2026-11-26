extends Control
## Small ink vignettes on the journey papers. The routes are schematic.

const INK := Color(0.24, 0.17, 0.11)
const WASH := Color(0.73, 0.62, 0.45)
const LIGHT := Color(0.91, 0.85, 0.73)
const Book := preload("res://scripts/cambridge/departure_props.gd")

var subject := ""
var steps := 0
var last_leg := 1.0:
	set(value):
		last_leg = value
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(600, 160))
	draw_rect(Rect2(1, 1, 598, 158), LIGHT)
	match subject:
		"hotel", "window", "wait":
			_hotel()
		"dock", "principe_folder":
			_dock()
		_:
			_route()
	draw_rect(Rect2(1, 1, 598, 158), WASH, false, 1)


func _stroke(points: PackedVector2Array, colour := INK, width := 2.0) -> void:
	draw_polyline(points, colour, width, true)


func _shape(points: PackedVector2Array, colour: Color) -> void:
	draw_colored_polygon(points, colour)
	points.append(points[0])
	_stroke(points)


func _route() -> void:
	for y in range(20, 150, 18):
		for x in range(22 + (y % 28), 550, 85):
			_stroke([Vector2(x, y), Vector2(x + 13, y - 3), Vector2(x + 29, y)], WASH, 0.8)
	var stops := PackedVector2Array([Vector2(75, 100), Vector2(270, 45), Vector2(485, 92)])
	match subject:
		"sobral":
			stops = [Vector2(520, 30), Vector2(390, 93), Vector2(120, 119), Vector2(217, 96), Vector2(277, 133)]
		"passage":
			stops = [Vector2(84, 33), Vector2(234, 91), Vector2(286, 118), Vector2(520, 129)]
	for i in mini(steps, stops.size()):
		if i > 0:
			_leg(stops[i - 1], stops[i], last_leg if i == steps - 1 and subject != "split" else 1.0)
		else:
			draw_circle(stops[i], 4, INK, true, -1.0, true)
	if subject == "split":
		_leg(stops[2], Vector2(555, 41), last_leg)
		_leg(stops[2], Vector2(555, 128), last_leg)


func _leg(from: Vector2, to: Vector2, progress: float) -> void:
	var curve := Curve2D.new()
	curve.add_point(from, Vector2.ZERO, Vector2((to.x - from.x) * 0.35, (to.y - from.y) * 0.15))
	curve.add_point(to, Vector2((from.x - to.x) * 0.35, (from.y - to.y) * 0.15))
	var length := curve.get_baked_length()
	var points := PackedVector2Array()
	for i in 17:
		points.append(curve.sample_baked(length * progress * i / 16.0))
	_stroke(points, INK, 2.4)
	draw_circle(points[-1], 4.0, INK, true, -1.0, true)


func _hotel() -> void:
	var window := Rect2(194, 8, 211, 87) if subject == "window" else Rect2(218, 8, 165, 82)
	draw_rect(window, Color(0.64, 0.59, 0.54) if subject in ["wait", "window"] else Color(0.82, 0.75, 0.59))
	var left := window.position.x
	var right := window.end.x
	_stroke([Vector2(left, 45), Vector2(left + 38, 33), Vector2(left + 81, 55), Vector2(right, 66)], WASH)
	for x in range(int(left) + 5, int(right) - 7, 12):
		draw_line(Vector2(x, 65), Vector2(x + 6, 66), LIGHT, 2)
	draw_rect(window, INK, false, 3)
	draw_line(Vector2(window.get_center().x, 8), Vector2(window.get_center().x, window.end.y), INK, 3)
	draw_line(Vector2(left, 57), Vector2(right, 57), INK, 2)
	for x in [133, 425]:
		_shape([Vector2(x, 114), Vector2(x + 2, 71), Vector2(x + 44, 71), Vector2(x + 51, 112)], WASH)
		for slat in [11, 20, 29, 38]:
			draw_line(Vector2(x + slat, 75), Vector2(x + slat, 106), INK)
	_shape([Vector2(64, 155), Vector2(106, 102), Vector2(479, 102), Vector2(534, 155)], WASH)
	for y in [116, 134, 150]:
		draw_line(Vector2(99, y), Vector2(502, y), LIGHT)
	var cup := Vector2(337, 132) if subject == "wait" else Vector2(376, 117)
	draw_set_transform(cup * size / Vector2(600, 160), 0, size / Vector2(600, 160))
	draw_arc(Vector2(13, -4), 5, -PI / 2, PI / 2, 12, INK, 1.5, true)
	draw_circle(Vector2.ZERO, 17, LIGHT, true, -1, true)
	draw_circle(Vector2.ZERO, 11, INK, false, 1.3, true)
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(600, 160))
	_shape([Vector2(205, 127), Vector2(221, 110), Vector2(287, 108), Vector2(278, 129)], LIGHT)


func _dock() -> void:
	for y in range(29, 100, 9):
		for x in range(14 + (y % 20), 560, 76):
			_stroke([Vector2(x, y), Vector2(x + 38, y - 2)], WASH, 1)
	_shape([Vector2(596, 31), Vector2(304, 31), Vector2(265, 52), Vector2(320, 76), Vector2(596, 76)], WASH)
	for x in range(323, 577, 12):
		_stroke([Vector2(x, 71), Vector2(x + 7, 61)], INK, 0.8)
	for x in [458, 503, 548]:
		var crate := Rect2(x, 31, 36, 21)
		draw_rect(crate, LIGHT)
		draw_rect(crate, INK, false, 1.5)
		_stroke([crate.position + Vector2(8, 0), crate.position + Vector2(8, 21)], INK, 1)
	_stroke([Vector2(265, 52), Vector2(596, 52)])
	var quay_left := Vector2(4, 109)
	var quay_corner := Vector2(518, 93)
	_shape([quay_left, quay_corner, Vector2(596, 123), Vector2(596, 155), Vector2(4, 155)], WASH)
	_stroke([quay_left + Vector2(0, 17), quay_corner + Vector2(0, 17), Vector2(596, 140)], INK, 1)
	for x in range(12, 515, 12):
		var edge := quay_left.lerp(quay_corner, (x - quay_left.x) / (quay_corner.x - quay_left.x))
		_stroke([edge + Vector2(0, 15), edge + Vector2(8, 4)], INK, 0.8)
	if subject == "principe_folder":
		var base := Vector2(72, 140).lerp(Vector2(336, 52), last_leg)
		var lid := base - Vector2(0, 33)
		_shape([lid, lid + Vector2(109, 0), base + Vector2(109, 0), base], LIGHT)
		draw_arc(lid + Vector2(54, 0), 9, PI, TAU, 16, INK, 2, true)
		_stroke([lid + Vector2(0, 10), lid + Vector2(109, 10)], INK, 1)
		for x in [16, 93]:
			_stroke([lid + Vector2(x, 0), base + Vector2(x, 0)], INK, 2)
	elif last_leg < 0.5:
		_shape([Vector2(48, 123), Vector2(66, 108), Vector2(190, 104), Vector2(177, 122)], LIGHT)


static func print_view(parent: Node, world: Node3D, target: Vector3, distance: Vector3, width: float) -> SubViewport:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 200)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent.add_child(viewport)
	viewport.add_child(world)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = width
	viewport.add_child(camera)
	camera.position = target + distance
	camera.look_at(target)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 26, 0)
	light.light_energy = 1.5
	viewport.add_child(light)
	return viewport


static func workbook_print(parent: Control, opened: bool, on_crate := false) -> void:
	var mount := TextureRect.new()
	mount.custom_minimum_size.y = 126
	mount.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mount.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(mount)
	var book := Book.new()
	var world := Node3D.new()
	world.add_child(book)
	if on_crate:
		var crate := MeshInstance3D.new()
		var wood := BoxMesh.new()
		wood.size = Vector3(0.59, 0.12, 0.44)
		var material := StandardMaterial3D.new()
		material.albedo_color = WASH
		wood.material = material
		crate.mesh = wood
		crate.position.y = -0.078
		world.add_child(crate)
	var viewport := print_view(mount, world, Vector3(0, 0.03, 0), Vector3(0.5, 1.05, 0.85), 0.54)
	mount.texture = viewport.get_texture()
	if opened:
		book.open_workbook(0.0)
