extends RefCounted
## In-play print furniture only; viewer and menu themes stay on their own root.

var ui: Node
var palette: Dictionary
var slips: Array[StyleBoxFlat] = []
var panel_slips := {}
var buttons: StyleBoxFlat
var selected_button: StyleBoxFlat
var hovered_button: StyleBoxFlat
var choice_focus := StyleBoxEmpty.new()
var foreground: Color
var evidence_dialogue := {}
var portrait_tint := Color.WHITE
var disclosure_wrap: int


func setup(target: Node, colours: Dictionary) -> void:
	ui = target
	palette = colours
	ui.paper_hud = true
	disclosure_wrap = ui.dialogue_portrait.disclosure.autowrap_mode
	ui.dialogue_portrait.disclosure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for label in [ui.clock_label, ui.prompt_label, ui.toast, ui.caption]:
		var slip := StyleBoxFlat.new()
		slip.set_border_width_all(1)
		# A Label's normal box is behind its existing content: no layout shift.
		slip.expand_margin_left = 16
		slip.expand_margin_right = 16
		slip.expand_margin_top = 16
		slip.expand_margin_bottom = 16
		label.add_theme_stylebox_override("normal", slip)
		label.add_theme_constant_override("outline_size", 0)
		slips.append(slip)
	for panel in [ui.objectives.get_parent(), ui.tot_panel, ui.dialog_panel, ui.dialogue_portrait]:
		var slip: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
		slip.set_corner_radius_all(0)
		slip.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", slip)
		slips.append(slip)
		panel_slips[panel] = slip
	buttons = ui._panel_style(palette.paper, palette.ink_col)
	buttons.set_corner_radius_all(0)
	buttons.set_border_width_all(1)
	buttons.set_content_margin_all(10)
	selected_button = buttons.duplicate()
	hovered_button = buttons.duplicate()
	hovered_button.set_border_width_all(3)
	ui.dialogue_entry.connect(func(_speaker: String): _choices())
	ui.tot_panel.visibility_changed.connect(_central_visibility)
	ui.paper_layout = _layout
	ui.hud.resized.connect(_layout)
	ui.objectives.get_parent().resized.connect(_layout)
	ui.toast.resized.connect(_toast_layout)
	ui.toast.minimum_size_changed.connect(_toast_layout)
	ui.tot_panel.resized.connect(_toast_layout)


func light(darkness: float, night: float, params: Dictionary) -> void:
	if evidence_dialogue.is_empty():
		evidence_dialogue = {
			"panel": ui.dialog_panel.get_theme_stylebox("panel"),
			"mount": ui.dialogue_portrait.get_theme_stylebox("panel"),
			"speaker": ui.speaker_label.get_theme_color("font_color"),
			"text": ui.text_label.get_theme_color("default_color"),
			"hint": ui.hint_label.get_theme_color("font_color"),
			"disclosure": ui.dialogue_portrait.disclosure.get_theme_color("font_color"),
		}
	var blue := darkness * float(params.tot_wash)
	var wash := night * float(params.night_wash)
	# The print's polarity follows its page. Tint within each polarity follows
	# the same lighting values as the engraving, including third contact.
	var dark := blue > 0.5 or wash > 0.5
	var background: Color = palette.ink_col.lerp(palette.tot_paper, blue * 0.15).lerp(palette.ink_col, wash) if dark else palette.paper
	foreground = palette.paper.lerp(palette.safe_light, wash) if dark else palette.ink_col
	for slip in slips:
		slip.bg_color = background
		slip.border_color = foreground
	for panel in panel_slips:
		panel.add_theme_stylebox_override("panel", panel_slips[panel])
	buttons.bg_color = background
	buttons.border_color = foreground
	selected_button.bg_color = foreground
	selected_button.border_color = foreground
	hovered_button.bg_color = background
	hovered_button.border_color = foreground
	for label in [ui.clock_label, ui.prompt_label, ui.toast, ui.caption, ui.tot_hint, ui.callout, ui.speaker_label, ui.hint_label, ui.dialogue_portrait.disclosure]:
		label.add_theme_color_override("font_color", foreground)
		label.add_theme_constant_override("outline_size", 0)
	ui.crosshair.add_theme_color_override("font_color", foreground)
	ui.crosshair.add_theme_color_override("font_outline_color", palette.ink_col if dark else palette.paper)
	ui.crosshair.add_theme_constant_override("outline_size", 3)
	for label in [ui.objectives, ui.tot_label, ui.text_label]:
		label.add_theme_color_override("default_color", foreground)
	# The original print stays on its card; multiply its paper by the page wash.
	portrait_tint = palette.paper.lerp(palette.tot_paper, blue).lerp(palette.safe_paper, wash) / palette.paper
	ui.dialogue_portrait.image.self_modulate = portrait_tint
	_choices()
	_central_visibility()


func _choices() -> void:
	# Row 7's report conversation is part of the evidence viewer, whose pixels
	# are deliberately outside this pass, including its shared dialogue controls.
	if ui.viewer.visible:
		ui.dialogue_portrait.disclosure.autowrap_mode = disclosure_wrap
		ui.dialog_panel.add_theme_stylebox_override("panel", evidence_dialogue.panel)
		ui.dialogue_portrait.add_theme_stylebox_override("panel", evidence_dialogue.mount)
		ui.speaker_label.add_theme_color_override("font_color", evidence_dialogue.speaker)
		ui.text_label.add_theme_color_override("default_color", evidence_dialogue.text)
		ui.hint_label.add_theme_color_override("font_color", evidence_dialogue.hint)
		ui.dialogue_portrait.disclosure.add_theme_color_override("font_color", evidence_dialogue.disclosure)
		ui.dialogue_portrait.image.self_modulate = Color.WHITE
		return
	ui.dialogue_portrait.disclosure.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ui.dialogue_portrait.image.self_modulate = portrait_tint
	ui.dialog_panel.add_theme_stylebox_override("panel", panel_slips[ui.dialog_panel])
	ui.dialogue_portrait.add_theme_stylebox_override("panel", panel_slips[ui.dialogue_portrait])
	ui.speaker_label.add_theme_color_override("font_color", foreground)
	ui.text_label.add_theme_color_override("default_color", foreground)
	ui.hint_label.add_theme_color_override("font_color", foreground)
	ui.dialogue_portrait.disclosure.add_theme_color_override("font_color", foreground)
	for button in ui._choice_buttons:
		if not button.focus_entered.is_connected(_choices):
			button.focus_entered.connect(_choices)
			button.focus_exited.connect(_choices)
		var focused: bool = button.has_focus()
		button.add_theme_stylebox_override("normal", selected_button if focused else buttons)
		button.add_theme_stylebox_override("hover", selected_button if focused else hovered_button)
		button.add_theme_stylebox_override("pressed", selected_button)
		button.add_theme_stylebox_override("hover_pressed", selected_button)
		button.add_theme_stylebox_override("focus", choice_focus)
		for state in ["font_color", "font_hover_color", "font_focus_color"]:
			button.add_theme_color_override(state, buttons.bg_color if focused else foreground)
		for state in ["font_pressed_color", "font_hover_pressed_color"]:
			button.add_theme_color_override(state, buttons.bg_color)


func _central_visibility() -> void:
	ui.prompt_label.visible = not ui.tot_panel.visible and not ui.prompt_label.text.is_empty()
	ui.crosshair.visible = not ui.tot_panel.visible
	if ui.tot_panel.visible:
		ui.hold_bar.hide()
	_toast_layout()


func _layout() -> void:
	# Size the labels around their text, preserving the centred prompt and clock
	# whenever there is room alongside the task panel.
	for label in [ui.clock_label, ui.prompt_label]:
		label.size.x = label.get_minimum_size().x
		label.position.x = (ui.hud.size.x - label.size.x) * 0.5
	var task: Control = ui.objectives.get_parent()
	if task.visible:
		var left: float = task.position.x + task.size.x + 32.0
		ui.clock_label.position.x = maxf(ui.clock_label.position.x, left)
		if ui.clock_label.position.x + ui.clock_label.size.x + 16.0 > ui.hud.size.x:
			ui.clock_label.position.x = (ui.hud.size.x - ui.clock_label.size.x) * 0.5
			ui.clock_label.position.y = task.position.y + task.size.y + 32.0
		else:
			ui.clock_label.position.y = 18.0
	else:
		ui.clock_label.position.y = 18.0
	var font: Font = ui.toast.get_theme_font("font")
	var font_size: int = ui.toast.get_theme_font_size("font_size")
	var width := 0.0
	for line in ui.toast.text.split("\n"):
		width = maxf(width, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x)
	var paper: StyleBoxFlat
	var right: float = ui.hud.size.x
	if ui.tot_panel.visible:
		paper = ui.toast.get_theme_stylebox("normal")
		var gap: float = 16.0 * ui.hud.size.y / 900.0
		right = ui.tot_panel.position.x - gap
		width = minf(width, right - paper.expand_margin_left - paper.expand_margin_right)
	ui.toast.size.x = minf(width, 960.0)
	# Refit the wrapped height after changing the width.
	ui.toast.size.y = 0.0
	ui.toast.position.x = (ui.hud.size.x - ui.toast.size.x) * 0.5
	if ui.tot_panel.visible:
		ui.toast.position.x = minf(ui.toast.position.x, right - paper.expand_margin_right - ui.toast.size.x)
	_toast_layout()


func _toast_layout() -> void:
	ui.toast.size.y = ceilf(ui.toast.get_minimum_size().y)
	ui.toast.position.y = ui.hud.size.y - 150.0
	if ui.tot_panel.visible:
		# Main's 90 px toast ends 60 px above the bottom; extra lines grow up.
		ui.toast.position.y = ui.hud.size.y - 60.0 - ui.toast.size.y
