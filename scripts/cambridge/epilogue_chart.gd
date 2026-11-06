extends Control
## Conversion arc D: the October 1919 chart overlay. The player's Príncipe result is
## copied onto the 1917 copy, then the two Sobral rows, one press each. No combination
## is drawn: the three rows are different instruments, not one pooled measurement.

signal completed

const Settings := preload("res://scripts/settings.gd")
const Chart := preload("res://scripts/chart.gd")
const MainContent := preload("res://scripts/content.gd")
const CambridgeContentEpilogue := preload("res://scripts/cambridge/content_epilogue.gd")

## 1.98 ± 2×0.18 = 1.62–2.34″ holds 1.75 only.
const SOBRAL_TRUTH := 1

var run: Dictionary = {}
var chart
var rows: Array = []
var notes: Array[String] = []
var step := 0
var button: Button
var question: Label
var choices: Array[Button] = []
var read_answer := -1
var input_blocked := false:
	set(value):
		input_blocked = value
		if is_instance_valid(button):
			button.disabled = value
		for b in choices:
			if is_instance_valid(b):
				b.disabled = value or read_answer >= 0
var _built := false
var _note_box: VBoxContainer
var _choice_box: VBoxContainer
var _column: VBoxContainer


func _ready() -> void:
	hide()


func open(p_run: Dictionary) -> void:
	run = p_run if p_run != null else {}
	step = 0
	read_answer = -1
	if not _built:
		_build()
		_built = true
	for b in choices:
		b.disabled = input_blocked
	button.text = ""
	_column.custom_minimum_size.x = minf(1040, get_viewport_rect().size.x - 64)
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
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_column = VBoxContainer.new()
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.add_theme_constant_override("separation", 10)
	center.add_child(_column)
	chart = Chart.new()
	chart.custom_minimum_size = Vector2(0, 340)
	chart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_column.add_child(chart)
	_note_box = VBoxContainer.new()
	_note_box.add_theme_constant_override("separation", 2)
	_column.add_child(_note_box)
	question = Label.new()
	question.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Settings.track_font(question, 20)
	question.visible = false
	_column.add_child(question)
	_choice_box = VBoxContainer.new()
	_choice_box.add_theme_constant_override("separation", 6)
	_choice_box.visible = false
	_column.add_child(_choice_box)
	var answers: Array = MainContent.interval_prompt("")[0].choices
	for i in answers.size():
		var choice := Button.new()
		choice.text = str(answers[i])
		choice.custom_minimum_size = Vector2(0, 44)
		choice.alignment = HORIZONTAL_ALIGNMENT_LEFT
		choice.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		choice.focus_mode = Control.FOCUS_ALL
		Settings.track_font(choice, 20)
		choice.pressed.connect(_read.bind(i))
		_choice_box.add_child(choice)
		choices.append(choice)
	button = Button.new()
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_ALL
	Settings.track_font(button, 22)
	button.pressed.connect(_press)
	_column.add_child(button)


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
	if step >= 3:
		question.visible = true
		_choice_box.visible = true
		if read_answer < 0:
			question.text = "Sobral 4 吋那一點：細線（兩倍誤差）裡容得下哪一個？"
		button.visible = read_answer >= 0
		return
	question.visible = false
	_choice_box.visible = false
	button.visible = true
	button.text = ["抄上 Sobral 4 吋", "抄上 Sobral 天體照相儀", "抄好了"][step]


func _press() -> void:
	if input_blocked:
		return
	if step < 2:
		step += 1
		_refresh()
		button.grab_focus()
	elif step == 2:
		step = 3
		_refresh()
		choices[0].grab_focus()
	else:
		completed.emit()


## The Sobral reading: every answer progresses; the chart stays open behind it.
func _read(index: int) -> void:
	if input_blocked:
		return
	read_answer = index
	for b in choices:
		b.disabled = true
	var text := MainContent.interval_feedback(read_answer, SOBRAL_TRUTH)
	if CambridgeContentEpilogue.ledger_case(run) == "conceded":
		text += "\n（和你的底片放在一起看——兩套儀器、隔一個大西洋。）"
	question.text = text
	button.text = "好"
	button.visible = true
	button.grab_focus()
