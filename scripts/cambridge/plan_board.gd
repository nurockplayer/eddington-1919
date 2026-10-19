extends Control
class_name CambridgePlanBoard
## Four-slot plan picker with a reconsideration gate for biased cards.

signal reaction(seq: Array)
signal blocked(card: Dictionary)
signal finished(ids: Array)

const C17 = preload("res://scripts/cambridge/content_1917.gd")
const INK := Color(0.16, 0.13, 0.10)
const PAPER := Color(0.86, 0.80, 0.68)
const PAPER_EDGE := Color(0.50, 0.37, 0.23)

var selected: Array = []
var card_buttons: Dictionary = {}
var finish_btn: Button
var _cards: Array = []


func _ready() -> void:
	hide()


static func can_finish(ids: Array, cards: Array) -> bool:
	if ids.size() < 3 or ids.size() > 4:
		return false
	var seen: Dictionary = {}
	for id in ids:
		if seen.has(id):
			return false
		seen[id] = true
		var card := _find_card(id, cards)
		if card.is_empty() or card.get("kind", "") == "bias":
			return false
	return true


static func _find_card(id: Variant, cards: Array) -> Dictionary:
	for card in cards:
		if card.get("id", "") == id:
			return card
	return {}


func open() -> void:
	selected.clear()
	card_buttons.clear()
	_cards = C17.plan_cards()
	for child in get_children():
		child.queue_free()
	_build()
	visible = true


func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := ColorRect.new()
	panel.color = Color(0.025, 0.025, 0.03, 0.90)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var sheet := Panel.new()
	sheet.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	sheet.anchor_left = 0.055
	sheet.anchor_top = 0.035
	sheet.anchor_right = 0.945
	sheet.anchor_bottom = 0.965
	var sheet_style := StyleBoxFlat.new()
	sheet_style.bg_color = PAPER
	sheet_style.set_border_width_all(2)
	sheet_style.border_color = PAPER_EDGE
	sheet_style.shadow_color = Color(0, 0, 0, 0.24)
	sheet_style.shadow_size = 12
	sheet.add_theme_stylebox_override("panel", sheet_style)
	add_child(sheet)
	var layout := VBoxContainer.new()
	layout.anchor_left = 0.075
	layout.anchor_top = 0.065
	layout.anchor_right = 0.925
	layout.anchor_bottom = 0.935
	layout.add_theme_constant_override("separation", 16)
	add_child(layout)
	var title := Label.new()
	title.text = "怎樣的日食觀測，才算公平的比較？"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", INK)
	layout.add_child(title)
	var slot_row := GridContainer.new()
	slot_row.columns = 2
	slot_row.add_theme_constant_override("h_separation", 14)
	slot_row.add_theme_constant_override("v_separation", 8)
	layout.add_child(slot_row)
	var slots: Array[Label] = []
	for i in 4:
		var slot := Label.new()
		slot.name = "PlanSlot%d" % (i + 1)
		slot.text = "%d. ——" % (i + 1)
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(0, 48)
		slot.add_theme_color_override("font_color", INK)
		slot_row.add_child(slot)
		slots.append(slot)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	layout.add_child(grid)
	for card in _cards:
		var button := Button.new()
		button.text = card.text
		button.toggle_mode = true
		button.set_meta("original_text", str(card.text))
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 70)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_card_button(button, false)
		button.pressed.connect(_toggle_card.bind(card, button, slots))
		grid.add_child(button)
		card_buttons[card.id] = button
	finish_btn = Button.new()
	finish_btn.text = "完成計畫"
	_style_card_button(finish_btn, false)
	finish_btn.disabled = true
	finish_btn.pressed.connect(_finish)
	finish_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	layout.add_child(finish_btn)


func _toggle_card(card: Dictionary, button: Button, slots: Array[Label]) -> void:
	var id: String = card.id
	if selected.has(id):
		selected.erase(id)
		button.button_pressed = false
	else:
		if selected.size() >= 4:
			button.button_pressed = false
			return
		selected.append(id)
		button.button_pressed = true
		reaction.emit(card.get("react", []))
	_style_card_button(button, button.button_pressed)
	_update_slots(slots)
	finish_btn.disabled = selected.size() < 3


func _update_slots(slots: Array[Label]) -> void:
	for i in slots.size():
		var label := slots[i]
		if i < selected.size():
			var card := _find_card(selected[i], _cards)
			label.text = "✓  %d. %s" % [i + 1, card.get("text", "")]
		else:
			label.text = "%d. ——" % (i + 1)


func _style_card_button(button: Button, is_selected: bool) -> void:
	var original := str(button.get_meta("original_text", button.text))
	if button.has_meta("original_text"):
		button.text = ("✓  " if is_selected else "　　") + original
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_hover_pressed_color", INK)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.89, 0.83, 0.72)
	normal.set_border_width_all(1)
	normal.border_color = PAPER_EDGE
	normal.set_corner_radius_all(2)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var selected_style := StyleBoxFlat.new()
	selected_style.bg_color = Color(0.76, 0.67, 0.51)
	selected_style.set_border_width_all(3)
	selected_style.border_color = Color(0.20, 0.17, 0.13)
	selected_style.set_corner_radius_all(2)
	selected_style.content_margin_left = 12
	selected_style.content_margin_right = 12
	selected_style.content_margin_top = 8
	selected_style.content_margin_bottom = 8
	var hover := StyleBoxFlat.new()
	hover.bg_color = Color(0.91, 0.85, 0.73)
	hover.set_border_width_all(2)
	hover.border_color = PAPER_EDGE
	hover.set_corner_radius_all(2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", selected_style if is_selected else hover)
	button.add_theme_stylebox_override("pressed", selected_style)
	button.add_theme_stylebox_override("focus", hover)


func _finish() -> void:
	if selected.size() < 3:
		return
	for id in selected:
		var card := _find_card(id, _cards)
		if card.get("kind", "") == "bias":
			blocked.emit(card)
			return
	if can_finish(selected, _cards):
		finished.emit(selected.duplicate())
