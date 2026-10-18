extends Control
## Deflection chart: each measured plate as a point with its error bar, the
## weighted combination, and the 0 / 0.87″ / 1.75″ reference lines.

const X_MAX := 3.2

var rows: Array = []        # [{label, value, sigma, weak}]
var combined: Dictionary = {}
var revealed := false


func set_data(p_rows: Array, p_combined: Dictionary, p_revealed: bool) -> void:
	rows = p_rows
	combined = p_combined
	revealed = p_revealed
	queue_redraw()


func _x(v: float, w: float) -> float:
	return 60.0 + clampf(v, -0.4, X_MAX) / X_MAX * (w - 90.0)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.09, 0.08, 0.07, 0.95))
	var top := 30.0
	var bottom := h - 46.0
	for ref in [[0.0, "無偏折 0″", Color(0.6, 0.6, 0.6)], [0.87, "牛頓式 0.87″", Color(0.55, 0.75, 0.95)], [1.75, "愛因斯坦 1.75″", Color(0.98, 0.72, 0.4)]]:
		var x := _x(ref[0], w)
		draw_dashed_line(Vector2(x, top), Vector2(x, bottom), ref[2], 2.0, 6.0)
		draw_string(font, Vector2(x - 40, bottom + 22), ref[1], HORIZONTAL_ALIGNMENT_LEFT, -1, 15, ref[2])
	for t in range(0, int(X_MAX) + 1):
		var x := _x(t, w)
		draw_line(Vector2(x, bottom), Vector2(x, bottom + 5), Color(0.5, 0.5, 0.5), 1.0)
	if not revealed:
		draw_string(font, Vector2(70, h * 0.45), "先選片，再量測。數值會在量測後顯示。", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.7, 0.66, 0.58))
		return
	if rows.is_empty():
		draw_string(font, Vector2(70, h * 0.45), "沒有可量測的底片。", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.55, 0.5))
		return
	var n := rows.size() + 1
	var step := minf(34.0, (bottom - top - 20.0) / n)
	for i in rows.size():
		var r: Dictionary = rows[i]
		var y := top + 16.0 + i * step
		var col := Color(0.85, 0.82, 0.75) if not r.weak else Color(0.85, 0.5, 0.45)
		var x0 := _x(r.value - r.sigma, w)
		var x1 := _x(r.value + r.sigma, w)
		draw_line(Vector2(x0, y), Vector2(x1, y), col, 2.0)
		draw_line(Vector2(x0, y - 5), Vector2(x0, y + 5), col, 2.0)
		draw_line(Vector2(x1, y - 5), Vector2(x1, y + 5), col, 2.0)
		draw_circle(Vector2(_x(r.value, w), y), 5.0, col)
		draw_string(font, Vector2(4, y + 5), r.label, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, col)
	if combined.get("n", 0) > 0:
		var y := top + 16.0 + rows.size() * step + 10.0
		var c := Color(1.0, 0.92, 0.6)
		var x0 := _x(combined.value - combined.sigma, w)
		var x1 := _x(combined.value + combined.sigma, w)
		draw_line(Vector2(x0, y), Vector2(x1, y), c, 4.0)
		var cx := _x(combined.value, w)
		draw_colored_polygon(PackedVector2Array([Vector2(cx, y - 8), Vector2(cx + 8, y), Vector2(cx, y + 8), Vector2(cx - 8, y)]), c)
		draw_string(font, Vector2(4, y + 5), "合併", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, c)
		draw_string(font, Vector2(cx + 14, y - 10), "%.2f″ ± %.2f″" % [combined.value, combined.sigma], HORIZONTAL_ALIGNMENT_LEFT, -1, 16, c)
