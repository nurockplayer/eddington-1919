extends Control
class_name CambridgeReportSheet
## Full-screen, scrollable report form. Row content is owned by C17.

signal submitted(report: Dictionary)
signal closed

const Cast = preload("res://scripts/cambridge/cast.gd")
const C17 = preload("res://scripts/cambridge/content_1917.gd")

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
	backdrop.color = Color(0.025, 0.025, 0.03, 0.94)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 120
	scroll.offset_top = 48
	scroll.offset_right = -120
	scroll.offset_bottom = -96
	add_child(scroll)
	var page := VBoxContainer.new()
	page.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page.add_theme_constant_override("separation", 16)
	scroll.add_child(page)
	var title := Label.new()
	title.text = "［暫］核對記錄"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
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
	close_btn = Button.new()
	close_btn.text = "［暫］關閉"
	close_btn.pressed.connect(func():
		visible = false
		closed.emit())
	actions.add_child(close_btn)
	submit_btn = Button.new()
	submit_btn.text = "交給 %s" % Cast.MENTOR
	submit_btn.pressed.connect(_submit)
	actions.add_child(submit_btn)


func _add_row(page: VBoxContainer, row: Dictionary) -> void:
	var heading := Label.new()
	heading.text = row.text
	heading.add_theme_font_size_override("font_size", 23)
	page.add_child(heading)
	var available := available_options(row, _state)
	if row.id == "residual" and available.is_empty():
		var missing := Label.new()
		missing.text = "［暫］（沒有發現）"
		page.add_child(missing)
		selected["residual"] = "not_found"
		return
	var choices := GridContainer.new()
	choices.columns = 2
	choices.add_theme_constant_override("h_separation", 10)
	choices.add_theme_constant_override("v_separation", 8)
	page.add_child(choices)
	for option in available:
		var button := Button.new()
		button.text = option.text
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size = Vector2(0, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.toggle_mode = true
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


func _select_option(row_id: String, option_id: String, button: Button) -> void:
	if row_id == "kit_credited":
		selected["kit_credited"] = button.button_pressed
		return
	for key in option_buttons:
		if str(key).begins_with(row_id + "/"):
			(option_buttons[key] as Button).button_pressed = key == "%s/%s" % [row_id, option_id]
	selected[row_id] = option_id


func _submit() -> void:
	var report := selected.duplicate(true)
	if not report.has("residual"):
		report["residual"] = "not_found"
	if not _state.get("kit_checked", false):
		report["kit_credited"] = false
	hide()
	submitted.emit(report)
