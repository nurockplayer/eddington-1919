extends Control
## Conversion arc D: the October 1919 chart overlay. The player's Príncipe result is
## copied onto the 1917 copy, then the two Sobral rows, one press each. No combination
## is drawn: the three rows are different instruments, not one pooled measurement.

signal completed

const Settings := preload("res://scripts/settings.gd")
const Chart := preload("res://scripts/chart.gd")

var run: Dictionary = {}
var chart
var rows: Array = []
var notes: Array[String] = []
var step := 0
var button: Button
var input_blocked := false:
	set(value):
		input_blocked = value
		if is_instance_valid(button):
			button.disabled = value
var _built := false
var _note_box: VBoxContainer


func _ready() -> void:
	hide()


func open(p_run: Dictionary) -> void:
	run = p_run if p_run != null else {}
	step = 0
	if not _built:
		_build()
		_built = true
	_refresh()
	chart.refresh_fonts()
	show()
	button.grab_focus()


## The UI's text-size button refreshes the main chart; this overlay asks for the same.
func refresh_fonts() -> void:
	if is_instance_valid(chart):
		chart.refresh_fonts()


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.025, 0.03, 0.9)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)
	chart = Chart.new()
	chart.custom_minimum_size = Vector2(0, 280)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chart.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(chart)
	_note_box = VBoxContainer.new()
	_note_box.add_theme_constant_override("separation", 2)
	column.add_child(_note_box)
	button = Button.new()
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_ALL
	Settings.track_font(button, 22)
	button.pressed.connect(_press)
	column.add_child(button)


func _refresh() -> void:
	rows = []
	notes = []
	var c: Dictionary = run.get("combined", {})
	if int(c.get("n", 0)) > 0:
		rows.append({"label": "你的底片（示意模擬）", "value": float(c.value), "sigma": float(c.sigma)})
	else:
		notes.append("你的底片：沒有數值。")
	if step >= 1:
		rows.append({"label": "Sobral 4 吋", "value": 1.98, "sigma": 0.18})
		notes.append("Sobral 4 吋：1.98″，±0.12″ 機率誤差，約 0.18″ 標準差")
	if step >= 2:
		rows.append({"label": "Sobral 天體照相儀", "value": 0.93, "sigma": 0.0, "weak": true, "no_bar": true})
		notes.append("Sobral 天體照相儀：約 0.93″，沒有可靠的誤差")
	chart.set_data(rows, {}, true)
	for child in _note_box.get_children():
		_note_box.remove_child(child)
		child.queue_free()
	for line in notes:
		var label := Label.new()
		label.text = line
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		Settings.track_font(label, 17)
		label.add_theme_color_override("font_color", Color(0.85, 0.82, 0.75))
		_note_box.add_child(label)
	button.text = ["抄上 Sobral 4 吋", "抄上 Sobral 天體照相儀", "抄好了"][step]


func _press() -> void:
	if input_blocked:
		return
	if step < 2:
		step += 1
		_refresh()
		button.grab_focus()
	else:
		completed.emit()
