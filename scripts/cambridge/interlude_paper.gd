extends Control
## Scrollable report-sheet presentation for clippings, letters and other archival inserts.

const Report := preload("res://scripts/cambridge/report_sheet.gd")
const Settings := preload("res://scripts/settings.gd")

signal action(id: String)

var body: VBoxContainer
var actions: HBoxContainer


func begin(wide := false, comparison := false) -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0.025, 0.025, 0.03, 0.30)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)

	var sheet := Panel.new()
	sheet.anchor_left = 0.05 if wide else 0.14
	sheet.anchor_right = 1.0 - sheet.anchor_left
	sheet.anchor_top = 0.08 if comparison else 0.04
	sheet.anchor_bottom = 0.29 if comparison else 0.96
	sheet.add_theme_stylebox_override("panel", Report.paper_style())
	add_child(sheet)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 32
	layout.offset_right = -32
	layout.offset_top = 16
	layout.offset_bottom = -16
	layout.add_theme_constant_override("separation", 10)
	sheet.add_child(layout)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.75, 0.65, 0.50)
	track.content_margin_left = 10
	for state in ["scroll", "scroll_focus"]:
		scroll.get_v_scroll_bar().add_theme_stylebox_override(state, track)
	var thumb := track.duplicate() as StyleBoxFlat
	thumb.bg_color = Report.PAPER_EDGE
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		scroll.get_v_scroll_bar().add_theme_stylebox_override(state, thumb)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)

	# Draw over the sliver of any line or block straddling either fold. The
	# body keeps its layout and the scroll range still reaches every item.
	var fold := Node2D.new()
	scroll.add_child(fold)
	fold.draw.connect(func():
		if scroll.get_v_scroll_bar().visible:
			var window := Rect2(Vector2.ZERO, Vector2(body.size.x, scroll.size.y))
			_draw_partial_rows(fold, body, window)
	)
	scroll.get_v_scroll_bar().value_changed.connect(func(_value): fold.queue_redraw())
	scroll.sort_children.connect(fold.queue_redraw)
	body.sort_children.connect(fold.queue_redraw)

	actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	actions.hide()
	show()


func _draw_partial_rows(fold: Node2D, parent: Container, window: Rect2) -> void:
	for child in parent.get_children():
		if not child is Control or not child.visible:
			continue
		var rect := Rect2(fold.to_local(child.global_position), child.size)
		if not rect.intersects(window) or window.encloses(rect):
			continue
		if child is Container:
			_draw_partial_rows(fold, child, window)
		elif child is Label:
			if child.get_line_count() == 1:
				fold.draw_rect(window.intersection(rect), Report.PAPER)
				continue
			for line in line_boxes(child):
				var row := Rect2(rect.position + Vector2(0, line.rect.position.y),
						Vector2(rect.size.x, line.rect.size.y))
				if row.intersects(window) and not window.encloses(row):
					fold.draw_rect(window.intersection(row), Report.PAPER)
		else:
			fold.draw_rect(window.intersection(rect), Report.PAPER)


static func line_boxes(control: Label) -> Array[Dictionary]:
	var lines: Array[Dictionary] = []
	for i in control.text.length():
		var bounds := control.get_character_bounds(i)
		if bounds.size.y <= 0.0:
			continue
		if lines.is_empty() or bounds.position.y != lines[-1].rect.position.y:
			lines.append({"rect": bounds, "text": ""})
		lines[-1].text += control.text[i]
	return lines


func heading(text: String, font_size: int, centered := false) -> void:
	var layout: VBoxContainer = actions.get_parent()
	label(layout, text, font_size, centered)
	layout.move_child(layout.get_child(-1), body.get_parent().get_index())


func label(parent: Container, text: String, font_size: int, centered := false) -> void:
	var line := Label.new()
	line.text = text
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if centered:
		line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Settings.track_font(line, font_size)
	line.add_theme_color_override("font_color", Report.INK)
	parent.add_child(line)


func rule(parent: Container) -> void:
	var ink := StyleBoxLine.new()
	ink.color = Report.PAPER_EDGE
	var rule_line := HSeparator.new()
	rule_line.add_theme_stylebox_override("separator", ink)
	parent.add_child(rule_line)


func columns(parent: Container) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	parent.add_child(row)
	return row


func column(row: BoxContainer) -> VBoxContainer:
	var contents := VBoxContainer.new()
	contents.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	contents.add_theme_constant_override("separation", 10)
	row.add_child(contents)
	return contents


func section(parent: Container, title: String, paragraphs: Array, source: String) -> void:
	if not title.is_empty():
		label(parent, title, 32)
	for paragraph in paragraphs:
		label(parent, paragraph, 24)
	if not source.is_empty():
		label(parent, source, 18)


func button(parent: Container, text: String, id: String, font_size := 21) -> Button:
	var control := Button.new()
	control.text = text
	# The centred footer uses the button's natural width. Tray and heading
	# buttons expand into their columns and can wrap within them.
	if parent != actions:
		control.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Settings.track_font(control, font_size)
	Report._style_button(control)
	control.pressed.connect(func(): action.emit(id))
	parent.add_child(control)
	return control


func advance(text: String) -> void:
	actions.show()
	button(actions, text, "advance").grab_focus()
