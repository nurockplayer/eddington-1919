extends Control
## The printed historical plate, with separate strokes for the three arrival beats.

signal beat_started(beat: int)
signal arrived

const Settings := preload("res://scripts/settings.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const STOCK := Color(0.91, 0.86, 0.75)
const GUIDE := Color(0.47, 0.39, 0.29)
const ASHBY := Color(0.47, 0.23, 0.17)
const PLAYER := Color(0.21, 0.33, 0.36)
const REFERENCES := [0.0, 0.87, 1.75]
const BEAT_SECONDS := 1.12
const STROKE_SECONDS := 0.46

var rows: Array
var labels: Dictionary
var pick: int
var beat := 0
var stroke := 1.0
var _elapsed := 0.0


func _ready() -> void:
	set_process(rows.size() == 2)
	stroke = float(Settings.reduced_motion) if is_processing() else 1.0
	if not is_processing():
		beat = rows.size()


func refresh_fonts() -> void:
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	var next := mini(int(_elapsed / BEAT_SECONDS), rows.size())
	stroke = 1.0 if Settings.reduced_motion else smoothstep(0.0, STROKE_SECONDS, _elapsed - next * BEAT_SECONDS)
	while beat < next:
		beat += 1
		beat_started.emit(beat)
	queue_redraw()
	if beat == rows.size() and stroke == 1.0:
		set_process(false)
		arrived.emit()


func _x(value: float) -> float:
	return 34.0 + value / 2.32 * (size.x - 68.0)


func _print(text: String, x: float, y: float, color: Color, centered := false) -> void:
	var font := get_theme_default_font()
	# Twenty canvas units are sixteen pixels at the 1280×720 presentation size.
	var px := Settings.fs(20)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	var left := clampf(x - width * 0.5 if centered else x, 28.0, size.x - width - 28.0)
	var ascent := font.get_ascent(px)
	draw_rect(Rect2(left - 4, y - ascent, width + 8, font.get_height(px)), STOCK)
	draw_string(font, Vector2(left, y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, px, color)


func _prediction(value: float, text: String, y: float, color: Color, diamond: bool) -> void:
	if value >= 0.0:
		var point := Vector2(_x(value), y - 7)
		if diamond:
			draw_polyline(PackedVector2Array([point + Vector2(0, -6), point + Vector2(6, 0),
				point + Vector2(0, 6), point + Vector2(-6, 0), point + Vector2(0, -6)]), color, 2.0, true)
		else:
			draw_circle(point, 5.0, color, true, -1, true)
	_print(text, _x(value) + 15 if value >= 0.0 else 34.0, y, color)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), STOCK)
	draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Report.PAPER_EDGE, false, 1.5)
	_print("%s · %s" % [labels.L24, labels.L25], size.x / 2, 33.0, Report.INK, true)
	var line_height := get_theme_default_font().get_height(Settings.fs(20))
	var top := 67.0 + 2.0 * line_height
	var bottom := size.y - line_height - 26.0
	var axis := stroke if beat == 0 else 1.0
	draw_line(Vector2(_x(0), bottom), Vector2(lerpf(_x(0), _x(2.32), axis), bottom), Report.INK, 2.0, true)
	for i in REFERENCES.size():
		var value: float = REFERENCES[i]
		if axis < value / 2.32:
			continue
		var x := _x(value)
		draw_dashed_line(Vector2(x, bottom), Vector2(x, lerpf(bottom, top, axis)), GUIDE, 1.5, 5.0, true, true)
		draw_line(Vector2(x, bottom - 5), Vector2(x, bottom + 6), Report.INK, 2.0, true)
		_print(labels["L%d" % (26 + i)], x, size.y - 16.0, Report.INK, true)
	if axis == 1.0:
		_prediction(0.87, labels.L04, 43.0 + line_height, ASHBY, false)
		var value: float = REFERENCES[pick] if pick >= 0 and pick < REFERENCES.size() else -1.0
		_prediction(value, labels.L05, 47.0 + 2.0 * line_height, PLAYER, true)
	for i in beat:
		var row: Dictionary = rows[i]
		var progress := stroke if i == beat - 1 else 1.0
		var y := lerpf(top, bottom, (i + 0.6) / rows.size())
		var point := Vector2(_x(row.value), y)
		if row.has("other_value"):
			var other := Vector2(_x(row.other_value), y)
			draw_arc(point, 5, 0, TAU, 20, ASHBY, 2.0, true)
			draw_rect(Rect2(other - Vector2(5, 5), Vector2(10, 10)), ASHBY, false, 2.0)
			for mark in [[point, row.value], [other, row.other_value]]:
				_print("%.2f″" % mark[1], mark[0].x + 14, y + 7, ASHBY)
		else:
			var low := lerpf(point.x, _x(row.value - row.sigma), progress)
			var high := lerpf(point.x, _x(row.value + row.sigma), progress)
			draw_line(Vector2(low, y), Vector2(high, y), Report.INK, 2.5, true)
			for x in [low, high]:
				draw_line(Vector2(x, y - 7 * progress), Vector2(x, y + 7 * progress), Report.INK, 2.0, true)
			draw_circle(point, 2.0 + 5.0 * progress, Report.INK, true, -1, true)
		_print(row.label, 34.0, y - 12.0, Report.INK)
