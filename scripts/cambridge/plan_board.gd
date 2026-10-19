extends Control
class_name CambridgePlanBoard
## Four-slot plan picker with a reconsideration gate for biased cards.

signal reaction(seq: Array)
signal blocked(card: Dictionary)
signal finished(ids: Array)

const C17 = preload("res://scripts/cambridge/content_1917.gd")

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
	panel.color = Color(0.025, 0.025, 0.03, 0.95)
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)
	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 100
	layout.offset_top = 48
	layout.offset_right = -100
	layout.offset_bottom = -48
	layout.add_theme_constant_override("separation", 16)
	add_child(layout)
	var title := Label.new()
	title.text = "怎樣的日食觀測，才算公平的比較？"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	layout.add_child(title)
	var slot_row := HBoxContainer.new()
	slot_row.add_theme_constant_override("separation", 8)
	layout.add_child(slot_row)
	var slots: Array[Label] = []
	for i in 4:
		var slot := Label.new()
		slot.name = "PlanSlot%d" % (i + 1)
		slot.text = "%d. ——" % (i + 1)
		slot.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.custom_minimum_size = Vector2(0, 46)
		slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_toggle_card.bind(card, button, slots))
		grid.add_child(button)
		card_buttons[card.id] = button
	finish_btn = Button.new()
	finish_btn.text = "完成計畫"
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
	_update_slots(slots)
	finish_btn.disabled = selected.size() < 3


func _update_slots(slots: Array[Label]) -> void:
	for i in slots.size():
		var label := slots[i]
		if i < selected.size():
			var card := _find_card(selected[i], _cards)
			label.text = "%d. %s" % [i + 1, card.get("text", "")]
		else:
			label.text = "%d. ——" % (i + 1)


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
