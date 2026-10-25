extends Control
class_name TotalityStrip
## The 0–302 s exposure strip under the totality header (M5 spec C).
## Data comes shaped from TotalityCues.strip_model; this node only draws it.
## No cloud, gap or contact marks: only time, exposures, and plate pips.

const PAD_X := 8.0
const TRACK_Y := 4.0
const TRACK_H := 8.0
const PIP := 10.0
const PIP_GAP := 6.0
const TRACK_COL := Color(0.20, 0.20, 0.25, 0.9)
const CLOSED_COL := Color(0.58, 0.53, 0.44, 0.95)
const OPEN_COL := Color(0.95, 0.68, 0.28, 1.0)
const PLAYHEAD_COL := Color(0.96, 0.93, 0.86, 0.95)
const PIP_EMPTY_COL := Color(0.55, 0.55, 0.62, 0.9)

var model: Dictionary = {}


func _ready() -> void:
	custom_minimum_size = Vector2(0, 32)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_model(m: Dictionary) -> void:
	model = m
	queue_redraw()


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
	var open_seg: Array = model.get("open_segment", [])
	if open_seg.size() == 2:
		var ox0 := _x_of(open_seg[0])
		var ox1 := _x_of(open_seg[1])
		if ox1 > ox0:
			draw_rect(Rect2(ox0, TRACK_Y, ox1 - ox0, TRACK_H), OPEN_COL)
	var px := _x_of(float(model.get("t", 0.0)))
	draw_line(Vector2(px, TRACK_Y - 3.0), Vector2(px, TRACK_Y + TRACK_H + 3.0), PLAYHEAD_COL, 2.0)
	var pips := int(model.get("plates_total", 0))
	var used := int(model.get("plates_used", 0))
	var py := TRACK_Y + TRACK_H + 5.0
	for i in pips:
		var rect := Rect2(PAD_X + i * (PIP + PIP_GAP), py, PIP, PIP)
		if i < used:
			draw_rect(rect, CLOSED_COL)
		else:
			draw_rect(rect, PIP_EMPTY_COL, false, 1.0)
