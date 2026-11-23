extends Control
## Deflection chart: each measured plate as a point with its error bar, the
## weighted combination, and the 0 / 0.87″ / 1.75″ reference lines.

const X_MAX := 3.2
const Settings := preload("res://scripts/settings.gd")

var rows: Array = []        # [{label, value, sigma, weak}]
var combined: Dictionary = {}
var revealed := false
var ledger: Array = []
var _label_px := Settings.fs(14)
var _drawn_label_px := -1
var _drawn_hollow := 0
var _drawn_filled := 0
var _drawn_markers: Array = []  # per row, in draw order: "filled" or "hollow"
var _drawn_bars: Array = []     # per row: "bar" or "none"
var _drawn_texts: Array = []    # every string drawn this frame
var _drawn_ledger: Array = []
var _drawn_ledger_bounds: Array = []
var _drawn_result_bounds := Rect2()
var _drawn_result_backing := false
var _drawn_axis_bounds: Array = []
var _drawn_hint_bounds: Array = []


func set_data(p_rows: Array, p_combined: Dictionary, p_revealed: bool) -> void:
	rows = p_rows
	combined = p_combined
	revealed = p_revealed
	queue_redraw()


func set_ledger(p_ledger: Array) -> void:
	ledger = p_ledger
	queue_redraw()


## Redraw with the current text size (ui calls this after cycling the scale).
func refresh_fonts() -> void:
	_label_px = Settings.fs(14)
	queue_redraw()


## What the last _draw() actually painted; the chart tests read this instead of
## the intended values, so a broken draw path cannot pass.
func drawn() -> Dictionary:
	return {"label_px": _drawn_label_px, "hollow": _drawn_hollow, "filled": _drawn_filled,
		"markers": _drawn_markers.duplicate(), "bars": _drawn_bars.duplicate(),
		"ledger": _drawn_ledger.duplicate(true), "ledger_bounds": _drawn_ledger_bounds.duplicate(),
		"result_bounds": _drawn_result_bounds, "result_backing": _drawn_result_backing,
		"axis_bounds": _drawn_axis_bounds.duplicate(), "hint_bounds": _drawn_hint_bounds.duplicate()}


## Every string the last _draw() painted. draw_string output is not a node
## property, so the leak watcher reads this to see the chart's text.
func drawn_texts() -> Array:
	return _drawn_texts.duplicate()


## Weak plates are marked by shape, not only colour: hollow ring vs filled dot.
func marker_filled(row: Dictionary) -> bool:
	return not row.get("weak", false)


func _x(v: float, w: float) -> float:
	return clampf(60.0 + clampf(v, -0.4, X_MAX) / X_MAX * (w - 90.0), 8.0, w - 8.0)


static func two_sigma_span(value: float, sigma: float) -> Vector2:
	return Vector2(value - 2.0 * sigma, value + 2.0 * sigma)


func _paint_ledger(font: Font, refs: Array, top: float) -> void:
	var entries := ledger.duplicate(true)
	if entries.size() == 2 and entries[0].pick == entries[1].pick:
		entries = [{"pick": entries[0].pick, "kind": "current", "tag":
			L.t("押的（1917 年至今沒改）：說不準") if entries[0].pick == 3 else L.t("押的（1917 年至今沒改）")}]
	var px := Settings.fs(13)
	var ascent := font.get_ascent(px)
	var height := ascent + font.get_descent(px)
	var items: Array = []
	for entry in entries:
		var pick: int = entry.pick
		if pick < 0 or pick > 3:
			continue
		var width := font.get_string_size(entry.tag, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var x := size.x - width - 4.0 if pick == 3 else _x(refs[pick][0], size.x) + 9.0
		var rect := Rect2(clampf(x, 4.0, size.x - width - 4.0), 0.0, width, height)
		if not items.is_empty():
			var previous: Rect2 = items[-1].rect
			if previous.grow(4.0).intersects(rect):
				# Two full-size lines do not fit in 30 px. Stagger vertically, then
				# separate horizontally so even the largest locale font stays clear.
				rect.position.y = maxf(0.0, top - height)
				rect.position.x = minf(maxf(rect.position.x, previous.end.x + 8.0), size.x - width - 4.0)
				previous.position.x = minf(previous.position.x, rect.position.x - previous.size.x - 8.0)
				items[-1].rect = previous
		items.append({"entry": entry, "rect": rect})
	for item in items:
		var entry: Dictionary = item.entry
		var pick: int = entry.pick
		var rect: Rect2 = item.rect
		var col := Color(0.85, 0.82, 0.75) if pick == 3 else Color(refs[pick][2])
		var shape := "text"
		if pick < 3:
			var x := _x(refs[pick][0], size.x)
			var y := rect.position.y + height * 0.5
			var triangle := PackedVector2Array([Vector2(x - 4, y - 3), Vector2(x + 4, y - 3), Vector2(x, y + 4)])
			shape = "hollow" if entry.kind == "original" else "filled"
			if shape == "filled":
				draw_colored_polygon(triangle, col)
			else:
				triangle.append(triangle[0])
				draw_polyline(triangle, col, 1.0, true)
		draw_string(font, rect.position + Vector2(0, ascent), entry.tag, HORIZONTAL_ALIGNMENT_LEFT, -1, px, col)
		_drawn_texts.append(entry.tag)
		_drawn_ledger.append({"pick": pick, "kind": entry.kind, "shape": shape})
		_drawn_ledger_bounds.append(rect)


func _draw() -> void:
	_drawn_label_px = -1
	_drawn_hollow = 0
	_drawn_filled = 0
	_drawn_markers.clear()
	_drawn_bars.clear()
	_drawn_texts.clear()
	_drawn_ledger.clear()
	_drawn_ledger_bounds.clear()
	_drawn_result_bounds = Rect2()
	_drawn_result_backing = false
	_drawn_axis_bounds.clear()
	_drawn_hint_bounds.clear()
	var w := size.x
	var h := size.y
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.08, 0.07, 0.95))
	var top := 30.0
	var axis_px := Settings.fs(15)
	var axis_height := font.get_height(axis_px)
	var bottom := h - 22.0 * Settings.text_scale - axis_height - font.get_descent(axis_px) - 8.0
	var refs := [[0.0, L.t("無偏折 0″"), Color(0.6, 0.6, 0.6)], [0.87, L.t("牛頓式 0.87″"), Color(0.55, 0.75, 0.95)], [1.75, L.t("愛因斯坦 1.75″"), Color(0.98, 0.72, 0.4)]]
	for i in refs.size():
		var ref: Array = refs[i]
		var x := _x(ref[0], w)
		draw_dashed_line(Vector2(x, top), Vector2(x, bottom), ref[2], 2.0, 6.0)
		_drawn_texts.append(ref[1])
		var text_size := font.get_string_size(ref[1], HORIZONTAL_ALIGNMENT_LEFT, -1, axis_px)
		var origin := Vector2(clampf(x - 40, 4, w - text_size.x - 4),
			bottom + 22.0 * Settings.text_scale + (axis_height + 3.0) * (i % 2))
		_drawn_axis_bounds.append(Rect2(origin - Vector2(0, font.get_ascent(axis_px)), text_size))
		draw_string(font, origin, ref[1], HORIZONTAL_ALIGNMENT_LEFT, -1, Settings.fs(15), ref[2])
	for t in range(0, int(X_MAX) + 1):
		var x := _x(t, w)
		draw_line(Vector2(x, bottom), Vector2(x, bottom + 5), Color(0.5, 0.5, 0.5), 1.0)
	if not revealed:
		var unmeasured := L.t("先選片，再量測。數值會在量測後顯示。")
		_drawn_texts.append(unmeasured)
		_paint_hint(font, unmeasured, Color(0.7, 0.66, 0.58))
		return
	_paint_ledger(font, refs, top)
	if rows.is_empty():
		var empty_hint := L.t("沒有可量測的底片。")
		_drawn_texts.append(empty_hint)
		_paint_hint(font, empty_hint, Color(0.9, 0.55, 0.5))
		return
	var n := rows.size() + 1
	var step := minf(34.0, (bottom - top - 20.0) / n)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y := top + 16.0 + i * step
		var col := Color(0.85, 0.82, 0.75) if not r.get("weak", false) else Color(0.85, 0.5, 0.45)
		# A row with no trustworthy error is a marker only; no bar is invented for it.
		if r.get("no_bar", false):
			_drawn_bars.append("none")
		else:
			_drawn_bars.append("bar")
			var span := two_sigma_span(r.value, r.sigma)
			var thin := Color(col, 0.45)
			var x2_lo := _x(span.x, w)
			var x2_hi := _x(span.y, w)
			draw_line(Vector2(x2_lo, y), Vector2(x2_hi, y), thin, 1.0)
			draw_line(Vector2(x2_lo, y - 3), Vector2(x2_lo, y + 3), thin, 1.0)
			draw_line(Vector2(x2_hi, y - 3), Vector2(x2_hi, y + 3), thin, 1.0)
			var x0 := _x(r.value - r.sigma, w)
			var x1 := _x(r.value + r.sigma, w)
			draw_line(Vector2(x0, y), Vector2(x1, y), col, 2.0)
			draw_line(Vector2(x0, y - 5), Vector2(x0, y + 5), col, 2.0)
			draw_line(Vector2(x1, y - 5), Vector2(x1, y + 5), col, 2.0)
		var p := Vector2(_x(r.value, w), y)
		if marker_filled(r):
			draw_circle(p, 5.0, col)
			_drawn_filled += 1
			_drawn_markers.append("filled")
		else:
			draw_arc(p, 5.0, 0.0, TAU, 20, col, 2.0)
			_drawn_hollow += 1
			_drawn_markers.append("hollow")
		_drawn_label_px = _label_px
		_drawn_texts.append(r.label)
		draw_string(font, Vector2(4, y + 5.0 * Settings.text_scale), r.label, HORIZONTAL_ALIGNMENT_LEFT, -1, _label_px, col)
	if combined.get("n", 0) > 0:
		var y := top + 16.0 + rows.size() * step + 10.0
		var c := Color(1.0, 0.92, 0.6)
		var span := two_sigma_span(combined.value, combined.sigma)
		var thin := Color(c, 0.55)
		var x2_lo := _x(span.x, w)
		var x2_hi := _x(span.y, w)
		draw_line(Vector2(x2_lo, y), Vector2(x2_hi, y), thin, 1.5)
		draw_line(Vector2(x2_lo, y - 3), Vector2(x2_lo, y + 3), thin, 1.5)
		draw_line(Vector2(x2_hi, y - 3), Vector2(x2_hi, y + 3), thin, 1.5)
		var x0 := _x(combined.value - combined.sigma, w)
		var x1 := _x(combined.value + combined.sigma, w)
		draw_line(Vector2(x0, y), Vector2(x1, y), c, 4.0)
		var cx := _x(combined.value, w)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 8), Vector2(cx + 8, y), Vector2(cx, y + 8), Vector2(cx - 8, y)]), c)
		var combined_label := L.t("合併")
		_drawn_texts.append(combined_label)
		draw_string(font, Vector2(4, y + 5.0 * Settings.text_scale), combined_label, HORIZONTAL_ALIGNMENT_LEFT, -1, Settings.fs(15), c)
		var combined_value := "%.2f″ ± %.2f″" % [combined.value, combined.sigma]
		_drawn_texts.append(combined_value)
		var px := Settings.fs(16)
		var width := font.get_string_size(combined_value, HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
		var baseline := Vector2(minf(cx + 14, w - width - 8), y - 10.0 * Settings.text_scale)
		_drawn_result_bounds = Rect2(baseline - Vector2(0, font.get_ascent(px)),
			Vector2(width, font.get_height(px)))
		# The reference lines stay in place, but cannot strike through the reading.
		draw_rect(_drawn_result_bounds.grow(2), Color(0.09, 0.08, 0.07))
		_drawn_result_backing = true
		draw_string(font, baseline, combined_value, HORIZONTAL_ALIGNMENT_LEFT, -1, px, c)


func _paint_hint(font: Font, text: String, color: Color) -> void:
	var px := Settings.fs(18)
	var width := size.x - 90.0
	var text_size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, px)
	var origin := Vector2(70, size.y * 0.45)
	_drawn_hint_bounds.append(Rect2(origin - Vector2(0, font.get_ascent(px)), text_size))
	draw_multiline_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, width, px, -1, color)
