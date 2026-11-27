extends "res://scripts/cambridge/madeira_ink.gd"
## Schematic route and held prints for the forest transfer and observing site.

const World := preload("res://scripts/world_builder.gd")
const STOPS := [Vector2(466, 80), Vector2(325, 133), Vector2(212, 111), Vector2(224, 55)]
const CLOUD := Color("9f9e93")

var progress := 0.0:
	set(value):
		progress = value
		queue_redraw()


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0, size / Vector2(600, 160))
	draw_rect(Rect2(1, 1, 598, 158), LIGHT)
	match subject:
		"map": _map()
		"handoff", "delivery": _forest()
		"cutaway": _cutaway()
		"night", "cloud": _horizon()
		"arrival": _shore()
	draw_rect(Rect2(1, 1, 598, 158), WASH, false, 1)


func _map() -> void:
	var island := PackedVector2Array([Vector2(215, 42), Vector2(274, 28), Vector2(371, 43),
		Vector2(422, 37), Vector2(473, 61), Vector2(466, 80), Vector2(497, 120),
		Vector2(438, 139), Vector2(354, 154), Vector2(264, 147), Vector2(212, 111), Vector2(207, 74)])
	_shape(island, WASH)
	for i in range(1, 4):
		_shape([Vector2(260 + i * 26, 107), Vector2(282 + i * 26, 72),
			Vector2(305 + i * 26, 107)], Color("aa9874"))
	for i in steps:
		var point: Vector2 = STOPS[i]
		if i > 0:
			_leg(STOPS[i - 1], point, 1.0)
		draw_circle(point, 5, INK, true, -1, true)
		draw_string(ThemeDB.fallback_font, point + Vector2(8, -8), str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 17, INK)
	if steps == 4:
		_stroke([Vector2(224, 13), STOPS[3], Vector2(135, 55)], INK, 1.6)
		draw_colored_polygon([Vector2(224, 13), Vector2(220, 22), Vector2(228, 22)], INK)
		draw_colored_polygon([Vector2(135, 55), Vector2(144, 51), Vector2(144, 59)], INK)


func _shore() -> void:
	for y in range(35, 135, 8):
		# The shore polygon painted over the ruling trims each line to the coast.
		_stroke([Vector2(12, y), Vector2(462 if y == 35 else 497, y)], WASH, 1)
	_shape([Vector2(294, 158), Vector2(339, 100), Vector2(290, 82), Vector2(413, 66),
		Vector2(497, 43), Vector2(598, 63), Vector2(598, 158)], WASH)
	for i in 4:
		var at := Vector2(380 + 49 * i, 89 - 9 * i)
		draw_rect(Rect2(at, Vector2(42, 27)), LIGHT)
		_shape([at + Vector2(-5, 1), at + Vector2(20, -15), at + Vector2(48, 1)], INK)


func _forest() -> void:
	draw_rect(Rect2(2, 108, 595, 48), WASH)
	for i in 15:
		var x := 220.0 + i * 24
		var height := 45.0 + (i * 19) % 38
		draw_rect(Rect2(x, 104 - height, 4, height), INK)
		draw_circle(Vector2(x, 105 - height), 23, WASH.darkened(0.2), true, -1, true)
	if subject == "handoff":
		for i in 8:
			var x := 10.0 + i * 23
			_stroke([Vector2(x, 151 - i * 1.9), Vector2(x + 13, 127 - i * 0.7)], INK, 4)
		_stroke([Vector2(2, 144), Vector2(187, 132)])
		_stroke([Vector2(2, 129), Vector2(187, 121)])
	_stroke([Vector2(189, 133), Vector2(268, 140), Vector2(370, 146), Vector2(497, 136)], LIGHT, 3)
	var at := Vector2(212, 139).lerp(Vector2(368, 147), clampf(progress * 1.4 - 0.4, 0, 1))
	if subject == "delivery":
		at = Vector2(387, 146)
	var lift := smoothstep(0, 0.45, progress)
	var stride := sin(progress * TAU * 3) * lift
	var crate := at - Vector2(0, lift * 23)
	_crate(crate)
	_porter(at + Vector2(-15, 0), crate + Vector2(3, -9), stride)
	_porter(at + Vector2(55, 0), crate + Vector2(37, -9), -stride)


func _porter(at: Vector2, grip: Vector2, stride: float) -> void:
	draw_circle(at + Vector2(0, -47), 6, INK, true, -1, true)
	var shoulder := at + Vector2(0, -36)
	_stroke([shoulder, at + Vector2(0, -19)], INK, 8)
	_stroke([at + Vector2(-8 - 8 * stride, 0), at + Vector2(0, -19),
		at + Vector2(9 + 8 * stride, -2)], INK, 4)
	_stroke([shoulder, shoulder.lerp(grip, 0.55) + Vector2(0, 8), grip], INK, 4)


func _crate(at: Vector2) -> void:
	draw_rect(Rect2(at - Vector2(0, 23), Vector2(40, 24)), LIGHT)
	draw_rect(Rect2(at - Vector2(0, 23), Vector2(40, 24)), INK, false, 2)
	_stroke([at + Vector2(5, -2), at + Vector2(34, -21)], INK)
	_stroke([at + Vector2(6, -23), at + Vector2(6, 1)], INK)
	_stroke([at + Vector2(34, -23), at + Vector2(34, 1)], INK)


func _cutaway() -> void:
	draw_rect(Rect2(117, 99, 366, 57), WASH)
	draw_rect(Rect2(183, 99, 23, 53), LIGHT)
	for x in [163, 283, 429]:
		draw_rect(Rect2(x, 67, 29, 32), WASH.darkened(0.25))
	_stroke([Vector2(153, 62), Vector2(177, 35)], INK, 6)
	draw_rect(Rect2(230, 54, 247, 15), INK)
	draw_rect(Rect2(230, 53, 9, 18), LIGHT)
	_stroke([Vector2(89, 21), Vector2(165, 48), Vector2(230, 60)], Color("87612d"), 2.5)
	draw_colored_polygon([Vector2(230, 60), Vector2(218, 53), Vector2(217, 63)], Color("87612d"))
	draw_circle(Vector2(197, 80), 8, INK)
	_stroke([Vector2(197, 80), Vector2(197, 133)], INK, 2)
	draw_rect(Rect2(190, 133, 14, 14), INK)


func _horizon() -> void:
	draw_rect(Rect2(2, 2, 595, 156), Color("30383b") if subject == "night" else Color("d2c9b2"))
	if subject == "night":
		for i in 31:
			draw_circle(Vector2(14 + (i * 83) % 570, 8 + (i * 37) % 84), 1 + i % 3 * 0.4, LIGHT, true, -1, true)
	var coverage := 1.0 if subject == "cloud" else progress
	if coverage > 0:
		var left := lerpf(584, 14, coverage)
		var end_width := minf(36.0, (586 - left) * 0.5)
		var ridge := PackedVector2Array()
		var base := PackedVector2Array()
		for i in 33:
			var x := lerpf(left, 586, i / 32.0)
			var top := 35 + 11 * sin(x * 0.034) + 6 * cos(x * 0.056)
			var bottom := 71 + 7 * sin(x * 0.028 + 2) + 5 * cos(x * 0.057)
			var middle := (top + bottom) * 0.5
			var taper := smoothstep(0.0, end_width, minf(x - left, 586 - x))
			ridge.append(Vector2(x, lerpf(middle, top, taper)))
			base.append(Vector2(x, lerpf(middle, bottom, taper)))
		var bank := ridge.duplicate()
		for i in range(31, 0, -1):
			bank.append(base[i])
		draw_colored_polygon(bank, CLOUD)
		bank.append(bank[0])
		_stroke(bank, CLOUD.darkened(0.25), 1)
		for i in range(1, 31, 2):
			if base[i].y - ridge[i].y < 10:
				continue
			var at := base[i] - Vector2(0, 5)
			_stroke([at - Vector2(5 * coverage, 0), at + Vector2(9 * coverage, -2)],
				CLOUD.darkened(0.18), 1)
	_shape([Vector2(2, 155), Vector2(2, 112), Vector2(83, 97), Vector2(177, 118),
		Vector2(299, 108), Vector2(432, 88), Vector2(597, 103), Vector2(597, 155)], Color("565549"))
	_stroke([Vector2(395, 145), Vector2(395, 105), Vector2(501, 105), Vector2(501, 144)], INK, 4)
	_stroke([Vector2(379, 106), Vector2(512, 106)], INK, 7)
	_stroke([Vector2(430, 133), Vector2(475, 133)], INK, 6)


static func station_print(parent: Control) -> void:
	var mount := TextureRect.new()
	mount.custom_minimum_size.y = 176
	mount.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mount.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(mount)
	var site := Node3D.new()
	var viewport := print_view(mount, site, Vector3(0, 1, -4.2), Vector3(9, 4.5, -3), 6.8)
	var builder := World.new(site)
	builder.look = false
	var station := builder._shelter_and_instrument()
	station.roof.hide()
	mount.texture = viewport.get_texture()
