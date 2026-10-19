extends Control
class_name CambridgeReportSheet
## Full-screen, scrollable report form. Row content is owned by C17.

signal submitted(report: Dictionary)
signal closed

const Cast = preload("res://scripts/cambridge/cast.gd")
const C17 = preload("res://scripts/cambridge/content_1917.gd")
const INK := Color(0.16, 0.13, 0.10)
const PAPER := Color(0.86, 0.80, 0.68)
const PAPER_EDGE := Color(0.50, 0.37, 0.23)

var selected: Dictionary = {}
var option_buttons: Dictionary = {}
var submit_btn: Button
var close_btn: Button
var _state: Dictionary = {}


func _ready() -> void:
	hide()


static func available_options(row: Dictionary, state: Dictionary) -> Array:
	if not _requirements_met(row.get("needs", []), state):
		return []
	var result: Array = []
	for option in row.get("options", []):
		if _requirements_met(option.get("needs", []), state):
			result.append(option)
	return result


static func _requirements_met(needs: Array, state: Dictionary) -> bool:
	for requirement in needs:
		var key := str(requirement)
		var present: bool = bool(state.get(key, state.get("residual_found", false) if key == "residual" else false))
		if not present:
			return false
	return true


func open(state: Dictionary) -> void:
	_state = state.duplicate(true)
	selected.clear()
	option_buttons.clear()
	for child in get_children():
		child.queue_free()
	_build()
	visible = true


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.025, 0.025, 0.03, 0.90)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var sheet := Panel.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.anchor_left = 0.055
	sheet.anchor_top = 0.035
	sheet.anchor_right = 0.945
	sheet.anchor_bottom = 0.91
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = PAPER
	sheet_style.set_border_width_all(2)
	sheet_style.border_color = PAPER_EDGE
	sheet_style.shadow_color = Color(0, 0, 0, 0.24)
	sheet_style.shadow_size = 12
	sheet.add_theme_stylebox_override("panel", sheet_style)
	add_child(sheet)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.anchor_left = 0.075
	scroll.anchor_top = 0.055
	scroll.anchor_right = 0.925
	scroll.anchor_bottom = 0.885
	add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 16)
	scroll.add_child(page)
	var title := Label.new()
	title.text = "核對紀錄"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", INK)
	page.add_child(title)
	for row in C17.report_rows():
		_add_row(page, row)
	var actions := HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 20)
	add_child(actions)
	actions.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	actions.offset_left = -260
	actions.offset_right = 260
	actions.offset_top = -76
	actions.offset_bottom = -12
	actions.add_theme_constant_override("separation", 18)
	close_btn = Button.new()
	close_btn.text = "關閉"
	_style_button(close_btn)
	close_btn.pressed.connect(func():
		visible = false
		closed.emit())
	actions.add_child(close_btn)
	submit_btn = Button.new()
	submit_btn.text = "交給 %s" % Cast.MENTOR
	_style_button(submit_btn)
	submit_btn.pressed.connect(_submit)
	actions.add_child(submit_btn)


func _add_row(page: VBoxContainer, row: Dictionary) -> void:
	var heading := Label.new()
	heading.text = row.text
	heading.add_theme_font_size_override("font_size", 23)
	heading.add_theme_color_override("font_color", INK)
	page.add_child(heading)
	var available := available_options(row, _state)
	if row.id == "residual" and available.is_empty():
		var missing := Label.new()
		missing.text = "（沒有發現）"
		missing.add_theme_color_override("font_color", Color(0.35, 0.30, 0.24))
		page.add_child(missing)
		selected["residual"] = "not_found"
		return
	var choices := GridContainer.new()
	choices.columns = 2
	choices.add_theme_constant_override("h_separation", 10)
	choices.add_theme_constant_override("v_separation", 8)
	page.add_child(choices)
	for option in available:
		var button: Button = CheckBox.new() if row.id == "kit_credited" else Button.new()
		button.set_meta("original_text", option.text)
		button.text = option.text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
		_style_button(button)
		button.pressed.connect(_select_option.bind(str(row.id), str(option.id), button))
		choices.add_child(button)
		option_buttons["%s/%s" % [row.id, option.id]] = button
		if row.id == "kit_credited":
			button.button_pressed = bool(_state.get("kit_checked", false))
			if button.button_pressed:
				selected["kit_credited"] = true
		elif (row.id == "cause" and option.id == "unknown") or (row.id == "original" and option.id == "keep") or (row.id == "residual" and option.id == "unresolved"):
			button.button_pressed = true
			selected[str(row.id)] = str(option.id)
		_refresh_option(row.id, button, button.button_pressed)


func _select_option(row_id: String, option_id: String, button: Button) -> void:
	if row_id == "kit_credited":
		selected["kit_credited"] = button.button_pressed
		_refresh_option(row_id, button, button.button_pressed)
		return
	for key in option_buttons:
		if str(key).begins_with(row_id + "/"):
			var option_button := option_buttons[key] as Button
			option_button.button_pressed = key == "%s/%s" % [row_id, option_id]
			_refresh_option(row_id, option_button, option_button.button_pressed)
	selected[row_id] = option_id


func _refresh_option(_row_id: String, button: Button, is_selected: bool) -> void:
	var original := str(button.get_meta("original_text", button.text))
	button.text = original if button is CheckBox else ("✓  " if is_selected else "　　") + original
	var normal := _choice_style(false)
	var pressed := _choice_style(true)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", pressed if is_selected else _choice_style(false, true))
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", pressed)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_hover_pressed_color", INK)
	button.add_theme_color_override("font_hover_color", INK)


func _choice_style(is_selected: bool, is_hover: bool = false) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.76, 0.67, 0.51) if is_selected else (Color(0.91, 0.85, 0.73) if is_hover else Color(0.89, 0.83, 0.72))
	style.set_border_width_all(2 if is_selected else 1)
	style.border_color = Color(0.20, 0.17, 0.13) if is_selected else PAPER_EDGE
	style.set_corner_radius_all(2)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style


func _style_button(button: Button) -> void:
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_hover_pressed_color", INK)
	var style := _choice_style(false)
	style.bg_color = Color(0.91, 0.85, 0.72)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", _choice_style(false, true))
	button.add_theme_stylebox_override("pressed", _choice_style(true))
	button.add_theme_stylebox_override("focus", _choice_style(false, true))


func _submit() -> void:
	var report := selected.duplicate(true)
	if not report.has("residual"):
		report["residual"] = "not_found"
	if not _state.get("kit_checked", false):
		report["kit_credited"] = false
	hide()
	submitted.emit(report)
