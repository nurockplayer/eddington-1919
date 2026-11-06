extends Control

class_name CambridgeBoxSketch
## Conversion arc move E (FICTION): the closed box, played by hand. The player drops
## a pencil in the box and then lets a light in, in an illustration that is never to
## scale. The box gives no number. The look follows plan_board.gd.

signal finished

const Settings := preload("res://scripts/settings.gd")
const INK := Color(0.16, 0.13, 0.10)
const PAPER := Color(0.86, 0.80, 0.68)
const PAPER_EDGE := Color(0.50, 0.37, 0.23)
const BOX_FILL := Color(0.90, 0.85, 0.74)

## Box coordinates, in pixels at the sketch's own scale. The pencil in the box, the
## box pulled up by the rope and the light in the box all fall at ACCEL: that sameness
## is the whole sketch. The light keeps its own name, and the landing point in box
## coordinates only matches between the two views because the two accelerations are equal.
const ACCEL := 600.0
const LIGHT_ACCEL := ACCEL
const BOX_W := 360.0
const BOX_H := 400.0
const FLOOR_Y := 240.0
const PENCIL_LEN := 52.0
## The tip, not the origin, stops on the floor: the origin starts high enough for it.
const PENCIL_Y := BOX_H - FLOOR_Y - PENCIL_LEN
const HOLE_Y := 140.0
const LIGHT_SPAN := 0.6
const TICK_STEP := 0.1

const DROP_PROMPTS := [
	"箱子放在地上。鬆手，看鉛筆怎麼掉。",
	"箱子在空無一物的太空裡，被繩子越拉越快地往上拉。再鬆手一次。",
	"外面蓋住了。再鬆手一次。",
]
const DROP_NOTE := "示意圖，不按比例。"
const LIGHT_NOTE := "示意圖：落差放大了許多。真的箱子裡，比一個原子還小。"

var input_blocked := false
var stage := 0
var mode := ""
var view := ""
var release_btn: Button
var next_btn: Button
var frame_btns: Array[Button] = []
## One Array of pencil offsets per fall, in box coordinates, as the animation drew them.
var fall_ticks: Array = []
## Equal-time light marks in box coordinates, per view.
var marks: Dictionary = {"outside": [], "inside": []}
## Where the light lands on the far wall, in box coordinates, per view.
var landing: Dictionary = {}
var _falling := false
var _fall_t := 0.0
var _next_tick := 0.0
var _light_running := false
var _light_t := 0.0
var _next_mark := 0.0
var _played: Dictionary = {"outside": false, "inside": false}
var _canvas: Control
var _prompt: Label
var _note: Label
var _inset_label: Label
var _arrow_label: Label
var _buttons: HBoxContainer
var _layout_size := Vector2.ZERO


class Sketch extends Control:
	var sketch

	func _draw() -> void:
		if sketch:
			sketch._draw_sketch(self)


static func drop_y(t: float) -> float:
	return minf(0.5 * ACCEL * t * t, FLOOR_Y)


static func box_rise(t: float) -> float:
	return 0.5 * ACCEL * t * t


static func light_drop(t: float) -> float:
	return 0.5 * LIGHT_ACCEL * t * t


static func fall_time() -> float:
	return sqrt(2.0 * FLOOR_Y / ACCEL)


func _ready() -> void:
	hide()


func open(p_mode: String) -> void:
	mode = p_mode
	stage = 0
	view = "outside" if mode == "light" else ""
	_falling = false
	_light_running = false
	_fall_t = 0.0
	_light_t = 0.0
	fall_ticks.clear()
	marks = {"outside": [], "inside": []}
	landing.clear()
	_played = {"outside": false, "inside": false}
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build()
	visible = true
	_layout_size = Vector2.ZERO
	_layout()
	_refresh_stage()
	_canvas.queue_redraw()


func _label(text_: String, size_: int, align := HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var label := Label.new()
	label.text = text_
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Settings.track_font(label, size_)
	label.add_theme_color_override("font_color", INK)
	return label


func _button(text_: String) -> Button:
	var button := Button.new()
	button.text = text_
	button.custom_minimum_size = Vector2(140, 44)
	button.focus_mode = Control.FOCUS_ALL
	Settings.track_font(button, 22)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.91, 0.85, 0.73) if state != "disabled" else Color(0.79, 0.74, 0.65)
		style.border_color = PAPER_EDGE
		style.set_border_width_all(2 if state in ["hover", "focus", "pressed"] else 1)
		style.set_content_margin_all(8)
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, INK)
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.39, 0.33))
	return button


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.025, 0.03, 0.90)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var sheet := Panel.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.anchor_left = 0.055
	sheet.anchor_top = 0.05
	sheet.anchor_right = 0.945
	sheet.anchor_bottom = 0.95
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = PAPER
	sheet_style.set_border_width_all(2)
	sheet_style.border_color = PAPER_EDGE
	sheet_style.shadow_color = Color(0, 0, 0, 0.24)
	sheet_style.shadow_size = 12
	sheet.add_theme_stylebox_override("panel", sheet_style)
	add_child(sheet)
	var sketch := Sketch.new()
	sketch.sketch = self
	sketch.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sketch.anchor_left = 0.055
	sketch.anchor_top = 0.05
	sketch.anchor_right = 0.945
	sketch.anchor_bottom = 0.95
	sketch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(sketch)
	_canvas = sketch
	_prompt = _label("", 20)
	_canvas.add_child(_prompt)
	_note = _label("", 17)
	_canvas.add_child(_note)
	_inset_label = _label("", 18)
	_inset_label.visible = false
	_canvas.add_child(_inset_label)
	_arrow_label = _label("越拉越快", 17, HORIZONTAL_ALIGNMENT_LEFT)
	_arrow_label.visible = false
	_canvas.add_child(_arrow_label)
	_buttons = HBoxContainer.new()
	_buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	_buttons.add_theme_constant_override("separation", 16)
	_canvas.add_child(_buttons)
	if mode == "light":
		for i in 2:
			var frame := _button("從箱外看" if i == 0 else "從箱裡看")
			frame.toggle_mode = true
			frame.pressed.connect(_frame.bind(i))
			_buttons.add_child(frame)
			frame_btns.append(frame)
	else:
		frame_btns.clear()
	release_btn = _button("鬆手")
	release_btn.pressed.connect(_release)
	_buttons.add_child(release_btn)
	next_btn = _button("")
	next_btn.disabled = true
	next_btn.pressed.connect(_next)
	_buttons.add_child(next_btn)


## The big interior of the box (drop) or the one box (light), in canvas pixels.
func _box_rect() -> Rect2:
	var size_ := _canvas.size
	var scale_ := size_.y * (0.60 if mode == "drop" else 0.46) / BOX_H
	var origin := Vector2(size_.x * 0.09, size_.y * 0.07) if mode == "drop" else Vector2(size_.x * 0.16, size_.y * 0.22)
	return Rect2(origin, Vector2(BOX_W, BOX_H) * scale_)


func _inset_rect() -> Rect2:
	var size_ := _canvas.size
	return Rect2(Vector2(size_.x * 0.64, size_.y * 0.10), Vector2(size_.x * 0.28, size_.y * 0.36))


## The light's position at time t, in box coordinates: across the box, and below its
## top. The outside view is the box risen past a straight ray; the inside view is the
## same ray curving. They agree because the two accelerations are one number.
func _box_point(t: float) -> Vector2:
	var x := BOX_W * clampf(t / LIGHT_SPAN, 0.0, 1.0)
	return Vector2(x, HOLE_Y + (box_rise(t) if view == "outside" else light_drop(t)))


func _box_to_screen(point: Vector2) -> Vector2:
	var base := _box_rect()
	var scale_ := base.size.y / BOX_H
	var top: float = base.position.y - (box_rise(_light_t) * scale_ if view == "outside" else 0.0)
	return Vector2(base.position.x + point.x * scale_, top + point.y * scale_)


func _layout() -> void:
	if not is_instance_valid(_canvas) or _canvas.size == Vector2.ZERO:
		return
	_layout_size = _canvas.size
	var size_ := _canvas.size
	var margin := size_.x * 0.06
	_prompt.position = Vector2(margin, size_.y * 0.735)
	_prompt.size = Vector2(size_.x - margin * 2.0, size_.y * 0.09)
	_note.position = Vector2(margin, size_.y * 0.83)
	_note.size = Vector2(size_.x - margin * 2.0, size_.y * 0.06)
	_buttons.position = Vector2(0.0, size_.y * 0.90)
	_buttons.size = Vector2(size_.x, size_.y * 0.09)
	var inset := _inset_rect()
	if stage == 0:
		_inset_label.position = inset.position + Vector2(0.0, inset.size.y * 0.80)
		_inset_label.size = Vector2(inset.size.x, inset.size.y * 0.2)
	elif stage == 2:
		_inset_label.position = inset.position + Vector2(inset.size.x * 0.06, inset.size.y * 0.40)
		_inset_label.size = Vector2(inset.size.x * 0.88, inset.size.y * 0.5)
	_arrow_label.position = Vector2(inset.end.x + size_.x * 0.01, inset.position.y + inset.size.y * 0.04)
	_arrow_label.size = Vector2(size_.x - _arrow_label.position.x, inset.size.y * 0.3)


func _refresh_stage() -> void:
	_falling = false
	_light_running = false
	_fall_t = 0.0
	_light_t = 0.0
	next_btn.disabled = true
	release_btn.disabled = false
	if mode == "drop":
		_prompt.text = DROP_PROMPTS[stage]
		_note.text = DROP_NOTE
		next_btn.text = "回到桌邊" if stage == 2 else "換一格"
		_inset_label.visible = stage != 1
		_inset_label.text = "地面" if stage == 0 else "Eddington 用手蓋住了這一格。"
		_arrow_label.visible = stage == 1
	else:
		_prompt.text = ""
		_note.text = LIGHT_NOTE
		next_btn.text = "收起來"
		_sync_frame_buttons()
	_layout()
	_canvas.queue_redraw()
	release_btn.grab_focus()


func _sync_frame_buttons() -> void:
	for i in frame_btns.size():
		frame_btns[i].set_pressed_no_signal(("outside" if i == 0 else "inside") == view)


func _release() -> void:
	if input_blocked:
		return
	if mode == "drop":
		if _falling:
			return
		_fall_start()
	else:
		if _light_running:
			return
		_light_running = true
		_light_t = 0.0
		_next_mark = TICK_STEP
		marks[view] = []
		release_btn.disabled = true
		_canvas.queue_redraw()


func _fall_start() -> void:
	_falling = true
	_fall_t = 0.0
	_next_tick = TICK_STEP
	fall_ticks.append([])
	release_btn.disabled = true
	next_btn.disabled = true
	_canvas.queue_redraw()


func _next() -> void:
	if input_blocked or next_btn.disabled:
		return
	if mode == "drop" and stage < 2:
		stage += 1
		_refresh_stage()
		return
	hide()
	finished.emit()


func _frame(index: int) -> void:
	if input_blocked:
		return
	view = "outside" if index == 0 else "inside"
	_light_running = false
	_light_t = 0.0
	release_btn.disabled = false
	_sync_frame_buttons()
	_canvas.queue_redraw()
	release_btn.grab_focus()


func _process(delta: float) -> void:
	if not visible or not is_instance_valid(_canvas):
		return
	if _canvas.size != _layout_size:
		_layout()
	if mode == "drop" and _falling:
		_fall_t += delta
		while _next_tick <= fall_time() and _fall_t >= _next_tick:
			fall_ticks[-1].append(drop_y(_next_tick))
			_next_tick += TICK_STEP
		if _fall_t >= fall_time():
			_fall_t = fall_time()
			_falling = false
			_fall_end()
		_canvas.queue_redraw()
	elif mode == "light" and _light_running:
		_light_t += delta
		while _next_mark <= LIGHT_SPAN and _light_t >= _next_mark:
			marks[view].append(_box_point(_next_mark))
			_next_mark += TICK_STEP
		if _light_t >= LIGHT_SPAN:
			_light_t = LIGHT_SPAN
			_light_running = false
			light_end()
		_canvas.queue_redraw()


func _fall_end() -> void:
	release_btn.disabled = true
	next_btn.text = "回到桌邊" if stage == 2 else "換一格"
	next_btn.disabled = false
	next_btn.grab_focus()
	_canvas.queue_redraw()


func light_end() -> void:
	_played[view] = true
	landing[view] = _box_point(LIGHT_SPAN)
	release_btn.disabled = false
	if _played.outside and _played.inside:
		next_btn.disabled = false
		next_btn.grab_focus()
	_canvas.queue_redraw()


func _draw_sketch(c: Control) -> void:
	if mode == "drop":
		_draw_drop(c)
	else:
		_draw_light(c)


func _draw_drop(c: Control) -> void:
	var base := _box_rect()
	var scale_ := base.size.y / BOX_H
	c.draw_rect(base, BOX_FILL, true)
	c.draw_rect(base, INK, false, 2.0)
	var floor_screen := base.position.y + BOX_H * scale_
	c.draw_line(Vector2(base.position.x, floor_screen), Vector2(base.end.x, floor_screen), INK, 3.0)
	var pencil_x := base.position.x + BOX_W * 0.5 * scale_
	var pencil_y := base.position.y + (PENCIL_Y + drop_y(_fall_t)) * scale_
	# Equal-time ticks: every fall marks the same times, so the later ones land on them.
	for i in fall_ticks.size():
		var alpha := 0.5 if i == fall_ticks.size() - 1 else 0.16
		for offset in fall_ticks[i]:
			var tick_y: float = base.position.y + (PENCIL_Y + float(offset)) * scale_
			c.draw_line(Vector2(pencil_x + 20.0, tick_y), Vector2(pencil_x + 38.0, tick_y), Color(INK, alpha), 2.0)
	c.draw_line(Vector2(pencil_x, pencil_y), Vector2(pencil_x, pencil_y + 44.0 * scale_), INK, 5.0 * scale_)
	c.draw_colored_polygon(PackedVector2Array([
		Vector2(pencil_x - 4.0 * scale_, pencil_y + 44.0 * scale_),
		Vector2(pencil_x + 4.0 * scale_, pencil_y + 44.0 * scale_),
		Vector2(pencil_x, pencil_y + PENCIL_LEN * scale_),
	]), INK)
	_draw_inset(c)


func _draw_inset(c: Control) -> void:
	var inset := _inset_rect()
	if stage == 0:
		var ground := inset.position.y + inset.size.y * 0.78
		c.draw_line(Vector2(inset.position.x, ground), Vector2(inset.end.x, ground), INK, 2.0)
		var x := inset.position.x
		while x < inset.end.x:
			c.draw_line(Vector2(x, ground), Vector2(x - 10.0, ground + 12.0), Color(INK, 0.5), 1.0)
			x += 14.0
		var box := Rect2(Vector2(inset.position.x + inset.size.x * 0.34, ground - inset.size.y * 0.40),
			Vector2(inset.size.x * 0.32, inset.size.y * 0.40))
		c.draw_rect(box, BOX_FILL, true)
		c.draw_rect(box, INK, false, 2.0)
	elif stage == 1:
		for star in [Vector2(0.14, 0.12), Vector2(0.82, 0.18), Vector2(0.55, 0.06), Vector2(0.24, 0.62), Vector2(0.88, 0.66)]:
			c.draw_circle(inset.position + inset.size * star, 2.5, Color(INK, 0.75))
		var travel := inset.size.y * 0.42 / box_rise(fall_time())
		var lift := box_rise(_fall_t) * travel
		var box := Rect2(Vector2(inset.position.x + inset.size.x * 0.36, inset.position.y + inset.size.y * 0.50 - lift),
			Vector2(inset.size.x * 0.30, inset.size.y * 0.32))
		c.draw_rect(box, BOX_FILL, true)
		c.draw_rect(box, INK, false, 2.0)
		var rope_x := box.position.x + box.size.x * 0.5
		c.draw_line(Vector2(rope_x, box.position.y), Vector2(rope_x, inset.position.y - inset.size.y * 0.30), INK, 2.0)
		var arrow_x := box.end.x + inset.size.x * 0.14
		var arrow_bottom := box.position.y + box.size.y * 0.5
		var arrow_top := arrow_bottom - inset.size.y * 0.34
		c.draw_line(Vector2(arrow_x, arrow_bottom), Vector2(arrow_x, arrow_top), INK, 2.0)
		c.draw_line(Vector2(arrow_x, arrow_top), Vector2(arrow_x - 6.0, arrow_top + 12.0), INK, 2.0)
		c.draw_line(Vector2(arrow_x, arrow_top), Vector2(arrow_x + 6.0, arrow_top + 12.0), INK, 2.0)
	else:
		c.draw_rect(inset, Color(0.93, 0.89, 0.80), true)
		c.draw_rect(inset, PAPER_EDGE, false, 2.0)


func _draw_light(c: Control) -> void:
	var base := _box_rect()
	var scale_ := base.size.y / BOX_H
	var top: float = base.position.y - (box_rise(_light_t) * scale_ if view == "outside" else 0.0)
	var box := Rect2(Vector2(base.position.x, top), base.size)
	c.draw_rect(box, BOX_FILL, true)
	c.draw_rect(box, INK, false, 2.0)
	# The hole: a small opening in the left wall, and the level it sits at.
	var hole_screen := Vector2(box.position.x, top + HOLE_Y * scale_)
	c.draw_circle(hole_screen, 3.5, PAPER)
	c.draw_arc(hole_screen, 3.5, 0.0, TAU, 12, INK, 1.0)
	c.draw_dashed_line(Vector2(box.position.x, hole_screen.y), Vector2(box.end.x, hole_screen.y), Color(INK, 0.45), 1.5, 8.0)
	if view == "outside":
		# A straight ray: the box rises past it, so the far wall climbs to meet it.
		var emission := Vector2(base.position.x, base.position.y + HOLE_Y * scale_)
		var reach := base.position.x + BOX_W * clampf(_light_t / LIGHT_SPAN, 0.0, 1.0) * scale_
		c.draw_line(emission, Vector2(reach, emission.y), INK, 2.0)
	else:
		# The same ray inside the box: it sags on the way across.
		var points := PackedVector2Array()
		for i in 25:
			var t := LIGHT_SPAN * float(i) / 24.0
			if t > _light_t:
				break
			points.append(_box_to_screen(_box_point(t)))
		if points.size() >= 2:
			c.draw_polyline(points, INK, 2.0)
	for mark in marks[view]:
		# An outside-frame mark fixed itself in space; the box rose past it since.
		var point: Vector2 = _box_to_screen(mark) if view == "inside" else Vector2(base.position.x + mark.x * scale_, base.position.y + HOLE_Y * scale_)
		c.draw_circle(point, 3.0, Color(0.20, 0.17, 0.13, 0.8))
	if landing.has(view):
		var hit := _box_to_screen(landing[view])
		c.draw_line(hit - Vector2(6, 0), hit + Vector2(6, 0), INK, 2.0)
		c.draw_line(hit - Vector2(0, 6), hit + Vector2(0, 6), INK, 2.0)
