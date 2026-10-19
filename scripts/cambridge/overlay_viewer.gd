extends Control
## Full-screen, self-contained Cambridge plate comparison modal.

signal clue_found(id: String)
signal aligned_changed(on: bool)
signal closed
signal hint_requested

const MathModel = preload("res://scripts/cambridge/overlay_math.gd")
const PAPER := Color(0.79, 0.785, 0.75)
const PAPER_LIGHT := Color(0.88, 0.875, 0.84)
const INK := Color(0.10, 0.105, 0.10)
const GOLD := Color(0.83, 0.67, 0.40)
const MUTED := Color(0.71, 0.69, 0.63)
const SOURCE_TILT := 3.2

var aligned := false
var flipped := false
var angle_deg := 0.0
var offset := Vector2.ZERO
var buttons: Dictionary = {}

var _font: Font
var _dragging := false
var _pointer_pressed := false
var _pointer_moved := false
var _pointer_start := Vector2.ZERO
var _clues: Dictionary = {}
var _loupe_open := false
var _hint_elapsed := 0.0
var _hint_sent := false
var _alignment_progress_recorded := false
var _status_label: Label
var _root_panel: PanelContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_font = SystemFont.new()
	(_font as SystemFont).font_names = PackedStringArray(["PingFang TC", "Heiti TC", "Noto Sans CJK TC", "Noto Sans TC", "Microsoft JhengHei", "Source Han Sans TC", "sans-serif"])
	_build_ui()
	visible = false


func open() -> void:
	visible = true
	_update_alignment()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	queue_redraw()


func close() -> void:
	if not visible:
		return
	visible = false
	_dragging = false
	closed.emit()


func detail_position(id: String) -> Vector2:
	var local_point := _detail_local_position(id)
	return get_global_transform_with_canvas() * local_point


func canvas_rect() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(Vector2(size.x * 0.12, size.y * 0.17), Vector2(size.x * 0.76, size.y * 0.62))


func _build_ui() -> void:
	_root_panel = PanelContainer.new()
	_root_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0)
	panel_style.set_content_margin_all(0)
	_root_panel.add_theme_stylebox_override("panel", panel_style)
	_root_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root_panel)
	var title := _label("14 號星場　／　玻璃與描圖紙", 28, PAPER_LIGHT)
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.position = Vector2(-360, 22)
	title.size = Vector2(720, 42)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(title)
	var subtitle := _label("固定底片　　·　　可移動描圖　　·　　拖曳平移　 Q／E 旋轉", 16, MUTED)
	subtitle.set_anchors_preset(Control.PRESET_CENTER_TOP)
	subtitle.position = Vector2(-440, 66)
	subtitle.size = Vector2(880, 30)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(subtitle)
	_status_label = _label("找出描圖與底片之間的差異。", 20, PAPER_LIGHT)
	_status_label.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_status_label.position = Vector2(-500, -123)
	_status_label.size = Vector2(1000, 34)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_status_label)
	var row := HBoxContainer.new()
	row.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	row.position = Vector2(-470, -76)
	row.size = Vector2(940, 56)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	add_child(row)
	buttons = {
		"flip": _button("翻面"),
		"left": _button("⟲　−0.5°"),
		"right": _button("+0.5°　⟳"),
		"reset": _button("重設"),
		"close": _button("關閉"),
	}
	buttons.flip.pressed.connect(_toggle_flip)
	buttons.left.pressed.connect(_rotate.bind(-0.5))
	buttons.right.pressed.connect(_rotate.bind(0.5))
	buttons.reset.pressed.connect(_reset)
	buttons.close.pressed.connect(close)
	for key in ["flip", "left", "right", "reset", "close"]:
		row.add_child(buttons[key])


func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", _font)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.add_theme_font_override("font", _font)
	button.add_theme_font_size_override("font_size", 18)
	button.focus_mode = Control.FOCUS_NONE
	button.custom_minimum_size = Vector2(142, 48)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.13, 0.125, 0.11, 0.97)
	normal.set_border_width_all(1)
	normal.border_color = Color(0.52, 0.46, 0.34)
	normal.set_corner_radius_all(3)
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.24, 0.21, 0.16, 1.0)
	hover.set_border_width_all(1)
	hover.border_color = GOLD
	hover.set_corner_radius_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_color_override("font_color", PAPER_LIGHT)
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.94, 0.80))
	return button


func _process(delta: float) -> void:
	if not visible or _hint_sent:
		return
	_hint_elapsed += delta
	if _hint_elapsed >= 90.0:
		_hint_sent = true
		hint_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_Q:
			_rotate(-0.5)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_E:
			_rotate(0.5)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE:
			close()
			get_viewport().set_input_as_handled()


func _gui_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var mouse_position: Vector2 = event.position
			if canvas_rect().has_point(mouse_position):
				_pointer_pressed = true
				_pointer_moved = false
				_pointer_start = mouse_position
				_dragging = true
				get_viewport().set_input_as_handled()
		else:
			if _pointer_pressed and not _pointer_moved:
				_try_detail_click(event.position)
			_pointer_pressed = false
			_dragging = false
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		var mouse_position: Vector2 = event.position
		var movement: Vector2 = event.relative
		if not _pointer_moved and mouse_position.distance_to(_pointer_start) >= 4.0:
			_pointer_moved = true
			movement = mouse_position - _pointer_start
		if _pointer_moved:
			var scale := _plate_scale()
			if scale > 0.0:
				offset += movement / scale
				_update_alignment()
				queue_redraw()
		get_viewport().set_input_as_handled()


func _toggle_flip() -> void:
	flipped = not flipped
	_update_alignment()
	queue_redraw()


func _rotate(amount: float) -> void:
	angle_deg += amount
	_update_alignment()
	queue_redraw()


func _reset() -> void:
	flipped = false
	angle_deg = 0.0
	offset = Vector2.ZERO
	_loupe_open = false
	_update_alignment()
	queue_redraw()


func _record_progress_stage() -> void:
	_hint_elapsed = 0.0
	_hint_sent = false


func _update_alignment() -> void:
	var next := MathModel.alignment(flipped, angle_deg, offset)
	if next:
		# Once the computed geometry is close enough, settle it onto the exact plate pose.
		angle_deg = SOURCE_TILT
		offset = Vector2.ZERO
		next = MathModel.alignment(flipped, angle_deg, offset)
		if next and not _alignment_progress_recorded:
			_alignment_progress_recorded = true
			_record_progress_stage()
	if next != aligned:
		aligned = next
		aligned_changed.emit(aligned)
	if is_instance_valid(_status_label):
		if aligned:
			_status_label.text = "17 個點重合了，還有 1 個沒有對上。"
		elif flipped:
			_status_label.text = "翻面後，整片星場仍沿同一方向錯開。"
		else:
			_status_label.text = "標籤倒了過來；先看看底片與描圖紙的方向。"


func _try_detail_click(mouse: Vector2) -> bool:
	for id in ["label_mirrored", "arrow_tilted"]:
		if mouse.distance_to(_detail_local_position(id)) < 28.0:
			_found_clue(id)
			return true
		if id == "label_mirrored" and mouse.distance_to(_plate_label_local_position()) < 28.0:
			_found_clue(id)
			return true
	if aligned and mouse.distance_to(_detail_local_position("residual")) < 30.0:
		_found_clue("residual")
		_loupe_open = true
		queue_redraw()
		return true
	return false


func _found_clue(id: String) -> void:
	if _clues.get(id, false):
		return
	_clues[id] = true
	_record_progress_stage()
	clue_found.emit(id)


func _detail_local_position(id: String) -> Vector2:
	var rect := canvas_rect()
	var scale := _plate_scale()
	var point := Vector2.ZERO
	if id == "label_mirrored":
		point = _copy_point(Vector2(-0.285, -0.315))
	elif id == "arrow_tilted":
		point = Vector2(-0.28, 0.30)
	elif id == "residual":
		point = MathModel.speck_point()
	return rect.get_center() + point * scale


func _plate_label_local_position() -> Vector2:
	return canvas_rect().get_center() + Vector2(-0.285, -0.315) * _plate_scale()


func _plate_scale() -> float:
	var rect := canvas_rect()
	return minf(rect.size.x, rect.size.y) * 1.16


func _copy_point(plate_point: Vector2) -> Vector2:
	var point := Vector2(-plate_point.x, plate_point.y).rotated(deg_to_rad(SOURCE_TILT))
	if flipped:
		point.x = -point.x
	return point.rotated(deg_to_rad(angle_deg)) + offset


func _point_to_pixel(point: Vector2) -> Vector2:
	return canvas_rect().get_center() + point * _plate_scale()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0.025, 0.028, 0.031, 0.995), true)
	var rect := canvas_rect()
	# A restrained pool of light behind the archival plate keeps the evidence readable.
	draw_rect(Rect2(rect.position - Vector2(16, 14), rect.size + Vector2(32, 28)), Color(0.12, 0.115, 0.10, 0.92), true)
	draw_rect(rect, Color(0.36, 0.355, 0.325), true)
	draw_rect(rect.grow(-8), PAPER, true)
	for i in 36:
		var x := rect.position.x + fposmod(float(i * 73 + 31), rect.size.x)
		var y := rect.position.y + fposmod(float(i * 47 + 19), rect.size.y)
		draw_circle(Vector2(x, y), 0.65, Color(0.42, 0.405, 0.37, 0.10))
	_draw_difference_arrows()
	_draw_plate_stars()
	_draw_speck()
	_draw_plate_marks()
	_draw_copy_layer()
	if aligned:
		_draw_alignment_glow()
	if _loupe_open:
		_draw_loupe()


func _draw_plate_stars() -> void:
	var points := MathModel.star_points()
	for i in points.size():
		var p := _point_to_pixel(points[i])
		var radius: float = [2.0, 2.5, 3.2, 1.8, 2.7][i % 5]
		draw_circle(p + Vector2(0.8, 1.0), radius + 1.0, Color(0.22, 0.21, 0.19, 0.10))
		draw_circle(p, radius, Color(0.12, 0.12, 0.115, 0.9))


func _draw_speck() -> void:
	var p := _point_to_pixel(MathModel.speck_point())
	draw_circle(p, 3.0, Color(0.76, 0.745, 0.69, 0.78))
	draw_circle(p, 1.5, Color(0.92, 0.90, 0.83, 0.85))


func _draw_plate_marks() -> void:
	var rect := canvas_rect()
	var font := _font
	var base := Vector2(-0.285, -0.315)
	draw_string(font, _point_to_pixel(base), "14", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.27, 0.26, 0.23, 0.75))
	var arrow_origin := Vector2(-0.28, 0.30)
	var arrow_end := arrow_origin + Vector2(0.11, 0.0).rotated(deg_to_rad(SOURCE_TILT))
	_draw_arrow(_point_to_pixel(arrow_origin), _point_to_pixel(arrow_end), Color(0.26, 0.25, 0.22, 0.8), 1.5)
	draw_string(font, _point_to_pixel(arrow_origin + Vector2(-0.015, 0.045)), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.28, 0.27, 0.24, 0.78))
	# Plate edge and registration ticks.
	draw_rect(rect.grow(-8), Color(0.36, 0.345, 0.31, 0.62), false, 1.0)
	for i in 9:
		var x := rect.position.x + 25 + i * (rect.size.x - 50) / 8.0
		draw_line(Vector2(x, rect.position.y + 9), Vector2(x, rect.position.y + 16), Color(0.34, 0.32, 0.285, 0.32), 1.0)


func _draw_copy_layer() -> void:
	var corners := [Vector2(-0.395, -0.34), Vector2(0.395, -0.34), Vector2(0.395, 0.34), Vector2(-0.395, 0.34)]
	var transformed: Array[Vector2] = []
	for corner in corners:
		transformed.append(_point_to_pixel(_copy_point(corner)))
	for i in 4:
		draw_line(transformed[i], transformed[(i + 1) % 4], Color(0.24, 0.22, 0.18, 0.35), 1.1)
	# The tracing paper grid is aligned to its own paper edge.
	for n in range(-3, 4):
		var u := float(n) * 0.095
		var a := _point_to_pixel(_copy_point(Vector2(u, -0.34)))
		var b := _point_to_pixel(_copy_point(Vector2(u, 0.34)))
		var c := _point_to_pixel(_copy_point(Vector2(-0.395, u * 0.86)))
		var d := _point_to_pixel(_copy_point(Vector2(0.395, u * 0.86)))
		draw_line(a, b, Color(0.20, 0.25, 0.23, 0.12), 0.8)
		draw_line(c, d, Color(0.20, 0.25, 0.23, 0.12), 0.8)
	var copy_stars := MathModel.transformed_copy(flipped, angle_deg, offset)
	for i in copy_stars.size():
		var p := _point_to_pixel(copy_stars[i])
		var radius := 2.2 if i < 17 else 3.5
		draw_circle(p, radius, Color(0.025, 0.08, 0.065, 0.88) if i < 17 else Color(0.05, 0.20, 0.15, 0.96))
	_draw_copy_label()
	var arrow_origin := _copy_point(Vector2(0.28, 0.30))
	var arrow_end := _copy_point(Vector2(0.39, 0.30))
	_draw_arrow(_point_to_pixel(arrow_origin), _point_to_pixel(arrow_end), Color(0.08, 0.20, 0.16, 0.78), 1.7)
	draw_string(_font, _point_to_pixel(_copy_point(Vector2(0.26, 0.345))), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.08, 0.20, 0.16, 0.82))


func _draw_copy_label() -> void:
	var at := _point_to_pixel(_copy_point(Vector2(-0.285, -0.315)))
	var mirrored := not flipped
	var rotation := deg_to_rad(angle_deg + SOURCE_TILT if not flipped else angle_deg - SOURCE_TILT)
	var x_scale := -1.0 if mirrored else 1.0
	draw_set_transform(at, rotation, Vector2(x_scale, 1.0))
	draw_string(_font, Vector2.ZERO, "14", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.055, 0.16, 0.12, 0.88))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_difference_arrows() -> void:
	if offset.length() > 0.18:
		return
	var targets := MathModel.star_points()
	var copies := MathModel.transformed_copy(flipped, angle_deg, offset)
	for i in copies.size():
		var nearest := Vector2.ZERO
		var distance := 999.0
		for target in targets:
			var d := copies[i].distance_to(target)
			if d < distance:
				distance = d
				nearest = target
		if distance < 0.095:
			var from := _point_to_pixel(copies[i])
			var to := _point_to_pixel(nearest)
			if from.distance_to(to) > 2.0:
				_draw_arrow(from, to, Color(0.49, 0.27, 0.12, 0.58), 1.0)


func _draw_alignment_glow() -> void:
	for point in MathModel.star_points():
		var p := _point_to_pixel(point)
		draw_circle(p, 8.0, Color(0.90, 0.71, 0.35, 0.10))
		draw_arc(p, 7.0, 0.0, TAU, 32, Color(0.91, 0.72, 0.39, 0.58), 1.0)


func _draw_loupe() -> void:
	var rect := canvas_rect()
	var loupe := Rect2(Vector2(rect.end.x - 194, rect.position.y + 28), Vector2(164, 164))
	draw_rect(loupe.grow(7), Color(0.10, 0.10, 0.095, 0.97), true)
	draw_rect(loupe, Color(0.83, 0.82, 0.77), true)
	draw_circle(loupe.get_center(), 4.0, Color(0.76, 0.745, 0.69, 0.82))
	draw_circle(loupe.get_center(), 2.1, Color(0.92, 0.90, 0.83, 0.91))
	draw_string(_font, loupe.position + Vector2(8, loupe.size.y + 25), "微弱斑點：恆星？乳劑瑕疵？", HORIZONTAL_ALIGNMENT_LEFT, 224, 14, Color(0.12, 0.12, 0.11, 0.9))
	draw_string(_font, loupe.position + Vector2(8, loupe.size.y + 46), "單憑這張底片，仍無法判定。", HORIZONTAL_ALIGNMENT_LEFT, 224, 13, Color(0.12, 0.12, 0.11, 0.78))


func _draw_arrow(from: Vector2, to: Vector2, color: Color, width: float) -> void:
	draw_line(from, to, color, width, true)
	var direction := (to - from).normalized()
	if direction.length_squared() < 0.001:
		return
	var side := Vector2(-direction.y, direction.x)
	draw_line(to, to - direction * 6.0 + side * 3.0, color, width, true)
	draw_line(to, to - direction * 6.0 - side * 3.0, color, width, true)
