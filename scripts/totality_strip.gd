extends Control
class_name TotalityStrip
## The 0–302 s exposure strip under the totality header (M5 spec C).
## Data comes shaped from TotalityCues.strip_model; this node only draws it.
## No cloud, gap or contact marks: only time, exposures, and plate pips.

const PAD_X := 8.0
const TRACK_Y := 8.0
const TRACK_H := 8.0
const PIP := 10.0
const PIP_GAP := 6.0
const TRACK_COL := Color(0.20, 0.20, 0.25, 0.9)
const CLOSED_COL := Color(0.58, 0.53, 0.44, 0.95)
const OPEN_COL := Color(0.95, 0.68, 0.28, 1.0)
const PLAYHEAD_COL := Color(0.96, 0.93, 0.86, 0.95)
const PIP_OUTLINE_COL := Color(0.55, 0.55, 0.62, 0.9)
const READY_COL := Color(0.72, 0.86, 0.72)
const HOLDER_CHANGE_S := preload("res://scripts/eclipse_sim.gd").PLATE_CHANGE_S

var model: Dictionary = {}
var holder_mark: StringName
var _change_left := 0.0


func _ready() -> void:
	custom_minimum_size = Vector2(0, 32)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_model(m: Dictionary) -> void:
	var closed := _closed_count(m)
	if not model.is_empty():
		# The last HUD tick is the shutter input's game time, even for a
		# zero-length exposure that has no segment on the track.
		if closed > _closed_count(model) and closed < int(m.plates_total):
			_change_left = HOLDER_CHANGE_S
		_change_left = maxf(_change_left - (float(m.t) - float(model.t)), 0.0)
	model = m
	if m.open_start >= 0.0:
		holder_mark = &"open"
	elif closed == int(m.plates_total):
		holder_mark = &"empty"
	elif _change_left > 0.0:
		holder_mark = &"changing"
	else:
		holder_mark = &"ready"
	queue_redraw()


func _closed_count(m: Dictionary) -> int:
	return int(m.plates_used) - int(m.open_start >= 0.0)


func _x_of(t: float) -> float:
	var total: float = maxf(float(model.get("total", 1.0)), 0.001)
	var w: float = size.x - PAD_X * 2.0
	return PAD_X + clampf(t / total, 0.0, 1.0) * w


func _draw() -> void:
	if model.is_empty():
		return
	var width: float = size.x - PAD_X * 2.0
	if width <= 0.0:
		return
	draw_rect(Rect2(PAD_X, TRACK_Y, width, TRACK_H), TRACK_COL)
	for seg in model.get("segments", []):
		var x0 := _x_of(seg[0])
		var x1 := _x_of(seg[1])
		if x1 > x0:
			draw_rect(Rect2(x0, TRACK_Y, x1 - x0, TRACK_H), CLOSED_COL)
	var px := _x_of(float(model.get("t", 0.0)))
	draw_line(Vector2(px, TRACK_Y - 1.0), Vector2(px, TRACK_Y + TRACK_H + 2.0), PLAYHEAD_COL, 2.0)
	if holder_mark == &"open":
		var start := _x_of(model.open_start)
		draw_line(Vector2(start, 5), Vector2(px, 5), OPEN_COL, 2.0)
		draw_polyline(PackedVector2Array([Vector2(px - 4, 6), Vector2(px, 2), Vector2(px + 4, 6)]), OPEN_COL, 2.0, true)
	var pips := int(model.plates_total)
	var closed := _closed_count(model)
	var py := TRACK_Y + TRACK_H + 3.0
	for i in pips:
		var x := PAD_X + i * (PIP + PIP_GAP)
		var rect := Rect2(x, py, PIP, PIP)
		if i < closed:
			draw_rect(rect, CLOSED_COL)
		elif i == closed and holder_mark == &"changing":
			draw_line(Vector2(x, py + 5), Vector2(x + 4, py - 1), PLAYHEAD_COL, 2.0, true)
			draw_line(Vector2(x + 5, py + 5), Vector2(x + 9, py - 1), PLAYHEAD_COL, 2.0, true)
		elif i == closed and holder_mark == &"ready":
			var center := Vector2(x + PIP / 2.0, py + 7)
			draw_polyline(PackedVector2Array([center + Vector2(0, -5), center + Vector2(5, 0),
				center + Vector2(0, 5), center + Vector2(-5, 0), center + Vector2(0, -5)]), READY_COL, 2.0, true)
		else:
			draw_rect(rect, PIP_OUTLINE_COL, false, 1.0)
	if holder_mark == &"empty":
		var x := PAD_X + pips * (PIP + PIP_GAP)
		draw_line(Vector2(x, py), Vector2(x + PIP, py + PIP), PLAYHEAD_COL, 2.0, true)
		draw_line(Vector2(x, py + PIP), Vector2(x + PIP, py), PLAYHEAD_COL, 2.0, true)
