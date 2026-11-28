extends RefCounted
## In-play print furniture and the overlays that open over it.

const Fonts := preload("res://scripts/fonts.gd")
const NIGHT_PAPER := Color("4d1714")
const NIGHT_INK := Color("ffdbc9")
const TOTALITY_INK := Color("fffbf2")

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
var serif: Font
var serif_emphasis := {}
var small_caps: FontVariation


func setup(target: Node, colours: Dictionary) -> void:
	ui = target
	palette = colours
	ui.paper_hud = true
	var face := Fonts.paper_serif(ui.font)
	serif = face
	for variant in ["bold_font", "italics_font", "bold_italics_font"]:
		var emphasis: SystemFont = face.duplicate()
		emphasis.font_weight = 700 if "bold" in variant else 400
		emphasis.font_italic = "italics" in variant
		serif_emphasis[variant] = emphasis
	small_caps = FontVariation.new()
	small_caps.base_font = serif
	small_caps.opentype_features = {"smcp": 1}
	for label in [ui.clock_label, ui.prompt_label, ui.toast, ui.caption, ui.tot_hint, ui.callout]:
		label.add_theme_font_override("font", serif)
	for label in [ui.objectives, ui.tot_label]:
		label.add_theme_font_override("normal_font", serif)
		for variant in serif_emphasis:
			label.add_theme_font_override(variant, serif_emphasis[variant])
		label.autowrap_mode = TextServer.AUTOWRAP_WORD
	ui.toast.autowrap_mode = TextServer.AUTOWRAP_WORD
	ui.objectives.get_parent().custom_minimum_size = Vector2.ZERO
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
		label.draw.connect(_inner_rule.bind(label, "normal"))
	for panel in [ui.objectives.get_parent(), ui.tot_panel, ui.dialog_panel, ui.dialogue_portrait]:
		var slip: StyleBoxFlat = panel.get_theme_stylebox("panel").duplicate()
		slip.set_corner_radius_all(0)
		slip.set_border_width_all(1)
		panel.add_theme_stylebox_override("panel", slip)
		slips.append(slip)
		panel_slips[panel] = slip
		if panel != ui.dialogue_portrait:
			panel.draw.connect(_inner_rule.bind(panel, "panel"))
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
	ui.paper_toast_layout = _fit_toast
	ui.hud.resized.connect(_layout)
	ui.objectives.get_parent().resized.connect(_layout)
	ui.toast.resized.connect(_toast_layout)
	ui.toast.minimum_size_changed.connect(_toast_layout)
	ui.tot_panel.resized.connect(_toast_layout)
	for modal in [ui.dialog_panel, ui.title_panel, ui.pause_panel, ui.help_panel, ui.log_panel, ui.credits_panel, ui.ending_panel]:
		modal.visibility_changed.connect(_visibility)
	ui.clock_label.minimum_size_changed.connect(_layout.call_deferred)
	ui.objectives.minimum_size_changed.connect(_layout.call_deferred)
	ui.dialogue_entry.connect(func(_speaker: String): ui._layout_dialogue_portrait.call_deferred())
	_visibility()
	_layout.call_deferred()


func light(darkness: float, night: float, params: Dictionary) -> void:
	if evidence_dialogue.is_empty():
		evidence_dialogue = {
			"panel": ui.dialog_panel.get_theme_stylebox("panel"),
			"mount": ui.dialogue_portrait.get_theme_stylebox("panel"),
			"speaker": ui.speaker_label.get_theme_color("font_color"),
			"text": ui.text_label.get_theme_color("default_color"),
			"hint": ui.hint_label.get_theme_color("font_color"),
			"disclosure": ui.dialogue_portrait.disclosure.get_theme_color("font_color"),
			"hint_outline": ui.hint_label.get_theme_constant("outline_size"),
			"disclosure_outline": ui.dialogue_portrait.disclosure.get_theme_constant("outline_size"),
		}
	var background: Color = palette.paper
	foreground = palette.ink_col
	portrait_tint = Color.WHITE
	if night * float(params.night_wash) > 0.5:
		background = NIGHT_PAPER
		foreground = NIGHT_INK
		portrait_tint = palette.safe_light
	else:
		var blue: Color = palette.tot_paper
		var wash := clampf(darkness * float(params.tot_wash), 0.0, 1.0)
		# Turn the HUD page before the return dialogue. The scene and portrait
		# can keep fading while every letter uses the ink for a solid stock.
		if wash > 0.75:
			background = blue
			foreground = TOTALITY_INK
		portrait_tint = Color.WHITE.lerp(blue.lerp(Color.WHITE, 0.4), wash)
	ui.set_overlay_paper(background, foreground)
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
	for label in [ui.clock_label, ui.prompt_label, ui.toast, ui.caption, ui.tot_hint, ui.callout]:
		label.add_theme_color_override("font_color", foreground)
		label.add_theme_constant_override("outline_size", 0)
	ui.crosshair.add_theme_color_override("font_color", foreground)
	ui.crosshair.add_theme_color_override("font_outline_color", background)
	ui.crosshair.add_theme_constant_override("outline_size", 3)
	for label in [ui.objectives, ui.tot_label]:
		label.add_theme_color_override("default_color", foreground)
		label.add_theme_color_override("font_outline_color", foreground)
		label.add_theme_constant_override("outline_size", 1)
	_choices()
	_central_visibility()


func _choices() -> void:
	# Row 7's report conversation is part of the evidence viewer, whose pixels
	# are deliberately outside this pass, including its shared dialogue controls.
	if ui.viewer.visible:
		ui.dialog_panel.add_theme_stylebox_override("panel", evidence_dialogue.panel)
		ui.dialogue_portrait.add_theme_stylebox_override("panel", evidence_dialogue.mount)
		ui.speaker_label.add_theme_color_override("font_color", evidence_dialogue.speaker)
		ui.text_label.add_theme_color_override("default_color", evidence_dialogue.text)
		ui.hint_label.add_theme_color_override("font_color", evidence_dialogue.hint)
		ui.dialogue_portrait.disclosure.add_theme_color_override("font_color", evidence_dialogue.disclosure)
		ui.hint_label.add_theme_constant_override("outline_size", evidence_dialogue.hint_outline)
		ui.dialogue_portrait.disclosure.add_theme_constant_override("outline_size", evidence_dialogue.disclosure_outline)
		ui.dialogue_portrait.image.self_modulate = Color.WHITE
		for label in [ui.speaker_label, ui.hint_label, ui.dialogue_portrait.disclosure]:
			label.remove_theme_font_override("font")
		ui.text_label.remove_theme_font_override("normal_font")
		for variant in serif_emphasis:
			ui.text_label.remove_theme_font_override(variant)
		return
	for label in [ui.speaker_label, ui.hint_label]:
		label.add_theme_font_override("font", small_caps)
	ui.dialogue_portrait.disclosure.add_theme_font_override("font", serif)
	ui.text_label.add_theme_font_override("normal_font", serif)
	for variant in serif_emphasis:
		ui.text_label.add_theme_font_override(variant, serif_emphasis[variant])
	ui.dialogue_portrait.image.self_modulate = portrait_tint
	ui.dialog_panel.add_theme_stylebox_override("panel", panel_slips[ui.dialog_panel])
	ui.dialogue_portrait.add_theme_stylebox_override("panel", panel_slips[ui.dialogue_portrait])
	ui.speaker_label.add_theme_color_override("font_color", foreground)
	ui.text_label.add_theme_color_override("default_color", foreground)
	for label in [ui.hint_label, ui.dialogue_portrait.disclosure]:
		label.add_theme_color_override("font_color", foreground)
		label.add_theme_color_override("font_outline_color", foreground)
		label.add_theme_constant_override("outline_size", 1)
	for button in ui._choice_buttons:
		if not button.focus_entered.is_connected(_choices):
			button.focus_entered.connect(_choices)
			button.focus_exited.connect(_choices)
		var focused: bool = button.has_focus()
		button.add_theme_font_override("font", serif)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD
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
	ui.prompt_label.visible = not ui.tot_panel.visible and not ui.prompt_label.text.is_empty() and not ui.blocks_world_input()
	ui.crosshair.visible = not ui.tot_panel.visible
	if ui.tot_panel.visible:
		ui.hold_bar.hide()
	_toast_layout()


func _visibility() -> void:
	var blocked: bool = ui.blocks_world_input() or ui.title_panel.visible or ui.ending_panel.visible
	ui.objectives.get_parent().visible = not blocked and not ui.objectives.text.is_empty()
	ui.toast.visible = not blocked and not ui.toast.text.is_empty()
	ui.clock_label.visible = not blocked and not ui.clock_label.text.is_empty()
	_central_visibility()


func _inner_rule(control: Control, style_name: String) -> void:
	if ui.viewer.visible and control == ui.dialog_panel:
		return
	var style: StyleBoxFlat = control.get_theme_stylebox(style_name)
	var rect := Rect2(Vector2.ZERO, control.size).grow_individual(style.expand_margin_left,
		style.expand_margin_top, style.expand_margin_right, style.expand_margin_bottom)
	control.draw_rect(rect.grow(-4.0), style.border_color, false, 1.0)


func _layout() -> void:
	_visibility()
	var task: Control = ui.objectives.get_parent()
	var face: Font = ui.objectives.get_theme_font("normal_font")
	var px: int = ui.objectives.get_theme_font_size("normal_font_size")
	var task_width: float = face.get_string_size(ui.objectives.get_parsed_text(), HORIZONTAL_ALIGNMENT_LEFT, -1, px).x
	ui.objectives.custom_minimum_size.x = minf(task_width, ui.hud.size.x * 0.32)
	task.size = task.get_combined_minimum_size()
	# Size the labels around their text, preserving the centred prompt and clock
	# whenever there is room alongside the task panel.
	for label in [ui.clock_label, ui.prompt_label]:
		label.size = label.get_minimum_size()
		label.position.x = (ui.hud.size.x - label.size.x) * 0.5
	ui.hold_bar.position.y = ui.prompt_label.position.y + ui.prompt_label.size.y + 20.0
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
	_fit_toast()


func _fit_toast() -> void:
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
	# Every toast grows upward from the same bottom margin, including rehearsal.
	ui.toast.position.y = ui.hud.size.y - 60.0 - ui.toast.size.y
