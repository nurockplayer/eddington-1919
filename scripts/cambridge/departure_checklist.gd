extends Control
## Last shared page. A row cannot be marked until Kit has finished reading it.
signal row_requested(index: int)
signal completed(result: Dictionary)
signal closed

const Content := preload("res://scripts/cambridge/content_departure.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")

var entries: Array = []
var marks: Dictionary = {}
var active_index := 0
var ready_to_mark := false
var input_blocked := false
var row_buttons: Array = []
var values: Array[RichTextLabel] = []
var plate_lines: Array[Label] = []
var continue_btn: Button
var correction_fix := -1
var _scroll: ScrollContainer
var _rows: Array[Control] = []
var _smudge: Control


class InkSmudge extends Control:
	func _draw() -> void:
		# Uneven rubbed ink, kept faint enough for the new value to remain readable.
		draw_line(Vector2(4, 16), Vector2(size.x - 5, 14), Color(0.25, 0.18, 0.11, 0.13), 12, true)
		draw_line(Vector2(10, 7), Vector2(size.x - 2, 10), Color(0.25, 0.18, 0.11, 0.09), 8, true)
		draw_line(Vector2(2, 23), Vector2(size.x - 12, 21), Color(0.25, 0.18, 0.11, 0.10), 6, true)


static func evaluate_marks(rows: Array, checked: Dictionary) -> Dictionary:
	var caught := false
	var alarm := false
	for entry in rows:
		if checked.has(entry.id) and checked[entry.id] == false:
			if entry.get("slip", false):
				caught = true
			else:
				alarm = true
	return {"caught_by_player": caught, "false_alarm": alarm}


func _ready() -> void:
	hide()


func open() -> void:
	entries = Content.check_entries()
	marks.clear()
	active_index = 0
	ready_to_mark = false
	correction_fix = -1
	row_buttons.clear()
	values.clear()
	plate_lines.clear()
	_rows.clear()
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_build()
	show()
	row_requested.emit(0)


func _label(text_: String, size_: int = 20) -> Label:
	var label := Label.new()
	label.text = text_
	label.add_theme_font_size_override("font_size", size_)
	label.add_theme_color_override("font_color", Report.INK)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _button(text_: String) -> Button:
	var button := Button.new()
	button.text = text_
	button.custom_minimum_size = Vector2(72, 44)
	button.add_theme_font_size_override("font_size", 22)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.91, 0.85, 0.73) if state != "disabled" else Color(0.79, 0.74, 0.65)
		style.border_color = Report.PAPER_EDGE
		style.set_border_width_all(2 if state in ["hover", "focus", "pressed"] else 1)
		style.set_content_margin_all(8)
		button.add_theme_stylebox_override(state, style)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(state, Report.INK)
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.39, 0.33))
	return button


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.025, 0.03, 0.88)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var sheet := Panel.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.anchor_left = 0.065
	sheet.anchor_right = 0.935
	sheet.anchor_top = 0.025
	sheet.anchor_bottom = 0.71
	var paper := StyleBoxFlat.new()
	paper.bg_color = Report.PAPER
	paper.border_color = Report.PAPER_EDGE
	paper.set_border_width_all(2)
	paper.shadow_color = Color(0, 0, 0, 0.3)
	paper.shadow_size = 12
	sheet.add_theme_stylebox_override("panel", paper)
	add_child(sheet)
	_scroll = ScrollContainer.new()
	_scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_scroll.anchor_left = 0.085
	_scroll.anchor_right = 0.915
	_scroll.anchor_top = 0.04
	_scroll.anchor_bottom = 0.695
	add_child(_scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 8)
	_scroll.add_child(page)
	var title := _label("畢宿星團比較星清單 · 最後一頁", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(title)
	var legend := _label("藍墨水：Kit　　褐墨水：你　　聽完底片數值，再逐行核對。", 18)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(legend)
	for i in entries.size():
		var entry: Dictionary = entries[i]
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 72
		row.add_theme_constant_override("separation", 18)
		page.add_child(row)
		_rows.append(row)
		var label := _label(entry.label, 22)
		label.custom_minimum_size.x = 116
		row.add_child(label)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		var value := RichTextLabel.new()
		value.bbcode_enabled = true
		value.fit_content = true
		value.scroll_active = false
		value.mouse_filter = Control.MOUSE_FILTER_IGNORE
		value.custom_minimum_size.y = 32
		var hand := SystemFont.new()
		hand.font_names = PackedStringArray(["Snell Roundhand", "Baskerville", "serif"] if entry.hand == "kit" else ["Baskerville", "Georgia", "serif"])
		hand.font_italic = true
		value.add_theme_font_override("normal_font", hand)
		value.add_theme_font_size_override("normal_font_size", 25)
		value.add_theme_color_override("default_color", Color(0.10, 0.23, 0.31) if entry.hand == "kit" else Color(0.30, 0.16, 0.09))
		value.text = entry.list
		column.add_child(value)
		values.append(value)
		if entry.get("slip", false):
			_smudge = InkSmudge.new()
			var prefix_width := hand.get_string_size("x 41.27　y ", HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
			var number_width := hand.get_string_size("16.83", HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
			_smudge.position = Vector2(prefix_width - 4, 1)
			_smudge.size = Vector2(number_width + 8, 30)
			_smudge.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_smudge.show_behind_parent = true
			var ghost := Label.new()
			ghost.text = "18.63"
			ghost.position = Vector2(4, -1)
			ghost.add_theme_font_override("font", hand)
			ghost.add_theme_font_size_override("font_size", 25)
			ghost.add_theme_color_override("font_color", Color(0.30, 0.16, 0.09, 0.25))
			ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_smudge.add_child(ghost)
			_smudge.hide()
			value.add_child(_smudge)
		var plate_line := _label("Kit 念出：……", 18)
		column.add_child(plate_line)
		plate_lines.append(plate_line)
		var buttons: Array = []
		for mark in [true, false]:
			var button := _button("✓" if mark else "✗")
			button.disabled = true
			button.pressed.connect(_mark.bind(i, mark))
			row.add_child(button)
			buttons.append(button)
		row_buttons.append(buttons)
	continue_btn = _button("收好清單")
	continue_btn.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	continue_btn.offset_left = -120
	continue_btn.offset_right = 120
	continue_btn.offset_top = -148
	continue_btn.offset_bottom = -96
	continue_btn.pressed.connect(func():
		if not input_blocked:
			hide()
			closed.emit())
	continue_btn.hide()
	add_child(continue_btn)


func begin_read() -> void:
	ready_to_mark = false
	plate_lines[active_index].text = "Kit 念出：" + str(entries[active_index].plate)
	_scroll.ensure_control_visible(_rows[active_index])


func allow_mark() -> void:
	ready_to_mark = true
	for button in row_buttons[active_index]:
		button.disabled = false
		button.add_theme_color_override("font_color", Report.INK)
	_scroll.ensure_control_visible(_rows[active_index])


func _mark(index: int, correct: bool) -> void:
	if input_blocked or not ready_to_mark or index != active_index or marks.has(entries[index].id):
		return
	marks[entries[index].id] = correct
	ready_to_mark = false
	for button in row_buttons[index]:
		button.disabled = true
	row_buttons[index][0 if correct else 1].text += " 已記"
	active_index += 1
	if active_index == entries.size():
		completed.emit(evaluate_marks(entries, marks))
	else:
		row_requested.emit(active_index)


func show_correction(fix: int) -> void:
	correction_fix = fix
	for i in entries.size():
		if not entries[i].get("slip", false):
			continue
		values[i].text = "x 41.27　y [s]18.63[/s]　16.83　" + Cast.YOU_INITIALS if fix == 0 else "x 41.27　y 16.83"
		_smudge.visible = fix == 1
		plate_lines[i].text = "劃線、改正、簽名（" + Cast.YOU_INITIALS + "：你的縮寫）" if fix == 0 else "擦改的墨跡還留在紙上"
		_scroll.ensure_control_visible(_rows[i])
	continue_btn.show()
	continue_btn.disabled = true
