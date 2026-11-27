extends Control
## A fixed glass register with a switchable emulsion and independent pencil marks.

const Overlay := preload("res://scripts/cambridge/overlay_viewer.gd")
const Plate := preload("res://scripts/plate_render.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const RINGS := [Vector2(0.24, 0.29), Vector2(0.69, 0.22), Vector2(0.38, 0.63), Vector2(0.77, 0.71)]
const TOP_TO_BOTTOM := [1, 0, 2, 3]

var centres := PackedVector2Array()
var clear_centres: Array[int] = []
var exposure_b := false
var selected := -1
var marks: Array[int] = []
var targets: Dictionary = {}
var _exposures: Array[ImageTexture] = []


func prepare(shift: float, visible_centres: Array, paper: Control) -> void:
	clear_centres.assign(visible_centres)
	var sharp := PackedVector2Array()
	var smudges := PackedVector2Array()
	for i in RINGS.size():
		var point: Vector2 = RINGS[i] + Vector2(shift, 0)
		centres.append(point)
		if clear_centres.has(i):
			sharp.append(point)
		else:
			smudges.append(point)
	_exposures = [Plate.render_check(PackedVector2Array(RINGS), PackedVector2Array()), Plate.render_check(sharp, smudges)]
	for i in TOP_TO_BOTTOM:
		if not clear_centres.has(i):
			continue
		var target := Button.new()
		target.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		for state in ["normal", "hover", "pressed"]:
			target.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		var focus := StyleBoxFlat.new()
		focus.bg_color = Color.TRANSPARENT
		focus.border_color = Report.INK
		focus.set_border_width_all(2)
		focus.set_corner_radius_all(14)
		target.add_theme_stylebox_override("focus", focus)
		target.pressed.connect(func(): paper.action.emit("centre:%d" % i))
		add_child(target)
		targets[i] = target
		target.hide()
	resized.connect(_position_targets)


func show_targets(active: bool) -> void:
	for target in targets.values():
		target.visible = active
	queue_redraw()


func _plate_rect() -> Rect2:
	var width := minf(size.x - 40, size.y - 36)
	return Rect2((size - Vector2.ONE * width) * 0.5, Vector2.ONE * width)


func _position_targets() -> void:
	var rect := _plate_rect()
	for i in targets:
		var target: Button = targets[i]
		target.size = Vector2(28, 28)
		target.position = rect.position + centres[i] * rect.size - target.size * 0.5
	queue_redraw()


func _draw() -> void:
	if _exposures.is_empty():
		return
	var rect := _plate_rect()
	if rect.size.x < 40:
		return
	Overlay.draw_glass(self, rect)
	draw_texture_rect(_exposures[int(exposure_b)], rect, false)
	var ring_ink := Color(0.27, 0.26, 0.23, 0.9)
	var mark_ink := Color(0.45, 0.20, 0.12)
	for i in RINGS.size():
		var origin: Vector2 = rect.position + RINGS[i] * rect.size
		var radius := rect.size.x * 0.03
		draw_arc(origin, radius, 0, TAU, 48, ring_ink, 1.5, true)
		draw_string(ThemeDB.fallback_font, origin + Vector2(-radius - 16, 5), str(i + 1),
			HORIZONTAL_ALIGNMENT_LEFT, -1, 16, ring_ink)
		if i == selected:
			draw_arc(origin, radius + 3, 0, TAU, 48, ring_ink, 1.5, true)
		if i >= marks.size() or not exposure_b:
			continue
		if marks[i] == -1:
			draw_line(origin - Vector2(5, 0), origin + Vector2(5, 0), mark_ink, 2, true)
		elif marks[i] >= 0:
			var point := rect.position + centres[marks[i]] * rect.size
			var diamond := PackedVector2Array([Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP])
			for j in diamond.size():
				diamond[j] = point + diamond[j] * 7
			draw_polyline(diamond, mark_ink, 2, true)
