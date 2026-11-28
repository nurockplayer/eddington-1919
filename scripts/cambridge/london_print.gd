extends "res://scripts/cambridge/interlude_paper.gd"
## The public record after the joint meeting, with Rook's column on a separate sheet.

signal completed

const Content := preload("res://scripts/cambridge/content_london_print.gd")
const London := preload("res://scripts/cambridge/content_london.gd")
const Chart := preload("res://scripts/chart.gd")

const PAGES := [
	["I5-01", "I5-02", ["I5-03", "I5-04", "I5-05", "I5-06"]],
	["I5-01", "I5-02", ["I5-16", "I5-17"]],
	["I5-01", "I5-02", ["I5-07", "I5-08", "I5-09"]],
	["I5-01", "I5-02", ["I5-18"]],
	["I5-01", "I5-02", ["I5-19", "I5-20", "I5-21"]],
	["I5-01", "I5-02", ["I5-22", "I5-23", "I5-24", "I5-10"]],
	["I5-01", "I5-02", ["I5-25"]],
	["I5-01", "I5-13", ["I5-14", "I5-15"]],
	["I5-01", "I5-02", ["I5-11"], "I5-12"],
	["I6-01", "I6-02", ["I6-03", "I6-04", "I6-05"]],
	["I6-01", "I6-02", ["I6-06", "I6-07", "I6-08", "I6-09", "I6-10"]],
	["I6-01", "I6-02", ["I6-17", "I6-18", "I6-19", "I6-20"]],
	["I6-01", "I6-02", ["I6-11", "I6-12"]],
	["I6-01", "I6-02", ["I6-13", "I6-14", "I6-15"], "I6-16"],
]
const HEADLINES := ["I5-04", "I5-08", "I6-14"]

var _text := Content.strings()
var _readings := Content.english_readings() if L.current() == "en" else {}
var _next := London.strings().L14 as String
var _page := 0
var _chart: Control


func open() -> void:
	resized.connect(queue_redraw)
	begin_plate(preload("res://assets/journey/london-news-v2.png"), L.t("倫敦・1919 年 11 月 7 日"))
	advance(_next)
	await action
	action.connect(_advance)
	_show_page()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("30271d"))


func refresh_fonts() -> void:
	if is_instance_valid(_chart):
		_chart.refresh_fonts()


func _advance(_id: String) -> void:
	_page += 1
	if _page == PAGES.size():
		actions.hide()
		completed.emit()
	else:
		_show_page()


func _show_page() -> void:
	var page: Array = PAGES[_page]
	var lines: Array = page[2]
	begin(lines[0] == "I5-22")
	var scroll: ScrollContainer = body.get_parent()
	var layout: VBoxContainer = scroll.get_parent()
	label(layout, _text[page[0]], 32)
	layout.move_child(layout.get_child(-1), 0)
	label(body, _text[page[1]], 19)
	rule(body)
	for id in lines:
		label(body, _text[id], 30 if id in HEADLINES else 24)
		if _readings.has(id):
			label(body, _readings[id], 18)
		if id == "I5-22":
			_show_diagram()
		if id == "I6-05":
			label(body, L.t("Einstein Archives ALS 9-260"), 18)
	advance(_text[page[3]] if page.size() == 4 else _next)


func _show_diagram() -> void:
	var row := columns(body)
	var ray := RayDiagram.new()
	ray.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(ray)
	_label_ray(ray, L.t("恆星的視位置"), Vector2(28, 0))
	_label_ray(ray, L.t("恆星的真實位置"), Vector2(18, 61))
	_chart = Chart.new()
	_chart.reference_only = true
	_chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(_chart)


func _label_ray(ray: Control, text: String, at: Vector2) -> void:
	var caption := Label.new()
	caption.text = text
	caption.position = at
	Settings.track_font(caption, 16)
	caption.add_theme_color_override("font_color", Report.INK)
	ray.add_child(caption)


class RayDiagram extends Control:
	func _get_minimum_size() -> Vector2:
		return Vector2(0, 150)

	func _draw() -> void:
		var ink := Color("4b3928")
		var sun := Vector2(size.x * 0.48, 105)
		var star := Vector2(18, 48)
		var apparent := Vector2(18, 20)
		var tangent := Vector2(size.x * 0.55, 62)
		var observer := Vector2(size.x - 18, 62)
		observer.y = tangent.y + (observer.x - tangent.x) * (tangent.y - apparent.y) / (tangent.x - apparent.x)
		var ray := Curve2D.new()
		ray.add_point(star)
		ray.add_point(tangent, Vector2(-55, -14), (observer - tangent) * 0.38)
		ray.add_point(observer)
		draw_circle(sun, 29, Color("d7b374"), true, -1.0, true)
		draw_arc(sun, 29, 0, TAU, 40, ink, 1.5, true)
		draw_polyline(ray.get_baked_points(), ink, 2.0, true)
		draw_dashed_line(apparent, tangent, ink, 1.5, 6.0, true, true)
		draw_circle(star, 4, ink, true, -1.0, true)
		draw_circle(apparent, 4, ink, false, 1.5, true)
		draw_circle(observer, 4, ink, true, -1.0, true)
