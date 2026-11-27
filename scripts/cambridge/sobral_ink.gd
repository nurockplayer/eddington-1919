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


func _draw() -> void:
	if subject == "glass":
		_glass()
		return
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(600, 160))
	draw_rect(Rect2(1, 1, 598, 158), LIGHT)
	match subject:
		"station", "first_contact", "totality", "dawn": _racecourse()
		"corona": _draw_sun(Vector2(300, 80), 36, true)
		"mailhat": _mailhat()
		"metronome", "astrograph", "four_inch": _programme()
	draw_rect(Rect2(1, 1, 598, 158), WASH, false, 1)


func _round_scale() -> Vector2:
	var stretch := size / Vector2(600, 160)
	return Vector2.ONE * minf(stretch.x, stretch.y) / stretch


func _racecourse() -> void:
	if subject == "dawn":
		draw_rect(Rect2(1, 1, 598, 158), WASH.darkened(0.52))
	elif subject == "totality" and beat >= 0:
		draw_rect(Rect2(1, 1, 598, 158), LIGHT.lerp(WASH, 0.4))
	for y in range(16, 76, 6):
		_stroke([Vector2(8, y), Vector2(593, y)], WASH, 0.4)
	match subject:
		"first_contact":
			_draw_sun(Vector2(393, 31), 20, false, 37)
			_cloud(Vector2(2, 4), 1.34)
			_cloud(Vector2(245, 19), 1.36)
			_cloud(Vector2(74, 35), 1.12)
		"totality":
			_cloud(Vector2(9, 4), 0.83)
			_cloud(Vector2(456, 12), 0.73)
			_draw_sun(Vector2(389, 34), 16, beat >= 0, 5)
			if beat == 160:
				_cloud(Vector2(310, 43), 0.55)
			if beat == 320:
				_round_disc(Vector2(389, 34) + Vector2(15, -6) * _round_scale(), 3, LIGHT)
		"dawn":
			for at in [Vector2(60, 14), Vector2(206, 37), Vector2(311, 14), Vector2(531, 27)]:
				_round_disc(at, 2.0, LIGHT)
	var silhouette := INK
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


func _cloud(at: Vector2, span: float) -> void:
	var ridge := PackedVector2Array([
		Vector2(0, 30), Vector2(15, 24), Vector2(35, 22), Vector2(49, 13),
		Vector2(68, 10), Vector2(86, 12), Vector2(103, 4), Vector2(122, 2),
		Vector2(141, 7), Vector2(156, 17), Vector2(174, 15), Vector2(190, 18),
		Vector2(208, 25), Vector2(231, 30),
	])
	var contour := PackedVector2Array()
	for point in ridge:
		contour.append(at + point * Vector2(span, 1))
	contour.append(at + Vector2(219 * span, 34))
	contour.append(at + Vector2(48 * span, 36))
	draw_colored_polygon(contour, WASH.lightened(0.13))
	_stroke(contour, WASH.darkened(0.18), 0.7)
	for i in range(2, 12):
		var point := at + ridge[i] * Vector2(span, 1)
		_stroke([point + Vector2(1, 5), point + Vector2(17 * span, 9)], LIGHT, 1.0)


func _round_disc(centre: Vector2, radius: float, colour: Color) -> void:
	draw_set_transform(centre * size / Vector2(600, 160), 0.0,
		Vector2.ONE * minf(size.x / 600.0, size.y / 160.0))
	draw_circle(Vector2.ZERO, radius, colour, true, -1, true)
	draw_set_transform(Vector2.ZERO, 0.0, size / Vector2(600, 160))


func _draw_sun(centre: Vector2, radius: float, total: bool, moon_offset := 0) -> void:
	var aspect := _round_scale()
	if total:
		for i in 96:
			var angle := i * TAU / 96
			var direction := Vector2.from_angle(angle)
			var length := radius * (1.2 + 0.46 * pow(absf(sin(angle + 0.3)), 3.0) + (i * 13) % 11 * 0.026)
			_stroke([centre + direction * radius * aspect,
				centre + direction.rotated(0.1) * length * aspect], WASH.darkened(0.17), 0.8)
		_round_disc(centre, radius, INK)
	else:
		_round_disc(centre, radius, WASH.darkened(0.3))
		_round_disc(centre + Vector2(moon_offset, -2) * aspect, radius, LIGHT)


func _mailhat() -> void:
	# Brass objective cell, focusing drawtube and plate holder on a braced stand.
	_stroke([Vector2(290, 90), Vector2(242, 140)], INK, 7)
	_stroke([Vector2(290, 90), Vector2(350, 140)], INK, 7)
	_stroke([Vector2(290, 90), Vector2(296, 146)], INK, 5)
	_stroke([Vector2(257, 126), Vector2(331, 126)], WASH, 3)
	draw_rect(Rect2(276, 80, 31, 25), INK)
	_shape([Vector2(188, 97), Vector2(412, 35), Vector2(423, 61), Vector2(199, 112)], WASH)
	_stroke([Vector2(208, 100), Vector2(401, 50)], LIGHT, 2)
	_shape([Vector2(174, 98), Vector2(195, 92), Vector2(203, 110), Vector2(182, 116)], WASH.darkened(0.2))
	_shape([Vector2(153, 96), Vector2(174, 91), Vector2(185, 120), Vector2(163, 126)], INK)
	_shape([Vector2(397, 34), Vector2(424, 26), Vector2(438, 59), Vector2(411, 67)], WASH.darkened(0.29))
	_shape([Vector2(422, 26), Vector2(433, 31), Vector2(442, 49), Vector2(438, 59),
		Vector2(426, 54), Vector2(418, 36)], INK)
	_stroke([Vector2(427, 31), Vector2(435, 44)], LIGHT, 1.5)


func _programme() -> void:
	match subject:
		"astrograph":
			for i in 19:
				var x := 18.0 + i * 30.5
				draw_rect(Rect2(x, 46, 20 if i % 2 else 10, 68),
					INK if (i + 1) * 320 <= beat * 19 else WASH)
		"four_inch":
			for i in 8:
				var x := 18.0 + i * 73.0
				draw_rect(Rect2(x, 46, 52, 68), INK if (i + 1) * 320 <= beat * 8 else WASH)
		"metronome":
			for i in 11:
				var active := beat >= 0 and i <= (10 if beat > 0 and beat % 10 == 0 else beat % 10)
				_round_disc(Vector2(18.0 + i * 56.4, 80), 27.0 if i in [0, 10] else 18.0,
					INK if active else WASH)


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
		var centre := Vector2(-0.05, 0.05) if magnified else Vector2(-0.12, 0.12)
		draw_circle(centre * side, radius, INK, true, -1, true)
		draw_arc(centre * side, radius + side * 0.025, 4.25, 4.94, 24, INK, 2.5, true)
		for i in 8:
			draw_line(Vector2(-side * 0.43, side * (i / 9.0 - 0.4)),
				Vector2(side * 0.43, side * (i / 9.0 - 0.38)), WASH, 1.8, true)
	elif magnified:
		var crop := Vector2.ONE * Plate.SIZE * 0.24
		draw_texture_rect_region(texture, rect, Rect2(detail * Plate.SIZE - crop / 2, crop))
	else:
		draw_texture_rect(texture, rect, false)
