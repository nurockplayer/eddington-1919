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
	sheet.anchor_left = 0.08 if wide else 0.20
	sheet.anchor_right = 1.0 - sheet.anchor_left
	sheet.anchor_top = 0.08
	sheet.anchor_bottom = 0.29 if comparison else 0.92
	sheet.add_theme_stylebox_override("panel", Report.paper_style())
	add_child(sheet)

	var layout := VBoxContainer.new()
	layout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	layout.offset_left = 32
	layout.offset_right = -32
	layout.offset_top = 22
	layout.offset_bottom = -22
	layout.add_theme_constant_override("separation", 16)
	sheet.add_child(layout)

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(scroll)
	scroll.get_v_scroll_bar().focus_mode = Control.FOCUS_ALL
	var track := StyleBoxFlat.new()
	track.bg_color = Report.PAPER.darkened(0.1)
	track.content_margin_left = 8
	scroll.get_v_scroll_bar().add_theme_stylebox_override("scroll", track)
	var thumb := track.duplicate() as StyleBoxFlat
	thumb.bg_color = Report.PAPER_EDGE
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		scroll.get_v_scroll_bar().add_theme_stylebox_override(state, thumb)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 14)
	scroll.add_child(body)
	body.sort_children.connect(_align_end_fold.bind(scroll, body))
	scroll.resized.connect(_align_end_fold.bind(scroll, body))

	actions = HBoxContainer.new()
	actions.alignment = BoxContainer.ALIGNMENT_CENTER
	actions.add_theme_constant_override("separation", 12)
	layout.add_child(actions)
	actions.hide()
	show()


func _align_end_fold(scroll: ScrollContainer, contents: VBoxContainer) -> void:
	var height := scroll.size.y
	var natural_height := contents.get_minimum_size().y
	var padded_height := 0.0
	if natural_height > height:
		padded_height = natural_height + contents.get_theme_constant("separation")
		var end := floori(padded_height - height)
		for row: Control in contents.get_children():
			var bottom := row.position.y + row.size.y
			if row is Label and row.position.y < end and end < bottom:
				# Give the scroll range enough paper below the final line to
				# move the resting top edge past the interrupted text row.
				padded_height = height + ceilf(bottom)
				break
	if padded_height == contents.custom_minimum_size.y:
		return
	contents.custom_minimum_size.y = padded_height
	if padded_height > 0.0 and scroll.scroll_vertical >= floori(natural_height - height):
		scroll.set_deferred("scroll_vertical", ceili(padded_height))


func begin_plate(texture: Texture2D, place_date: String) -> void:
	begin(true)
	var sheet: Panel = actions.get_parent().get_parent()
	# Fit the entire landscape plate above the caption and footer at large text scale.
	sheet.anchor_left = 0.17
	sheet.anchor_right = 0.83
	var image := TextureRect.new()
	image.name = "OpeningPlate"
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(image)
	var contents := body
	var aspect := float(texture.get_height()) / texture.get_width()
	contents.resized.connect(func(): image.custom_minimum_size.y = ceilf(contents.size.x * aspect))
	label(body, L.t("%s・歷史重建") % place_date, 18, true)
	var caption: Label = body.get_child(-1)
	caption.add_theme_font_override("font", Fonts.paper_serif(get_theme_default_font()))


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
