extends CanvasLayer

const Prompts := preload("res://scripts/prompts.gd")
const Fonts := preload("res://scripts/fonts.gd")
const Credits := preload("res://scripts/credits.gd")
const ScorePlayer := preload("res://scripts/audio/score_player.gd")
const Settings := preload("res://scripts/settings.gd")
const Content := preload("res://scripts/content.gd")
const Strip := preload("res://scripts/totality_strip.gd")
const DialoguePortrait := preload("res://scripts/cambridge/dialogue_portrait.gd")
const FadeStars := preload("res://scripts/fade_stars.gd")
const PlateRender := preload("res://scripts/plate_render.gd")
var music_ready_usec := 0
## All 2D presentation: HUD, dialogue, plate viewer, chart, title/ending, pause.

signal dialogue_done(results: Dictionary)
signal dialogue_entry(speaker: String)
signal prologue_pressed
signal log_toggled(open: bool)
signal pause_toggled(paused: bool)
signal start_pressed
signal restart_pressed(same_sky: bool)
signal quit_pressed
## The pause menu is closed; the chapter resets Story and returns to the title.
signal title_pressed
signal plate_toggled(index: int, on: bool)
## The player recorded a micrometer reading (reference star 0, plate pixels).
signal reading_set(index: int, px: float)
signal measure_pressed
signal reselect_pressed
signal report_pressed
signal viewer_closed
## The keyboard/pad prompt names changed (see Prompts.joypad).
signal prompts_changed

const PAPER := Color(0.93, 0.89, 0.80)
const INK := Color(0.10, 0.09, 0.08)
const DIM := Color(0.70, 0.66, 0.58)
const ACCENT := Color(0.95, 0.72, 0.38)

var font: Font
var theme_res: Theme
var hud: Control
var clock_label: Label
var objectives: RichTextLabel
var crosshair: Label
var prompt_label: Label
var hold_bar: ProgressBar
var toast: Label
var _toast_t := 0.0
var tot_panel: PanelContainer
var tot_label: RichTextLabel
var tot_strip: Control
var tot_hint: Label
var callout: Label
var _callout_t := 0.0
var dialog_panel: PanelContainer
var speaker_label: Label
var text_label: RichTextLabel
var choice_box: VBoxContainer
var hint_label: Label
var dialogue_portrait: DialoguePortrait
var cambridge_portraits := false
var fade: ColorRect
var caption: Label
var title_panel: Control
var title_controls: Label
var prologue_btn: Button
var start_btn: Button
var title_note: Label
var log_panel: PanelContainer
var log_text: RichTextLabel
var log_scroll: ScrollContainer
var log_title: Label
var log_back: Button
static var history: Array[String] = []
var _log_mouse_mode := Input.MOUSE_MODE_VISIBLE
var ending_replay: Button
var ending_replay_hint: Label
var ending_scroll: ScrollContainer
var ending_center: CenterContainer
var credits_scroll: ScrollContainer
var _menu_scroll_remainder := 0.0
var ending_panel: Control
var credits_panel: Control
var ending_text: RichTextLabel
var ending_objects: BoxContainer
var ending_slip: PanelContainer
var ending_telegram: RichTextLabel
var ending_plate_content: BoxContainer
var ending_plate_card: PanelContainer
var ending_plate: TextureRect
var ending_plate_caption: Label
var ending_title: Label
var ending_review: RichTextLabel
var ending_review_toggle: Button
var ending_history: RichTextLabel
var ending_history_toggle: Button
var pause_panel: Control
var help_panel: Control
var help_content: RichTextLabel
var _help_focus: Control
var _pause_title_btn: Button
var _settings_button: Button
var _pause_heading: Label
var _resume_button: Button
var _settings_only := false
var _title_focus_modes: Array[int] = []
var fullscreen_button: Button
var text_size_button: Button
var quality_button: Button
var hold_button: Button
var restart_button: Button
var quit_button: Button
var music_button: Button
var music_row: HBoxContainer
var music_slider: HSlider
var _restart_armed := false
var _quit_armed := false
var _title_armed := false
var viewer: Control
var thumbs: GridContainer
var big_plate: TextureRect
var plate_stage: Control
var viewer_mid: VBoxContainer
var plate_info: RichTextLabel
var reference_btn: Button
var reference_close_btn: Button
var reference_panel: PanelContainer
var loupe_btn: Button
var blink_btn: Button
var blink_label: Label
var mic_btn: Button
var mic_row: HBoxContainer
var mic_record_btn: Button
var mic_readout: Label
var mic_note: Label
var mic_overlay: Control
var micrometer_on := false
## Current crosshair setting for the selected plate, in plate pixels, radial.
var micrometer_px := 0.0
var _mic_had_loupe := false
var _mic_dragging := false
var _mic_hold := 0.0
var _mic_repeat := 0.0
## Set by main before open_viewer: returns {value, sigma} for a read plate.
var measurement_of := Callable()
var _comparison_texture: Texture2D
var _blink_elapsed := 0.0
var _blink_oxford := false
var _blink_had_loupe := false
var _blink_hint_shown := false
var _plate_texture: Texture2D
var _loupe_center := Vector2.ZERO
var loupe_start := Vector2(-1, -1)
var include_box: CheckBox
var measure_btn: Button
var reselect_btn: Button
var report_btn: Button
var chart: Control
var viewer_rule: RichTextLabel
var viewer_note: RichTextLabel
var viewer_sfx_log: Array[String] = []
var _viewer_sfx := {}

var _seq: Array = []
var _seq_i := 0
var _results := {}
var _choice_buttons: Array[Button] = []
var _viewer_sel := -1
var _viewer_plates: Array = []
## Set by main before open_viewer: the 1917 plan line for the comparison plate.
var comparison_recall := ""
## Set by main before open_viewer: the drive line under each eclipse plate.
var drive_note := ""
var _viewer_locked := false
var _viewer_reporting := false
var pause_enabled := false
var _pause_focus: Control
var _credits_focus: Control
var _log_focus: Control


func _ready() -> void:
	layer = 10
	var music_ready := Time.get_ticks_usec()
	ScorePlayer.load_settings()
	Settings.load_settings()
	Settings.apply_startup()
	music_ready_usec = Time.get_ticks_usec() - music_ready
	font = Fonts.cjk()
	theme_res = Theme.new()
	theme_res.default_font = font
	theme_res.default_font_size = Settings.fs(21)
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_res
	add_child(root)
	_build_hud(root)
	_build_viewer(root)
	_build_dialog(root)
	_build_title(root)
	_build_ending(root)
	_build_pause(root)
	_build_help(root)
	_build_log(root)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	var stars := FadeStars.new()
	stars.target = fade
	fade.add_child(stars)
	caption = Label.new()
	caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Settings.track_font(caption, 34)
	caption.add_theme_color_override("font_color", PAPER)
	caption.modulate.a = 0.0
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(caption)


func _panel_style(bg: Color, border := Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(16)
	if border.a > 0.0:
		sb.set_border_width_all(2)
		sb.border_color = border
	return sb


func _text_size_caption() -> String:
	return "文字大小：" + ["小", "標準", "大"][Settings.TEXT_SCALES.find(Settings.text_scale)]


func _cycle_text_size() -> void:
	Settings.cycle_text_scale()
	theme_res.default_font_size = Settings.fs(21)
	Settings.refresh_fonts(get_tree())
	chart.refresh_fonts()
	text_size_button.text = _text_size_caption()


func _quality_caption() -> String:
	return "畫質：低" if Settings.quality == "low" else "畫質：標準"


func _cycle_quality() -> void:
	Settings.cycle_quality()
	Settings.apply_quality(get_tree())
	quality_button.text = _quality_caption()


func _label(text: String, size := 21, color := PAPER) -> Label:
	var l := Label.new()
	l.text = text
	Settings.track_font(l, size)
	l.add_theme_color_override("font_color", color)
	return l


func _rich(size := 20) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	Settings.track_font(r, size)
	r.add_theme_color_override("default_color", PAPER)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	Settings.track_font(b, 20)
	b.focus_mode = Control.FOCUS_ALL
	var normal := _panel_style(Color(0.18, 0.15, 0.12, 0.95), Color(0.55, 0.45, 0.3))
	normal.set_content_margin_all(10)
	var hover := _panel_style(Color(0.32, 0.25, 0.16, 0.98), ACCENT)
	hover.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("focus", hover)
	b.add_theme_stylebox_override("pressed", hover)
	b.add_theme_stylebox_override("disabled", normal)
	b.add_theme_color_override("font_color", PAPER)
	b.add_theme_color_override("font_hover_color", Color(1, 0.95, 0.85))
	b.add_theme_color_override("font_disabled_color", Color(0.5, 0.47, 0.42))
	return b


# --------------------------------------------------------------------------- HUD

func _build_hud(root: Control) -> void:
	hud = Control.new()
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(hud)
	clock_label = _label("", 24)
	clock_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	clock_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	clock_label.position = Vector2(-300, 14)
	clock_label.size = Vector2(600, 40)
	clock_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	clock_label.add_theme_constant_override("outline_size", 3)
	hud.add_child(clock_label)
	var obj_panel := PanelContainer.new()
	obj_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.06, 0.05, 0.04, 0.62)))
	obj_panel.position = Vector2(18, 18)
	obj_panel.custom_minimum_size = Vector2(470, 0)
	hud.add_child(obj_panel)
	objectives = _rich(18)
	obj_panel.add_child(objectives)
	crosshair = _label("+", 26, Color(1, 1, 1, 0.75))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-8, -18)
	hud.add_child(crosshair)
	prompt_label = _label("", 22, Color(1, 0.95, 0.82))
	prompt_label.set_anchors_preset(Control.PRESET_CENTER)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.position = Vector2(-400, 26)
	prompt_label.size = Vector2(800, 36)
	prompt_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	prompt_label.add_theme_constant_override("outline_size", 6)
	hud.add_child(prompt_label)
	hold_bar = ProgressBar.new()
	hold_bar.set_anchors_preset(Control.PRESET_CENTER)
	hold_bar.position = Vector2(-120, 66)
	hold_bar.size = Vector2(240, 14)
	hold_bar.show_percentage = false
	hold_bar.max_value = 1.0
	hold_bar.visible = false
	hud.add_child(hold_bar)
	toast = _label("", 21, PAPER)
	toast.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.position = Vector2(-480, -150)
	toast.size = Vector2(960, 90)
	toast.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	toast.add_theme_constant_override("outline_size", 7)
	hud.add_child(toast)
	tot_panel = PanelContainer.new()
	tot_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.05, 0.07, 0.72), Color(0.4, 0.4, 0.5, 0.6)))
	tot_panel.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	tot_panel.position = Vector2(-446, -250)
	tot_panel.custom_minimum_size = Vector2(426, 0)
	tot_panel.visible = false
	hud.add_child(tot_panel)
	var tot_box := VBoxContainer.new()
	tot_box.add_theme_constant_override("separation", 5)
	tot_panel.add_child(tot_box)
	tot_label = _rich(19)
	tot_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tot_box.add_child(tot_label)
	tot_strip = Strip.new()
	tot_strip.custom_minimum_size = Vector2(394, 32)
	tot_box.add_child(tot_strip)
	tot_hint = _label("［空白鍵／E／左鍵］開始・停", 16, DIM)
	tot_box.add_child(tot_hint)
	# In the panel's VBox so the (variable-height) header can never overlap it.
	callout = _label("", 19, PAPER)
	callout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	callout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	callout.modulate.a = 0.0
	callout.visible = false
	callout.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	callout.add_theme_constant_override("outline_size", 6)
	tot_box.add_child(callout)


func set_objectives(bb: String) -> void:
	objectives.text = bb
	objectives.get_parent().visible = bb != ""


func set_prompt(text: String) -> void:
	prompt_label.text = text


func set_hold(progress: float) -> void:
	hold_bar.visible = progress > 0.0
	hold_bar.value = progress


func show_toast(text: String, seconds := 4.0) -> void:
	toast.text = text
	toast.modulate.a = 1.0
	_toast_t = seconds
	_append_history("・" + text)


## Toasts vanish on a timer; the log is where a slow reader reads them again.
func _append_history(line: String) -> void:
	if not history.is_empty() and history.back() == line:
		return
	history.append(line)
	while history.size() > 120:
		history.pop_front()


func _process(delta: float) -> void:
	if viewer.visible and blink_btn.button_pressed and not get_tree().paused and not log_panel.visible:
		_blink_elapsed += delta
		var blink_interval := 1.0 if Settings.reduced_motion else 0.5
		while _blink_elapsed >= blink_interval:
			_blink_elapsed -= blink_interval
			_blink_oxford = not _blink_oxford
			_update_blink()
	if viewer.visible and micrometer_on and not _viewer_locked and not _viewer_reporting and not get_tree().paused and not log_panel.visible:
		var held: float = 0.0
		if Input.is_action_pressed("ui_right"):
			held = 1.0
		elif Input.is_action_pressed("ui_left"):
			held = -1.0
		if held != 0.0:
			_mic_hold += delta
			if _mic_hold >= 0.35:
				_mic_repeat += delta
				while _mic_repeat >= 0.08:
					_mic_repeat -= 0.08
					_nudge_micrometer(held, _mic_fine())
		else:
			_mic_hold = 0.0
			_mic_repeat = 0.0
	if viewer.visible and loupe_btn.button_pressed and (loupe_btn.has_focus() or blink_btn.has_focus()) and not get_tree().paused and not log_panel.visible:
		var pan := Input.get_vector("gamepad_look_left", "gamepad_look_right", "gamepad_look_up", "gamepad_look_down")
		if pan != Vector2.ZERO:
			_show_loupe(_loupe_center + pan * 120.0 * delta)
	var scroll := _active_menu_scroll()
	if scroll:
		_menu_scroll_remainder += Input.get_axis("gamepad_look_up", "gamepad_look_down") * 900.0 * delta
		var pixels := int(_menu_scroll_remainder)
		_menu_scroll_remainder -= pixels
		scroll.scroll_vertical += pixels
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t < 0.6:
			toast.modulate.a = maxf(_toast_t / 0.6, 0.0)
	if _callout_t > 0.0:
		_callout_t -= delta
		if _callout_t <= 0.0:
			_callout_t = 0.0
			callout.text = ""
			callout.visible = false
			callout.modulate.a = 0.0
		elif _callout_t < 0.6:
			callout.modulate.a = maxf(_callout_t / 0.6, 0.0)


func fade_to(alpha: float, seconds := 0.8) -> Tween:
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tw.tween_property(fade, "color:a", alpha, seconds)
	return tw


func show_caption(text: String, seconds := 3.0) -> Tween:
	caption.text = text
	var tw := create_tween()
	tw.set_pause_mode(Tween.TWEEN_PAUSE_STOP)
	tw.tween_property(caption, "modulate:a", 1.0, 0.6)
	tw.tween_interval(seconds)
	tw.tween_property(caption, "modulate:a", 0.0, 0.6)
	return tw


# ---------------------------------------------------------------------- Dialogue

func _build_dialog(root: Control) -> void:
	dialog_panel = PanelContainer.new()
	# Keep long authored choices on screen as the panel grows from its bottom edge.
	dialog_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	dialog_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.06, 0.05, 0.9), Color(0.5, 0.4, 0.26)))
	dialog_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	# Low-third placement for every chapter (as Cambridge always used), so the speaker's
	# face stays visible above the panel; it still grows upward for long choices.
	dialog_panel.offset_left = -560
	dialog_panel.offset_right = 560
	dialog_panel.offset_top = -214
	dialog_panel.offset_bottom = -18
	dialog_panel.custom_minimum_size = Vector2(1120, 200)
	dialog_panel.visible = false
	root.add_child(dialog_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	dialog_panel.add_child(v)
	speaker_label = _label("", 22, ACCENT)
	v.add_child(speaker_label)
	text_label = _rich(21)
	text_label.custom_minimum_size = Vector2(1080, 0)
	v.add_child(text_label)
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 6)
	v.add_child(choice_box)
	hint_label = _label("［E／空白鍵／點擊］繼續", 16, DIM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(hint_label)
	dialogue_portrait = DialoguePortrait.new()
	root.add_child(dialogue_portrait)
	dialogue_portrait.setup(DIM)
	dialog_panel.visibility_changed.connect(func():
		if not dialog_panel.visible:
			dialogue_portrait.hide())
	root.resized.connect(_layout_dialogue_portrait)
	dialog_panel.resized.connect(_layout_dialogue_portrait)


func _layout_dialogue_portrait() -> void:
	if not cambridge_portraits:
		return
	# Reserve a separate bottom-left print column. Text/choices keep their own
	# panel; the print cannot cover the central evidence or an interaction prompt.
	var width: float = dialog_panel.get_parent().size.x
	var span := minf(width - 48.0, 1360.0)
	dialog_panel.offset_left = -span * 0.5 + 240.0
	dialog_panel.offset_right = span * 0.5
	dialog_panel.custom_minimum_size.x = 0.0
	text_label.custom_minimum_size.x = 0.0
	text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_portrait.size = Vector2(224, 256)
	dialogue_portrait.position = Vector2((width - span) * 0.5, dialog_panel.get_global_rect().end.y - dialogue_portrait.size.y)


func dialog_active() -> bool:
	return dialog_panel.visible


## Plays a sequence of {s: speaker, t: text, choices?: [..], key?: String}.
## Emits dialogue_done(results) where results[key] = chosen index.
func play(seq: Array) -> void:
	if seq.is_empty():
		dialogue_done.emit({})
		return
	_seq = seq.duplicate(true)
	_seq_i = 0
	_results = {}
	_toast_t = 0.0
	toast.modulate.a = 0.0
	dialog_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_show_entry()


func _show_entry() -> void:
	var e: Dictionary = _seq[_seq_i]
	history.append("%s：%s" % [e.get("s", ""), e.get("t", "")])
	if history.size() > 60:
		history.pop_front()
	speaker_label.text = e.get("s", "")
	text_label.text = e.get("t", "")
	if cambridge_portraits:
		_layout_dialogue_portrait()
		dialogue_portrait.show_entry(e)
	for b in _choice_buttons:
		b.release_focus()
		b.hide()
		b.queue_free()
	_choice_buttons.clear()
	var choices: Array = e.get("choices", [])
	hint_label.text = "［1–%d 或點擊］選擇" % choices.size() if choices.size() > 0 else "［E／空白鍵／點擊］繼續"
	for i in choices.size():
		var b := _button("%d.  %s" % [i + 1, choices[i]])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.pressed.connect(_choose.bind(i))
		choice_box.add_child(b)
		_choice_buttons.append(b)
	if not _choice_buttons.is_empty():
		_choice_buttons[0].grab_focus()
	_refresh_hints()
	dialogue_entry.emit(str(e.get("s", "")))


func _choose(i: int) -> void:
	var e: Dictionary = _seq[_seq_i]
	history.append("你：" + str(e.choices[i]))
	if history.size() > 60:
		history.pop_front()
	_results[e.get("key", str(_seq_i))] = i
	if e.has("then"):
		# Branch: insert the follow-up lines for this choice.
		var follow: Array = e.then[i]
		for k in follow.size():
			_seq.insert(_seq_i + 1 + k, follow[k])
	_advance()


func _advance() -> void:
	_seq_i += 1
	if _seq_i >= _seq.size():
		dialog_panel.visible = false
		for b in _choice_buttons:
			b.release_focus()
			b.hide()
			b.queue_free()
		_choice_buttons.clear()
		dialogue_done.emit(_results)
		return
	_show_entry()


func _unhandled_input(event: InputEvent) -> void:
	if pause_enabled and event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func _dialogue_input(event: InputEvent) -> void:
	if get_tree().paused or log_panel.visible or not dialog_panel.visible:
		return
	var e: Dictionary = _seq[_seq_i]
	var has_choices := e.has("choices")
	if has_choices and event is InputEventKey and event.pressed and not event.echo:
		var n: int = event.keycode - KEY_1
		if n >= 0 and n < e.choices.size():
			get_viewport().set_input_as_handled()
			_choose(n)
			return
	if has_choices:
		var selected := _choice_buttons.find(get_viewport().gui_get_focus_owner())
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			var step := 1 if event.is_action_pressed("ui_down") else -1
			_choice_buttons[posmod(maxi(selected, 0) + step, _choice_buttons.size())].grab_focus()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_accept"):
			get_viewport().set_input_as_handled()
			_choose(maxi(selected, 0))
	else:
		var adv := event.is_action_pressed("interact") or event.is_action_pressed("shutter") or event.is_action_pressed("ui_accept")
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			adv = true
		if adv:
			get_viewport().set_input_as_handled()
			_advance()


# ----------------------------------------------------------------------- Totality

func set_totality(visible_: bool, bb := "", strip_model := {}) -> void:
	tot_panel.visible = visible_
	tot_label.text = bb
	tot_strip.visible = visible_ and not strip_model.is_empty()
	if not strip_model.is_empty():
		tot_strip.set_model(strip_model)
	if not visible_:
		callout.text = ""
		callout.modulate.a = 0.0
		callout.visible = false
		_callout_t = 0.0


## One-shot line under the totality panel; replaces any older callout.
func set_callout(text: String, seconds := 3.5) -> void:
	callout.text = text
	callout.visible = text != ""
	callout.modulate.a = 1.0 if text != "" else 0.0
	_callout_t = seconds if text != "" else 0.0
	if text != "":
		_append_history("・" + text)


func set_clock(text: String) -> void:
	clock_label.text = text


# ------------------------------------------------------------------ Plate viewer

func _build_viewer(root: Control) -> void:
	viewer = PanelContainer.new()
	viewer.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.045, 0.04, 1.0)))
	viewer.set_anchors_preset(Control.PRESET_FULL_RECT)
	viewer.visible = false
	root.add_child(viewer)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 18)
	viewer.add_child(h)
	# Left: thumbnails.
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(458, 0)
	h.add_child(left)
	left.add_child(_label("已沖洗的底片", 24, ACCENT))
	left.add_child(_label("點選檢視；勾選要量測的底片。\n先依星像品質決定，再按「量測」。", 16, DIM))
	reference_btn = _button("參考底片")
	reference_btn.toggle_mode = true
	left.add_child(reference_btn)
	reference_panel = PanelContainer.new()
	reference_panel.visible = false
	reference_btn.toggled.connect(func(on):
		if on and reference_panel.get_child_count() == 0:
			_build_reference_plates()
		reference_panel.visible = on
		(reference_close_btn if on else reference_btn).grab_focus()
	)
	thumbs = GridContainer.new()
	thumbs.columns = 4
	thumbs.add_theme_constant_override("h_separation", 6)
	thumbs.add_theme_constant_override("v_separation", 6)
	left.add_child(thumbs)
	viewer_note = _rich(15)
	left.add_child(viewer_note)
	# Middle: big plate + info.
	var mid := VBoxContainer.new()
	viewer_mid = mid
	mid.custom_minimum_size = Vector2(470, 0)
	h.add_child(mid)
	plate_stage = Control.new()
	plate_stage.custom_minimum_size = Vector2(470, 460)
	mid.add_child(plate_stage)
	big_plate = TextureRect.new()
	big_plate.custom_minimum_size = Vector2(460, 460)
	big_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	plate_stage.add_child(big_plate)
	big_plate.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	big_plate.gui_input.connect(_plate_gui_input)
	mic_overlay = Control.new()
	mic_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mic_overlay.visible = false
	plate_stage.add_child(mic_overlay)
	mic_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mic_overlay.draw.connect(_draw_micrometer)
	plate_stage.add_child(reference_panel)
	reference_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reference_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.05, 0.045, 0.04, 1.0), ACCENT))
	blink_label = _label("", 15, DIM)
	blink_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	blink_label.hide()
	mid.add_child(blink_label)
	plate_info = _rich(18)
	mid.add_child(plate_info)
	include_box = CheckBox.new()
	include_box.text = "納入量測"
	Settings.track_font(include_box, 20)
	include_box.add_theme_color_override("font_color", PAPER)
	include_box.focus_mode = Control.FOCUS_ALL
	include_box.toggled.connect(func(on):
		if _viewer_sel >= 0 and not _viewer_locked:
			_viewer_sound("mark")
			plate_toggled.emit(_viewer_sel, on)
	)
	var plate_controls := HBoxContainer.new()
	mid.add_child(plate_controls)
	plate_controls.add_child(include_box)
	loupe_btn = _button("放大鏡 ×2")
	loupe_btn.toggle_mode = true
	loupe_btn.tooltip_text = "借用 Ashby 的放大鏡：點底片移動中心；聚焦此鍵時用右搖桿或方向鍵移動，再按一次收起。Q/E 或 L1/R1 切換放大鏡與閃爍比對按鍵。"
	loupe_btn.toggled.connect(_set_loupe)
	plate_controls.add_child(loupe_btn)
	blink_btn = _button("閃爍比對")
	blink_btn.toggle_mode = true
	blink_btn.tooltip_text = "每半秒比對同一區域；右搖桿或方向鍵移動。Q/E 或 L1/R1 切換放大鏡與閃爍比對按鍵。"
	blink_btn.toggled.connect(_set_blink)
	plate_controls.add_child(blink_btn)
	mic_btn = _button("測微器")
	mic_btn.toggle_mode = true
	mic_btn.tooltip_text = "顯微測微器：把十字線對到參考星在日食底片上的位置。←／→（方向鍵／D-pad）每次 0.25 格，Shift 或 L2 微調 0.05 格；滑鼠可直接拖曳十字線。對好後按「記下讀數」或 A 鍵，這張底片才算量過。1 格 = 底片上 1 像素。"
	mic_btn.toggled.connect(_set_micrometer)
	plate_controls.add_child(mic_btn)
	mic_row = HBoxContainer.new()
	mic_row.visible = false
	mid.add_child(mic_row)
	mic_record_btn = _button("記下讀數")
	mic_record_btn.pressed.connect(_record_micrometer)
	mic_row.add_child(mic_record_btn)
	mic_readout = _label("讀數：0.00 格", 16, ACCENT)
	mic_readout.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mic_row.add_child(mic_readout)
	mic_note = _label("位移為示意放大；真實的位移比一個星點還小得多。", 14, DIM)
	mic_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mic_note.visible = false
	mid.add_child(mic_note)
	# Right: chart + actions.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	h.add_child(right)
	right.add_child(_label("星光偏折（太陽邊緣，角秒）", 22, ACCENT))
	viewer_rule = _rich(15)
	viewer_rule.visible = false
	right.add_child(viewer_rule)
	chart = preload("res://scripts/chart.gd").new()
	chart.custom_minimum_size = Vector2(560, 420)
	right.add_child(chart)
	var btns := GridContainer.new()
	btns.columns = 2
	btns.add_theme_constant_override("h_separation", 10)
	btns.add_theme_constant_override("v_separation", 10)
	right.add_child(btns)
	measure_btn = _button("量測所選底片")
	measure_btn.pressed.connect(func():
		_viewer_sound("measure")
		measure_pressed.emit()
	)
	btns.add_child(measure_btn)
	reselect_btn = _button("重新選片")
	reselect_btn.pressed.connect(func():
		_viewer_sound("mark")
		reselect_pressed.emit()
	)
	btns.add_child(reselect_btn)
	report_btn = _button("向 Eddington 報告 →")
	report_btn.pressed.connect(func(): report_pressed.emit())
	btns.add_child(report_btn)
	var close := _button("離開桌子")
	close.pressed.connect(func(): viewer_closed.emit())
	btns.add_child(close)
	var model_note := _label("示意模擬資料：數值為遊戲模型，不是 1919 年的實際量測。", 15, DIM)
	model_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(model_note)
	viewer.resized.connect(_layout_viewer)
	get_viewport().size_changed.connect(_layout_viewer)
	_layout_viewer()


func _layout_viewer() -> void:
	var window_height := float(get_viewport().get_window().size.y)
	var growth := clampf((window_height - 720.0) / 360.0, 0.0, 1.0)
	var extra := minf(76.0 * growth, maxf(0.0, get_viewport().get_visible_rect().size.x - 1556.0 + 32.0 * growth))
	chart.custom_minimum_size.x = 560.0 - 32.0 * growth
	viewer_mid.custom_minimum_size.x = 470.0 + extra
	plate_stage.custom_minimum_size = Vector2(470.0 + extra, 460.0 + extra)
	big_plate.custom_minimum_size = Vector2.ONE * (460.0 + extra)
	chart.custom_minimum_size.y = 280.0 if _viewer_reporting else 420.0 + 160.0 * growth


func _build_reference_plates() -> void:
	var card := VBoxContainer.new()
	reference_panel.add_child(card)
	var examples := HBoxContainer.new()
	examples.add_theme_constant_override("separation", 4)
	card.add_child(examples)
	var captions := ["星點清楚：小而圓", "拖長：每顆星都拉成同方向的短線（時鐘走速不準）", "起霧：雲光蓋住，星點淡、數得到的少"]
	var kinds := ["sharp", "trailed", "fogged"]
	for i in kinds.size():
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 150
		examples.add_child(column)
		var image := TextureRect.new()
		image.custom_minimum_size = Vector2(150, 150)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		image.texture = preload("res://scripts/plate_render.gd").render_example(kinds[i])
		column.add_child(image)
		var caption_label := _label(captions[i], 15)
		caption_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(caption_label)
	card.add_child(_label("示意圖，不是你的底片。", 15, DIM))
	reference_close_btn = _button("收起參考")
	reference_close_btn.pressed.connect(func(): reference_btn.button_pressed = false)
	card.add_child(reference_close_btn)


func _set_loupe(on: bool) -> void:
	if not on and blink_btn.button_pressed:
		_set_blink(false)
	if on and _plate_texture != null:
		var center := _plate_texture.get_size() * 0.5
		var start_at_star := loupe_start.x >= 0.0 and loupe_start.y >= 0.0
		_show_loupe(loupe_start if start_at_star else center)
		if start_at_star:
			var zoom := big_plate.texture as AtlasTexture
			var region := zoom.region
			var plate_center := _plate_texture.get_size() * 0.5
			# Rect2 includes its top and left edges; trim that edge if clamping puts the Sun there.
			if region.position.x == plate_center.x and loupe_start.x > plate_center.x:
				region.position.x += 1.0
				region.size.x -= 1.0
			elif region.end.x == plate_center.x and loupe_start.x < plate_center.x:
				region.size.x -= 1.0
			elif region.position.y == plate_center.y and loupe_start.y > plate_center.y:
				region.position.y += 1.0
				region.size.y -= 1.0
			elif region.end.y == plate_center.y and loupe_start.y < plate_center.y:
				region.size.y -= 1.0
			zoom.region = region
	else:
		loupe_btn.set_pressed_no_signal(false)
		big_plate.texture = _plate_texture


func _show_loupe(center: Vector2) -> void:
	var half := _plate_texture.get_size() * 0.5
	_loupe_center = center.clamp(half * 0.5, _plate_texture.get_size() - half * 0.5)
	var zoom := AtlasTexture.new()
	zoom.atlas = _plate_texture
	zoom.region = Rect2(_loupe_center - half * 0.5, half)
	big_plate.texture = zoom
	if blink_btn.button_pressed:
		_update_blink()


func _set_blink(on: bool) -> void:
	blink_btn.set_pressed_no_signal(on)
	_blink_elapsed = 0.0
	_blink_oxford = false
	blink_label.visible = on
	if on:
		_blink_had_loupe = loupe_btn.button_pressed
		if not _blink_had_loupe:
			loupe_btn.set_pressed_no_signal(true)
			_set_loupe(true)
		_update_blink()
	elif loupe_btn.button_pressed:
		if _blink_had_loupe:
			big_plate.texture.atlas = _plate_texture
		else:
			_set_loupe(false)


func _update_blink() -> void:
	big_plate.texture.atlas = _comparison_texture if _blink_oxford else _plate_texture
	blink_label.text = "牛津（無日）" if _blink_oxford else "第 %d 號（全食）・位移已放大（示意）" % _viewer_plates[_viewer_sel].number


# ------------------------------------------------------- Micrometer (arc C)

## The reference star's undisplaced position, in full-plate texture pixels.
func _mic_star_point() -> Vector2:
	var center := Vector2(PlateRender.SIZE, PlateRender.SIZE) * 0.5
	if loupe_start.x >= 0.0 and loupe_start.y >= 0.0:
		return loupe_start
	return center + Vector2(PlateRender.SUN_PX, 0.0)


func _mic_dir() -> Vector2:
	var d := _mic_star_point() - Vector2(PlateRender.SIZE, PlateRender.SIZE) * 0.5
	return d.normalized() if d.length() > 0.001 else Vector2.RIGHT


## [origin, drawn, region] for the plate as shown: the same mapping the click
## handler uses, valid both zoomed (AtlasTexture) and unzoomed.
func _plate_geometry() -> Array:
	var tex := big_plate.texture
	var shown: Vector2 = tex.get_size() if tex != null else Vector2(PlateRender.SIZE, PlateRender.SIZE)
	if shown.x <= 0.0 or shown.y <= 0.0:
		shown = Vector2(PlateRender.SIZE, PlateRender.SIZE)
	var drawn := shown * minf(big_plate.size.x / shown.x, big_plate.size.y / shown.y)
	var origin := (big_plate.size - drawn) * 0.5
	var region := Rect2(Vector2.ZERO, _plate_texture.get_size())
	if tex is AtlasTexture:
		region = tex.region
	return [origin, drawn, region]


func _plate_to_local(p: Vector2) -> Vector2:
	var g := _plate_geometry()
	return g[0] + (p - g[2].position) / g[2].size * g[1]


func _local_to_plate(local: Vector2) -> Vector2:
	var g := _plate_geometry()
	return g[2].position + (local - g[0]) / g[1] * g[2].size


func _set_micrometer(on: bool) -> void:
	mic_btn.set_pressed_no_signal(on)
	var has_plate: bool = _viewer_sel >= 0 and _viewer_sel < _viewer_plates.size() and _plate_texture != null
	if on and (has_plate == false or _viewer_reporting):
		on = false
	micrometer_on = on
	if on:
		_mic_had_loupe = loupe_btn.button_pressed
		if not _mic_had_loupe:
			loupe_btn.set_pressed_no_signal(true)
			_set_loupe(true)
		_sync_micrometer()
	else:
		_mic_dragging = false
		_mic_hold = 0.0
		_mic_repeat = 0.0
		if not _mic_had_loupe and loupe_btn.button_pressed:
			_set_loupe(false)
	mic_overlay.visible = micrometer_on
	mic_row.visible = micrometer_on
	mic_note.visible = micrometer_on
	_sync_micrometer_controls()
	mic_overlay.queue_redraw()


## Take the crosshair from the selected plate's saved reading (0 if unread).
func _sync_micrometer() -> void:
	micrometer_px = 0.0
	if _viewer_sel >= 0 and _viewer_sel < _viewer_plates.size():
		var p: Dictionary = _viewer_plates[_viewer_sel]
		if p.get("read", false) and not is_nan(float(p.get("reading", 0.0))):
			micrometer_px = maxf(float(p.reading), 0.0)
	_update_micrometer()


func _sync_micrometer_controls() -> void:
	if mic_btn == null:
		return
	var has_plate: bool = _viewer_sel >= 0 and _plate_texture != null
	mic_btn.disabled = _viewer_reporting or not has_plate
	mic_record_btn.disabled = _viewer_reporting or _viewer_locked or not has_plate


func _update_micrometer() -> void:
	mic_readout.text = "讀數：%.2f 格" % micrometer_px
	mic_overlay.queue_redraw()


## The player's setting: drag, arrow, or bot, all land here.
func set_micrometer_reading(px: float) -> void:
	if not micrometer_on or _viewer_sel < 0:
		return
	var limit: float = PlateRender.SIZE
	micrometer_px = clampf(px, 0.0, limit)
	_update_micrometer()


func _mic_fine() -> bool:
	return Input.is_key_pressed(KEY_SHIFT) or Input.get_joy_axis(0, JOY_AXIS_TRIGGER_LEFT) > 0.5


func _nudge_micrometer(direction: float, fine: bool) -> void:
	if _viewer_locked or _viewer_reporting:
		return
	set_micrometer_reading(micrometer_px + direction * (0.05 if fine else 0.25))


func _record_micrometer() -> void:
	if not micrometer_on or _viewer_sel < 0 or _viewer_locked or _viewer_reporting:
		return
	_viewer_sound("mark")
	reading_set.emit(_viewer_sel, micrometer_px)


func _mic_drag_to(local: Vector2) -> void:
	var plate_point := _local_to_plate(local)
	set_micrometer_reading((plate_point - _mic_star_point()).dot(_mic_dir()))


func _draw_micrometer() -> void:
	if not micrometer_on or _viewer_sel < 0 or _plate_texture == null:
		return
	var star := _mic_star_point()
	var dir := _mic_dir()
	var night := _plate_to_local(star)
	var one_px := _plate_to_local(star + dir) - night
	if one_px.length() < 0.001:
		return
	var along := one_px.normalized()
	var across := along.orthogonal()
	mic_overlay.draw_line(_plate_to_local(star - dir * 14.0), _plate_to_local(star + dir * 70.0),
		Color(ACCENT, 0.22), 1.0)
	mic_overlay.draw_arc(night, 5.0, 0.0, TAU, 20, Color(0.74, 0.84, 0.96, 0.85), 1.0, true)
	var cross := _plate_to_local(star + dir * micrometer_px)
	mic_overlay.draw_line(cross - across * 9.0, cross + across * 9.0, ACCENT, 1.5)
	mic_overlay.draw_line(cross - along * 9.0, cross + along * 9.0, ACCENT, 1.5)
	var label_pos := night - along * 34.0 + across * 12.0
	mic_overlay.draw_string(font, label_pos, "夜裡的位置", HORIZONTAL_ALIGNMENT_LEFT, -1,
		Settings.fs(13), Color(0.74, 0.84, 0.96, 0.9))


func _plate_gui_input(event: InputEvent) -> void:
	if _viewer_reporting or _plate_texture == null:
		return
	# With the micrometer on, the plate is a dial: drag sets the crosshair.
	if micrometer_on and _viewer_sel >= 0:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_mic_dragging = not _viewer_locked
				if _mic_dragging:
					_mic_drag_to(event.position)
			else:
				_mic_dragging = false
			big_plate.accept_event()
			return
		if event is InputEventMouseMotion and _mic_dragging:
			_mic_drag_to(event.position)
			big_plate.accept_event()
			return
	if not event is InputEventMouseButton or not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return
	var g := _plate_geometry()
	var drawn: Vector2 = g[1]
	var local: Vector2 = event.position - g[0]
	if not Rect2(Vector2.ZERO, drawn).has_point(local):
		return
	var region: Rect2 = g[2]
	loupe_btn.set_pressed_no_signal(true)
	_show_loupe(region.position + local / drawn * region.size)
	big_plate.accept_event()


func open_viewer(plates: Array, comparison_tex: Texture2D, textures: Array, locked: bool) -> void:
	_set_micrometer(false)
	_set_loupe(false)
	_comparison_texture = comparison_tex
	set_viewer_report(false)
	if _viewer_sfx.is_empty():
		_build_viewer_sfx()
	viewer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_viewer_plates = plates
	for c in thumbs.get_children():
		c.queue_free()
	var comp := _thumb(comparison_tex, "牛津比對片")
	comp.pressed.connect(_select_plate.bind(-2, comparison_tex))
	thumbs.add_child(comp)
	for i in plates.size():
		var b := _thumb(textures[i], _thumb_text(i))
		b.pressed.connect(_select_plate.bind(i, textures[i]))
		thumbs.add_child(b)
	comp.grab_focus()
	set_viewer_locked(locked)
	if plates.size() > 0:
		_select_plate(0, textures[0], false)
	else:
		_select_plate(-2, comparison_tex, false)


static func _wav(samples: PackedFloat32Array, rate := 22050, loop := false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -0.8, 0.8) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
	wav.loop_end = samples.size()
	return wav


func _build_viewer_sfx() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 1919
	var rate := 22050
	for name in ["plate", "mark", "measure"]:
		var duration: float = {"plate": 0.22, "mark": 0.07, "measure": 0.9}[name]
		var samples := PackedFloat32Array()
		samples.resize(int(duration * rate))
		var previous_noise := 0.0
		for i in samples.size():
			var t := float(i) / rate
			match name:
				"plate":
					samples[i] = (0.38 * sin(TAU * 2900.0 * t) + 0.22 * sin(TAU * 4400.0 * t)) * exp(-25.0 * t) + 0.18 * sin(TAU * 120.0 * t) * exp(-40.0 * t)
				"mark":
					var noise := rng.randf_range(-1.0, 1.0)
					samples[i] = 0.35 * (noise - previous_noise) * exp(-90.0 * t)
					previous_noise = noise
				"measure":
					var click := i / 2205
					var click_t := float(i % 2205) / rate
					if click_t < 0.008:
						var burst := 0.32 * rng.randf_range(-1.0, 1.0) + 0.25 * sin(TAU * 1600.0 * click_t)
						samples[i] = burst * exp(-400.0 * click_t) * (1.2 if click == 8 else 1.0)
		var player := AudioStreamPlayer.new()
		player.bus = "SFX"
		player.stream = _wav(samples, rate)
		player.volume_db = -18.0 if name == "measure" else -20.0
		add_child(player)
		_viewer_sfx[name] = player


func _viewer_sound(name: String) -> void:
	_viewer_sfx[name].play()
	viewer_sfx_log.append(name)


func _exit_tree() -> void:
	for player in _viewer_sfx.values():
		player.stop()


func _thumb(tex: Texture2D, text: String) -> Button:
	var b := Button.new()
	b.icon = tex
	b.expand_icon = true
	b.custom_minimum_size = Vector2(100, 122)
	b.text = text
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	Settings.track_font(b, 14)
	b.focus_mode = Control.FOCUS_ALL
	return b


func _thumb_text(i: int) -> String:
	var p: Dictionary = _viewer_plates[i]
	return "第 %d 號%s%s" % [p.number, " ✓" if p.included else "", " ✓讀" if p.get("read", false) else ""]


func refresh_thumbs() -> void:
	var kids := thumbs.get_children()
	for i in _viewer_plates.size():
		if i + 1 < kids.size():
			kids[i + 1].text = _thumb_text(i)


func _select_plate(i: int, tex: Texture2D, sound := true) -> void:
	if _viewer_reporting and sound:
		return
	if sound and (i >= 0 or i == -2):
		_viewer_sound("plate")
	_set_loupe(false)
	_viewer_sel = i
	_plate_texture = tex
	_set_loupe(false)
	blink_btn.disabled = _viewer_reporting or i < 0 or tex == null or _comparison_texture == null
	if i >= 0:
		var plate: Dictionary = _viewer_plates[i]
		blink_btn.disabled = blink_btn.disabled or plate.sunlit or plate.duration < 0.5 or plate.get("stars", 0) == 0
	if i < 0 and micrometer_on:
		_set_micrometer(false)
	_sync_micrometer_controls()
	if i >= 0 and micrometer_on:
		_sync_micrometer()
		if _plate_texture != null:
			loupe_btn.set_pressed_no_signal(true)
			_set_loupe(true)
	if i == -2:
		plate_info.text = "[b]牛津比對底片[/b]（1919 年 1 月，同一具望遠鏡、同一片星場，夜間拍攝）\n沒有太陽的星位置。日食底片上的星若被太陽重力偏折，會相對這裡向外移。"
		if comparison_recall != "":
			plate_info.text += "\n[i]%s[/i]" % comparison_recall
		include_box.visible = false
		return
	include_box.visible = not _viewer_reporting
	var p: Dictionary = _viewer_plates[i]
	include_box.set_pressed_no_signal(p.included)
	include_box.disabled = _viewer_locked
	var lines := []
	lines.append("[b]第 %d 號底片[/b]　曝光 %.1f 秒（全食第 %d 秒開始）" % [p.number, p.duration, int(p.start)])
	if not p.sunlit and p.duration >= 0.5 and p.has("stars"):
		var stars_line := "可辨識的星點：%d 顆" % p.stars
		lines.append("[color=#e88]%s[/color]" % stars_line if p.stars < 5 else stars_line)
	if not p.sunlit and p.get("sky_read", "") != "":
		lines.append(Content.totality_read_night(p.sky_read))
	if not p.sunlit and p.duration >= 0.5 and drive_note != "":
		lines.append(drive_note)
	if p.sunlit:
		lines.append("[color=#e88]第三接觸時快門仍開著——陽光回來，整張過曝。[/color]")
	if p.duration < 0.5:
		lines.append("[color=#e88]幾乎沒有曝光。[/color]")
	if _viewer_locked:
		match p.get("quality", ""):
			"good":
				lines.append("星像清楚。")
			"poor":
				lines.append("[color=#fd8]可量，但星像拖長或被雲霧蓋住。[/color]")
	if _viewer_locked and p.included and p.usable and p.get("read", false) and measurement_of.is_valid():
		var m: Dictionary = measurement_of.call(p)
		lines.append("讀數 [b]%.2f 格[/b]：量得偏折 [b]%.2f″ ± %.2f″[/b]" % [p.reading, m.value, m.sigma])
	elif _viewer_locked and p.included and p.usable and p.get("read", false):
		lines.append("已記下讀數：%.2f 格。" % p.reading)
	elif _viewer_locked and p.included and p.usable:
		lines.append("[color=#fd8]這張還沒讀數——用測微器對好參考星再記下，才會算進結果。[/color]")
	elif _viewer_locked and p.included and not p.usable:
		lines.append("[color=#e88]可辨識的星不足五顆，無法同時解出比例尺與偏折。[/color]")
	plate_info.text = "\n".join(lines)
	if not blink_btn.disabled and not _blink_hint_shown:
		plate_info.text += "\n按「閃爍比對」：同一顆星，在兩張底片上跳一下——那一跳就是要量的東西。\n位移已放大，方便肉眼看見；真正的量測用顯微測微器。"
		_blink_hint_shown = true


func set_viewer_locked(locked: bool) -> void:
	var focused := get_viewport().gui_get_focus_owner() as BaseButton
	var action_focused := focused in [measure_btn, reselect_btn, report_btn, include_box]
	_viewer_locked = locked
	measure_btn.disabled = locked
	reselect_btn.disabled = not locked or _viewer_reporting
	report_btn.disabled = not locked or _viewer_reporting
	include_box.disabled = locked
	mic_btn.disabled = _viewer_reporting or _viewer_sel < 0 or _plate_texture == null
	_sync_micrometer_controls()
	if action_focused and focused.disabled and not _viewer_reporting:
		(reselect_btn if locked else measure_btn).grab_focus()
	if _viewer_sel >= 0 and _viewer_sel < _viewer_plates.size():
		_select_plate(_viewer_sel, _plate_texture, false)


func set_viewer_report(reporting: bool) -> void:
	_viewer_reporting = reporting
	# Leave room for the five-reason dialogue at 1600×900 with large text.
	_layout_viewer()
	if reporting:
		_set_loupe(false)
	viewer_rule.visible = reporting and viewer_rule.text != ""
	# Keep every viewer control out of dialogue focus navigation.
	for button in viewer.find_children("*", "BaseButton", true, false):
		button.disabled = reporting
		button.focus_mode = Control.FOCUS_NONE if reporting else Control.FOCUS_ALL
	report_btn.get_parent().visible = not reporting
	reference_btn.visible = not reporting
	loupe_btn.visible = not reporting
	blink_btn.visible = not reporting
	mic_btn.visible = not reporting
	if reporting:
		_set_micrometer(false)
	mic_row.visible = micrometer_on
	mic_note.visible = micrometer_on
	reference_btn.set_pressed_no_signal(false)
	reference_panel.hide()
	set_viewer_locked(true if reporting else _viewer_locked)
	include_box.visible = not reporting and _viewer_sel >= 0


func set_viewer_note(bb: String) -> void:
	viewer_note.text = bb


func close_viewer() -> void:
	_set_micrometer(false)
	_set_loupe(false)
	viewer.visible = false


## Global centre of a viewer control, for the autoplay bot's simulated clicks.
func viewer_button_center(which: String) -> Vector2:
	var c: Control = {"measure": measure_btn, "reselect": reselect_btn, "report": report_btn, "include": include_box}[which]
	return c.get_global_rect().get_center()


func thumb_center(i: int) -> Vector2:
	return thumbs.get_child(i + 1).get_global_rect().get_center()


# ------------------------------------------------------------ Title/ending/pause

func _build_title(root: Control) -> void:
	title_panel = ColorRect.new()
	(title_panel as ColorRect).color = Color(0.03, 0.03, 0.04, 0.78)
	title_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(title_panel)
	# The same Hyades sky, faint behind the title (it follows the panel's 0.78 alpha).
	var sky := FadeStars.new()
	sky.target = title_panel as ColorRect
	sky.drop = 0.16  # keeps Aldebaran clear of the title buttons
	sky.meteors = true
	sky.figure = true
	title_panel.add_child(sky)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(-460, -330)
	v.custom_minimum_size = Vector2(920, 0)
	v.add_theme_constant_override("separation", 14)
	title_panel.add_child(v)
	var t := _label("雲層之後", 64, PAPER)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var st := _label("劍橋，1917 → 普林西比，1919", 26, ACCENT)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(st)
	var body := _rich(19)
	body.text = ("[center]1917 年，劍橋的雨夜。記錄同一片星空的兩張圖，對不上。\n"
		+ "有人會說，對不上的東西就是假的。\n"
		+ "兩年後，在赤道的雲層底下，你只有 302 秒——去量星光經過太陽時，有沒有彎。[/center]\n")
	v.add_child(body)
	var disclaimer := _rich(15)
	disclaimer.text = "[color=#8f8676]" + Credits.DISCLAIMER + "[/color]"
	v.add_child(disclaimer)
	title_controls = _label("", 18, DIM)
	title_controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title_controls)
	# Steam Deck starts on the pad, so the first hints must already name its buttons.
	Prompts.joypad = not Input.get_connected_joypads().is_empty()
	_refresh_hints()
	title_note = _label("第一次玩請從序章開始；只玩尾章會略過劍橋的調查、出發前的準備與結尾的後續。", 15, Color("8f8676"))
	title_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_note.custom_minimum_size.x = 920
	v.add_child(title_note)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	v.add_child(hb)
	prologue_btn = _button("開始遊戲：序章・劍橋，1917")
	prologue_btn.pressed.connect(func(): prologue_pressed.emit())
	hb.add_child(prologue_btn)
	start_btn = _button("只玩尾章：普林西比，1919")
	start_btn.pressed.connect(func(): start_pressed.emit())
	hb.add_child(start_btn)
	var credits := _button("製作名單")
	credits.focus_mode = Control.FOCUS_ALL
	credits.pressed.connect(_open_credits)
	hb.add_child(credits)
	_settings_button = _button("設定")
	_settings_button.focus_mode = Control.FOCUS_ALL
	_settings_button.pressed.connect(open_settings)
	hb.add_child(_settings_button)
	var q := _button("　離開　")
	q.pressed.connect(func(): quit_pressed.emit())
	hb.add_child(q)
	var version := _label("v" + str(ProjectSettings.get_setting("application/config/version")), 15, Color("8f8676"))
	version.name = "Version"
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_panel.add_child(version)
	version.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	version.position -= version.get_minimum_size() + Vector2(24, 18)
	version.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prologue_btn.grab_focus()


func hide_title() -> void:
	title_panel.visible = false


func _build_ending(root: Control) -> void:
	ending_panel = ColorRect.new()
	(ending_panel as ColorRect).color = Color("0d0b09")
	var gradient := Gradient.new()
	gradient.colors = PackedColorArray([Color("0d0b09"), Color("17120d")])
	var background := TextureRect.new()
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	background.texture = texture
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ending_panel.add_child(background)
	ending_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_panel.visible = false
	root.add_child(ending_panel)
	var scroll := ScrollContainer.new()
	scroll.follow_focus = false
	ending_scroll = scroll
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 100
	scroll.offset_right = -100
	scroll.offset_top = 24
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.offset_bottom = -110
	ending_panel.add_child(scroll)
	ending_center = CenterContainer.new()
	ending_center.name = "EndingContentCenter"
	ending_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(ending_center)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	ending_center.add_child(v)
	ending_title = _label("", 44, PAPER)
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ending_title)
	ending_objects = BoxContainer.new()
	ending_objects.add_theme_constant_override("separation", 24)
	ending_objects.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(ending_objects)
	ending_plate_card = PanelContainer.new()
	ending_plate_card.name = "EndingPlateCard"
	ending_plate_card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ending_plate_card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	ending_plate_card.add_theme_stylebox_override("panel", _panel_style(Color("211b15"), Color("493c2c")))
	ending_objects.add_child(ending_plate_card)
	ending_plate_content = BoxContainer.new()
	ending_plate_content.vertical = true
	ending_plate_content.add_theme_constant_override("separation", 8)
	ending_plate_card.add_child(ending_plate_content)
	ending_plate = TextureRect.new()
	ending_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	ending_plate_content.add_child(ending_plate)
	ending_plate_caption = _label("", 17)
	ending_plate_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_plate_caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_plate_content.add_child(ending_plate_caption)
	ending_slip = PanelContainer.new()
	ending_slip.name = "EndingTelegramSlip"
	ending_slip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ending_slip.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var paper := _panel_style(Color("e9e1cf"), Color("b9ad93"))
	paper.set_border_width_all(1)
	paper.set_corner_radius_all(2)
	paper.content_margin_left = 28
	paper.content_margin_right = 28
	paper.content_margin_top = 22
	paper.content_margin_bottom = 22
	ending_slip.add_theme_stylebox_override("panel", paper)
	ending_objects.add_child(ending_slip)
	ending_telegram = _rich(19)
	ending_telegram.add_theme_color_override("default_color", Color("2b2620"))
	ending_slip.add_child(ending_telegram)
	scroll.resized.connect(_layout_ending_objects)
	ending_telegram.theme_changed.connect(_layout_ending_objects)
	ending_text = _rich(19)
	ending_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(ending_text)
	ending_review_toggle = _button("回顧證據與評語")
	ending_review_toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ending_review_toggle.pressed.connect(_toggle_ending_review)
	ending_review = _rich(19)
	ending_review.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_review.visible = false
	v.add_child(ending_review)
	ending_history_toggle = _button("歷史上發生了什麼")
	ending_history_toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ending_history_toggle.pressed.connect(_toggle_ending_history)
	ending_history = _rich(17)
	ending_history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_history.visible = false
	v.add_child(ending_history)
	var hb := HFlowContainer.new()
	hb.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	hb.offset_left = 8
	hb.offset_right = -8
	hb.offset_top = -48
	hb.offset_bottom = -48
	hb.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hb.alignment = FlowContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("h_separation", 8)
	hb.add_theme_constant_override("v_separation", 12)
	ending_panel.add_child(hb)
	var replay_hint := _label("重玩從 1919 年 5 月 29 日的準備開始；上一回的紀錄會留著，結尾會和這一回並排比較。", 16, DIM)
	replay_hint.name = "EndingReplayHint"
	replay_hint.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	replay_hint.offset_left = 20
	replay_hint.offset_right = -20
	replay_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	replay_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	replay_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_panel.add_child(replay_hint)
	ending_replay_hint = replay_hint
	var place_row := func():
		hb.offset_top = -48 - hb.get_combined_minimum_size().y
		var hint_height := replay_hint.get_combined_minimum_size().y
		replay_hint.offset_bottom = hb.offset_top - 4
		replay_hint.offset_top = replay_hint.offset_bottom - hint_height
		scroll.offset_bottom = replay_hint.offset_top - 4
	hb.minimum_size_changed.connect(place_row)
	replay_hint.minimum_size_changed.connect(place_row)
	hb.resized.connect(place_row)
	var same := _button("同一片雲：換個做法，再量一次")
	ending_replay = same
	same.pressed.connect(func(): restart_pressed.emit(true))
	hb.add_child(same)
	hb.add_child(ending_review_toggle)
	hb.add_child(ending_history_toggle)
	var fresh := _button("新的天空：換一種雲況")
	fresh.pressed.connect(func(): restart_pressed.emit(false))
	hb.add_child(fresh)
	var credits := _button("製作名單")
	credits.focus_mode = Control.FOCUS_ALL
	credits.pressed.connect(_open_credits)
	hb.add_child(credits)
	var q := _button("離開")
	q.pressed.connect(func(): quit_pressed.emit())
	hb.add_child(q)
	# Right/left traverse visual reading order even across a wrapped line.
	# Up/down remain reserved for scrolling the narrative.
	hb.sort_children.connect(func():
		var buttons := hb.get_children().filter(func(b): return b.visible)
		for i in buttons.size():
			var b: Button = buttons[i]
			b.focus_neighbor_left = b.get_path_to(buttons[(i - 1 + buttons.size()) % buttons.size()])
			b.focus_neighbor_right = b.get_path_to(buttons[(i + 1) % buttons.size()])
			b.focus_previous = b.focus_neighbor_left
			b.focus_next = b.focus_neighbor_right
	)
	var hint := _label("↑↓ 或右搖桿：捲動", 16, DIM)
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-220, -32)
	hint.size = Vector2(440, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_panel.add_child(hint)
	_build_credits(root)


func _build_credits(root: Control) -> void:
	credits_panel = ColorRect.new()
	credits_panel.name = "Credits"
	(credits_panel as ColorRect).color = Color(0.03, 0.03, 0.04, 0.97)
	credits_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	credits_panel.visible = false
	credits_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	credits_panel.z_index = 2
	root.add_child(credits_panel)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 80
	v.offset_right = -80
	v.offset_top = 40
	v.offset_bottom = -40
	v.add_theme_constant_override("separation", 16)
	credits_panel.add_child(v)
	var scroll := ScrollContainer.new()
	credits_scroll = scroll
	scroll.follow_focus = true
	scroll.name = "Scroll"
	scroll.focus_mode = Control.FOCUS_ALL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var content := _rich(18)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.text = Credits.text()
	scroll.add_child(content)
	var back := _button("返回")
	back.focus_mode = Control.FOCUS_ALL
	back.add_theme_stylebox_override("focus", back.get_theme_stylebox("hover"))
	back.pressed.connect(_close_credits)
	v.add_child(back)
	var hint := _label("↑↓ 或右搖桿：捲動", 16, DIM)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(hint)


func _open_credits() -> void:
	_credits_focus = get_viewport().gui_get_focus_owner()
	credits_panel.show()
	credits_scroll.scroll_vertical = 0
	_menu_scroll_remainder = 0.0
	(credits_panel.find_children("*", "Button", true, false)[0] as Button).grab_focus()


func _layout_ending_objects() -> void:
	var narrow := ending_scroll.size.x < 1100
	ending_objects.vertical = narrow
	ending_slip.custom_minimum_size.x = minf(620 * Settings.text_scale, ending_scroll.size.x)
	ending_plate_content.vertical = not narrow
	var side := 96.0 if narrow else 260.0
	ending_plate.custom_minimum_size = Vector2(side, side)


func show_ending(title: String, bb: String, history_bb := "", review_bb := "", telegram_bb := "", plate: Texture2D = null, plate_caption := "") -> void:
	ending_title.text = title
	ending_text.text = bb
	ending_telegram.text = telegram_bb
	ending_objects.visible = not telegram_bb.is_empty()
	ending_plate.texture = plate
	ending_plate_caption.text = plate_caption
	_layout_ending_objects()
	ending_review.text = review_bb
	ending_review.visible = false
	ending_review_toggle.visible = not review_bb.is_empty()
	ending_review_toggle.text = "回顧證據與評語"
	ending_history.text = history_bb
	ending_history.visible = false
	ending_history_toggle.visible = not history_bb.is_empty()
	ending_history_toggle.text = "歷史上發生了什麼"
	ending_panel.visible = true
	ending_replay.grab_focus()
	ending_scroll.scroll_vertical = 0
	_menu_scroll_remainder = 0.0
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func _toggle_ending_review() -> void:
	ending_review.visible = not ending_review.visible
	ending_review_toggle.text = "收起回顧" if ending_review.visible else "回顧證據與評語"


func _toggle_ending_history() -> void:
	ending_history.visible = not ending_history.visible
	ending_history_toggle.text = "收起歷史" if ending_history.visible else "歷史上發生了什麼"


func _build_pause(root: Control) -> void:
	pause_panel = ColorRect.new()
	(pause_panel as ColorRect).color = Color(0, 0, 0, 0.6)
	pause_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_panel.visible = false
	pause_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_panel.z_index = 1
	root.add_child(pause_panel)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.anchor_left = 0.5
	scroll.anchor_right = 0.5
	scroll.offset_left = -150
	scroll.offset_right = 150
	scroll.offset_top = 20
	scroll.offset_bottom = -20
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	pause_panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	scroll.add_child(v)
	_pause_heading = _label("暫停", 36)
	_pause_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_pause_heading)
	var r := _button("繼續")
	_resume_button = r
	r.pressed.connect(func():
		if _settings_only:
			close_settings()
		else:
			toggle_pause())
	v.add_child(r)
	music_button = _button("音樂：開" if ScorePlayer.music_enabled() else "音樂：關")
	music_button.pressed.connect(func():
		ScorePlayer.set_music_enabled(not ScorePlayer.music_enabled())
		music_button.text = "音樂：開" if ScorePlayer.music_enabled() else "音樂：關"
		_sync_music_row())
	v.add_child(music_button)
	for bus in ["Master", "Music", "SFX"]:
		var row := HBoxContainer.new()
		var label := _label({"Master": "主音量", "Music": "音樂", "SFX": "音效"}[bus], 20)
		label.custom_minimum_size.x = 80
		row.add_child(label)
		var slider := HSlider.new()
		slider.max_value = 1.0
		slider.step = 0.05
		slider.value = Settings.volumes[bus]
		slider.focus_mode = Control.FOCUS_ALL
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.value_changed.connect(func(value: float): Settings.set_volume(bus, value))
		row.add_child(slider)
		v.add_child(row)
		if bus == "Music":
			music_row = row
			music_slider = slider
	_sync_music_row()
	fullscreen_button = _button("全螢幕：開" if Settings.fullscreen else "全螢幕：關")
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	v.add_child(fullscreen_button)
	text_size_button = _button(_text_size_caption())
	text_size_button.pressed.connect(_cycle_text_size)
	v.add_child(text_size_button)
	quality_button = _button(_quality_caption())
	quality_button.pressed.connect(_cycle_quality)
	v.add_child(quality_button)
	var look := _button("視角靈敏度：" + ["低", "標準", "高"][Settings.LOOK_SPEEDS.find(Settings.look_speed)])
	look.pressed.connect(func():
		Settings.cycle_look_speed()
		look.text = "視角靈敏度：" + ["低", "標準", "高"][Settings.LOOK_SPEEDS.find(Settings.look_speed)])
	v.add_child(look)
	var invert := _button("上下反轉：開" if Settings.invert_y else "上下反轉：關")
	invert.pressed.connect(func():
		Settings.toggle_invert_y()
		invert.text = "上下反轉：開" if Settings.invert_y else "上下反轉：關")
	v.add_child(invert)
	var motion := _button("減少晃動：開" if Settings.reduced_motion else "減少晃動：關")
	motion.pressed.connect(func():
		Settings.toggle_reduced_motion()
		motion.text = "減少晃動：開" if Settings.reduced_motion else "減少晃動：關")
	v.add_child(motion)
	hold_button = _button("長按互動：按一下" if Settings.hold_toggle else "長按互動：按住")
	hold_button.pressed.connect(func():
		Settings.toggle_hold_toggle()
		hold_button.text = "長按互動：按一下" if Settings.hold_toggle else "長按互動：按住")
	v.add_child(hold_button)
	var help := _button("操作說明")
	help.pressed.connect(_open_help)
	v.add_child(help)
	_pause_title_btn = _button("回到標題")
	var pause_title := _pause_title_btn
	pause_title.pressed.connect(func():
		if not _title_armed:
			_title_armed = true
			pause_title.text = "再按一次：回到標題"
			return
		_return_to_title())
	v.add_child(pause_title)
	# Restart and quit throw away the run, and there is no save: ask twice.
	restart_button = _button("從頭開始")
	restart_button.pressed.connect(func():
		if not _restart_armed:
			_restart_armed = true
			restart_button.text = "再按一次：從頭開始"
			return
		get_tree().paused = false
		restart_pressed.emit(true))
	v.add_child(restart_button)
	quit_button = _button("離開遊戲")
	quit_button.pressed.connect(func():
		if not _quit_armed:
			_quit_armed = true
			quit_button.text = "再按一次：離開（進度不會保留）"
			return
		quit_pressed.emit())
	v.add_child(quit_button)
	for button in [r, music_button, fullscreen_button, look, invert, motion, hold_button, restart_button, quit_button]:
		button.focus_mode = Control.FOCUS_ALL
	# Long labels (the armed 「再按一次：…」 texts at 大) wrap inside the 300 px column instead of widening it.
	for button in [r, music_button, fullscreen_button, text_size_button, quality_button, look, invert, motion, hold_button, help, pause_title, restart_button, quit_button]:
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _toggle_fullscreen() -> void:
	Settings.toggle_fullscreen()
	fullscreen_button.text = "全螢幕：開" if Settings.fullscreen else "全螢幕：關"


# A muted bus makes its slider dead weight; dim it instead of leaving it live.
func _sync_music_row() -> void:
	if music_slider == null:
		return
	var on := ScorePlayer.music_enabled()
	music_slider.editable = on
	music_slider.focus_mode = Control.FOCUS_ALL if on else Control.FOCUS_NONE
	music_row.modulate.a = 1.0 if on else 0.4


func open_settings() -> void:
	_pause_focus = get_viewport().gui_get_focus_owner()
	_settings_only = true
	_title_focus_modes.clear()
	for button in prologue_btn.get_parent().get_children():
		_title_focus_modes.append(button.focus_mode)
		button.focus_mode = Control.FOCUS_NONE
	_pause_heading.text = "設定"
	_resume_button.text = "返回"
	_pause_title_btn.hide()
	restart_button.hide()
	quit_button.hide()
	pause_panel.show()
	quality_button.text = _quality_caption()
	Settings.sync_fullscreen()
	fullscreen_button.text = "全螢幕：開" if Settings.fullscreen else "全螢幕：關"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_resume_button.grab_focus()


func close_settings() -> void:
	pause_panel.hide()
	_pause_heading.text = "暫停"
	_resume_button.text = "繼續"
	_pause_title_btn.show()
	restart_button.show()
	quit_button.show()
	_settings_only = false
	var buttons := prologue_btn.get_parent().get_children()
	for i in buttons.size():
		buttons[i].focus_mode = _title_focus_modes[i]
	_restore_focus(_settings_button)


func toggle_pause() -> void:
	if _settings_only:
		return
	var p := not get_tree().paused
	if p:
		_pause_focus = get_viewport().gui_get_focus_owner()
	get_tree().paused = p
	pause_panel.visible = p
	if p:
		quality_button.text = _quality_caption()
		Settings.sync_fullscreen()
		fullscreen_button.text = "全螢幕：開" if Settings.fullscreen else "全螢幕：關"
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_panel.find_children("*", "Button", true, false)[0].grab_focus()
	else:
		_restart_armed = false
		_quit_armed = false
		_title_armed = false
		restart_button.text = "從頭開始"
		quit_button.text = "離開遊戲"
		_pause_title_btn.text = "回到標題"
		_restore_focus(_pause_focus)
	# Only the chapter knows every form and scripted input lock it owns.
	pause_toggled.emit(p)


# Dialogue history is shared by both chapters; Tab never advances dialogue.
func _build_log(root: Control) -> void:
	log_panel = PanelContainer.new()
	log_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	log_panel.offset_left = 150
	log_panel.offset_right = -150
	log_panel.offset_top = 55
	log_panel.offset_bottom = -55
	log_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.04, 0.035, 0.03, 0.98), ACCENT))
	log_panel.visible = false
	root.add_child(log_panel)
	var v := VBoxContainer.new()
	log_panel.add_child(v)
	log_title = _label("對話紀錄　［%s 關閉］" % Prompts.key("toggle_log"), 28, ACCENT)
	v.add_child(log_title)
	log_scroll = ScrollContainer.new()
	log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(log_scroll)
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	log_text.fit_content = true
	log_text.scroll_following = false
	log_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	log_text.add_theme_color_override("default_color", PAPER)
	log_scroll.add_child(log_text)
	log_back = _button("返回　%s" % Prompts.key("toggle_log"))
	log_back.pressed.connect(toggle_log)
	v.add_child(log_back)


func log_open() -> bool:
	return log_panel.visible


func toggle_log() -> void:
	log_panel.visible = not log_panel.visible
	# The dialogue panel's bottom edge sits below the log; its input hint is inert while reading.
	hint_label.visible = not log_panel.visible
	if log_panel.visible:
		_log_focus = get_viewport().gui_get_focus_owner()
		log_panel.find_children("*", "Button", true, false)[0].grab_focus()
		_log_mouse_mode = Input.mouse_mode
		log_text.text = "\n\n".join(history)
		_scroll_log_to_bottom()
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = _log_mouse_mode
		_restore_focus(_log_focus)
	log_toggled.emit(log_panel.visible)


## Opening the log starts at the newest line, like the log did when it followed.
## The label's height settles over a few frames, so follow the maximum until it stops growing.
func _scroll_log_to_bottom() -> void:
	var last := -1.0
	for i in 6:
		await get_tree().process_frame
		if not is_instance_valid(log_scroll):
			return
		var bar := log_scroll.get_v_scroll_bar()
		var bottom := bar.max_value - bar.page
		log_scroll.scroll_vertical = int(bottom)
		if bottom == last:
			return
		last = bottom


func _restore_focus(previous: Control) -> void:
	if is_instance_valid(previous) and previous.is_visible_in_tree():
		previous.grab_focus()
	else:
		var owner := get_viewport().gui_get_focus_owner()
		if owner:
			owner.release_focus()


func _close_credits() -> void:
	credits_panel.hide()
	_restore_focus(_credits_focus)


func _build_help(root: Control) -> void:
	help_panel = ColorRect.new()
	help_panel.name = "Help"
	(help_panel as ColorRect).color = Color(0.03, 0.03, 0.04, 0.97)
	help_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	help_panel.visible = false
	help_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	help_panel.z_index = 2
	root.add_child(help_panel)
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_FULL_RECT)
	v.offset_left = 80
	v.offset_right = -80
	v.offset_top = 40
	v.offset_bottom = -40
	v.add_theme_constant_override("separation", 16)
	help_panel.add_child(v)
	v.add_child(_label("操作說明", 28, ACCENT))
	help_content = _rich(18)
	help_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	help_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	v.add_child(help_content)
	var back := _button("返回")
	back.focus_mode = Control.FOCUS_ALL
	back.add_theme_stylebox_override("focus", back.get_theme_stylebox("hover"))
	back.pressed.connect(_close_help)
	v.add_child(back)


func _help_text() -> String:
	var text: String = title_controls.text
	# The opener line is already part of the live control text unless a future layout drops it.
	if not text.contains(Prompts.key("shutter")):
		text += "\n全食時：空白鍵（或 RB／X）喊開始與停。"
	return text


func _open_help() -> void:
	_help_focus = get_viewport().gui_get_focus_owner()
	help_content.text = _help_text()
	help_panel.show()
	(help_panel.find_children("*", "Button", true, false)[0] as Button).grab_focus()


func _close_help() -> void:
	help_panel.hide()
	_restore_focus(_help_focus)


func _return_to_title() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	title_pressed.emit()


func _refresh_hints() -> void:
	if title_controls:
		title_controls.text = "WASD／左搖桿 移動 · 滑鼠／方向鍵／右搖桿 觀看 · Shift／L3 跑\n%s 互動 · %s 紀錄 · %s 開始與停 · %s 暫停" % [Prompts.key("interact"), Prompts.key("toggle_log"), Prompts.key("shutter"), Prompts.key("pause")]
	if help_panel and help_panel.visible:
		help_content.text = _help_text()
	if log_title:
		log_title.text = "對話紀錄　［%s 關閉］" % Prompts.key("toggle_log")
	if log_back:
		log_back.text = "返回　%s" % Prompts.key("toggle_log")
	tot_hint.text = "［%s／%s］開始・停" % [Prompts.key("shutter"), Prompts.key("interact")]
	if not _choice_buttons.is_empty():
		hint_label.text = "［方向鍵／A 鍵］選擇" if Prompts.joypad else "［1–%d 或點擊］選擇" % _choice_buttons.size()
	else:
		hint_label.text = "［%s］繼續" % Prompts.key("interact") if Prompts.joypad else "［E／空白鍵／點擊］繼續"


func blocks_world_input() -> bool:
	return log_panel.visible or pause_panel.visible or help_panel.visible or credits_panel.visible or dialog_active()


func _active_menu_scroll() -> ScrollContainer:
	if log_panel.visible:
		return log_scroll
	if pause_panel.visible or dialog_panel.visible or viewer.visible:
		return null
	if credits_panel.visible:
		return credits_scroll
	return ending_scroll if ending_panel.visible else null


func _input(event: InputEvent) -> void:
	var was_joypad := Prompts.joypad
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.25):
		Prompts.joypad = true
	elif event is InputEventKey or event is InputEventMouse:
		Prompts.joypad = false
	_refresh_hints()
	if Prompts.joypad != was_joypad:
		prompts_changed.emit()
	if viewer.visible and micrometer_on and not _viewer_reporting and not get_tree().paused and not log_panel.visible and (event is InputEventKey or event is InputEventJoypadButton):
		if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			_nudge_micrometer(-1.0 if event.is_action_pressed("ui_left") else 1.0, _mic_fine())
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_accept") and _viewer_sel >= 0 and not _viewer_locked:
			_record_micrometer()
			get_viewport().set_input_as_handled()
			return
		# On a pad, B first puts the micrometer away; a second B leaves the table.
		if event.is_action_pressed("ui_cancel") and not event.is_action_pressed("pause"):
			_set_micrometer(false)
			get_viewport().set_input_as_handled()
			return
	if viewer.visible and loupe_btn.button_pressed and (loupe_btn.has_focus() or blink_btn.has_focus()) and not get_tree().paused and not log_panel.visible and (event is InputEventKey or event is InputEventJoypadButton):
		if event.is_action_pressed("overlay_rotate_right") and not blink_btn.disabled:
			blink_btn.grab_focus()
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("overlay_rotate_left"):
			loupe_btn.grab_focus()
			get_viewport().set_input_as_handled()
			return
		var directions := {"ui_left": Vector2.LEFT, "ui_right": Vector2.RIGHT, "ui_up": Vector2.UP, "ui_down": Vector2.DOWN}
		for action in directions:
			if event.is_action(action) and (loupe_btn.has_focus() or blink_btn.button_pressed):
				if event.is_pressed():
					_show_loupe(_loupe_center + directions[action] * 18.0)
				get_viewport().set_input_as_handled()
				return
	if event.is_action_pressed("toggle_fullscreen"):
		_toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	var scroll := _active_menu_scroll()
	if scroll and (event.is_action("ui_up") or event.is_action("ui_down")):
		if event.is_action_pressed("ui_up") or event.is_action_pressed("ui_down"):
			scroll.scroll_vertical += 80 if event.is_action_pressed("ui_down") else -80
		get_viewport().set_input_as_handled()
		return
	if credits_panel.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_close_credits()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_log"):
			get_viewport().set_input_as_handled()
		return
	if help_panel.visible:
		if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
			_close_help()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("toggle_log"):
			get_viewport().set_input_as_handled()
		return
	if pause_panel.visible and (event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel")):
		if _settings_only:
			close_settings()
		else:
			toggle_pause()
		get_viewport().set_input_as_handled()
		return
	if log_panel.visible and pause_enabled and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		toggle_pause()
		return
	if log_panel.visible and event.is_action_pressed("ui_cancel") and not event.is_action_pressed("pause"):
		toggle_log()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("toggle_log") and not get_tree().paused:
		toggle_log()
		get_viewport().set_input_as_handled()
	elif log_panel.visible:
		if event is InputEventKey and not event.is_action("pause") and not event.is_action("ui_accept") and not event.is_action("ui_up") and not event.is_action("ui_down"):
			get_viewport().set_input_as_handled()
	elif viewer.visible and not _viewer_reporting and event.is_action_pressed("ui_cancel") and not event.is_action_pressed("pause") and not get_tree().paused:
		viewer_closed.emit()
		get_viewport().set_input_as_handled()
	else:
		_dialogue_input(event)
