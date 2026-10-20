extends CanvasLayer

const ScorePlayer := preload("res://scripts/audio/score_player.gd")
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
signal plate_toggled(index: int, on: bool)
signal measure_pressed
signal reselect_pressed
signal report_pressed
signal viewer_closed

const PAPER := Color(0.93, 0.89, 0.80)
const INK := Color(0.10, 0.09, 0.08)
const DIM := Color(0.70, 0.66, 0.58)
const ACCENT := Color(0.95, 0.72, 0.38)

var font: SystemFont
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
var dialog_panel: PanelContainer
var speaker_label: Label
var text_label: RichTextLabel
var choice_box: VBoxContainer
var hint_label: Label
var fade: ColorRect
var caption: Label
var title_panel: Control
var prologue_btn: Button
var start_btn: Button
var log_panel: PanelContainer
var log_text: RichTextLabel
static var history: Array[String] = []
var _log_mouse_mode := Input.MOUSE_MODE_VISIBLE
var ending_panel: Control
var ending_text: RichTextLabel
var ending_title: Label
var ending_history: RichTextLabel
var ending_history_toggle: Button
var pause_panel: Control
var viewer: Control
var thumbs: GridContainer
var big_plate: TextureRect
var plate_info: RichTextLabel
var include_box: CheckBox
var measure_btn: Button
var reselect_btn: Button
var report_btn: Button
var chart: Control
var viewer_note: RichTextLabel

var _seq: Array = []
var _seq_i := 0
var _results := {}
var _choice_buttons: Array[Button] = []
var _viewer_sel := -1
var _viewer_plates: Array = []
var _viewer_locked := false
var pause_enabled := false


func _ready() -> void:
	layer = 10
	font = SystemFont.new()
	font.font_names = PackedStringArray(["PingFang TC", "Heiti TC", "Noto Sans CJK TC", "Noto Sans TC", "Microsoft JhengHei", "Source Han Sans TC", "sans-serif"])
	theme_res = Theme.new()
	theme_res.default_font = font
	theme_res.default_font_size = 21
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = theme_res
	add_child(root)
	_build_hud(root)
	_build_dialog(root)
	_build_viewer(root)
	_build_title(root)
	_build_ending(root)
	_build_pause(root)
	_build_log(root)
	fade = ColorRect.new()
	fade.color = Color(0, 0, 0, 0)
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fade)
	caption = Label.new()
	caption.set_anchors_preset(Control.PRESET_FULL_RECT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.add_theme_font_size_override("font_size", 34)
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


func _label(text: String, size := 21, color := PAPER) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l


func _rich(size := 20) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_color_override("default_color", PAPER)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 20)
	b.focus_mode = Control.FOCUS_NONE
	var normal := _panel_style(Color(0.18, 0.15, 0.12, 0.95), Color(0.55, 0.45, 0.3))
	normal.set_content_margin_all(10)
	var hover := _panel_style(Color(0.32, 0.25, 0.16, 0.98), ACCENT)
	hover.set_content_margin_all(10)
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
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
	tot_panel.position = Vector2(-430, -250)
	tot_panel.custom_minimum_size = Vector2(410, 0)
	tot_panel.visible = false
	hud.add_child(tot_panel)
	tot_label = _rich(19)
	tot_panel.add_child(tot_label)


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


func _process(delta: float) -> void:
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t < 0.6:
			toast.modulate.a = maxf(_toast_t / 0.6, 0.0)


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
	text_label = _rich(22)
	text_label.custom_minimum_size = Vector2(1080, 0)
	v.add_child(text_label)
	choice_box = VBoxContainer.new()
	choice_box.add_theme_constant_override("separation", 6)
	v.add_child(choice_box)
	hint_label = _label("［E／空白鍵／點擊］繼續", 16, DIM)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	v.add_child(hint_label)


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
	for b in _choice_buttons:
		b.queue_free()
	_choice_buttons.clear()
	var choices: Array = e.get("choices", [])
	hint_label.text = "［1–%d 或點擊］選擇" % choices.size() if choices.size() > 0 else "［E／空白鍵／點擊］繼續"
	for i in choices.size():
		var b := _button("%d.  %s" % [i + 1, choices[i]])
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_choose.bind(i))
		choice_box.add_child(b)
		_choice_buttons.append(b)
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
			b.queue_free()
		_choice_buttons.clear()
		dialogue_done.emit(_results)
		return
	_show_entry()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and pause_enabled:
		get_viewport().set_input_as_handled()
		toggle_pause()
		return
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
	if not has_choices:
		var adv := event.is_action_pressed("interact") or event.is_action_pressed("shutter") or event.is_action_pressed("ui_accept")
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			adv = true
		if adv:
			get_viewport().set_input_as_handled()
			_advance()


# ----------------------------------------------------------------------- Totality

func set_totality(visible_: bool, bb := "") -> void:
	tot_panel.visible = visible_
	tot_label.text = bb


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
	left.custom_minimum_size = Vector2(330, 0)
	h.add_child(left)
	left.add_child(_label("已沖洗的底片", 24, ACCENT))
	left.add_child(_label("點選檢視；勾選要量測的底片。\n先依星像品質決定，再按「量測」。", 16, DIM))
	thumbs = GridContainer.new()
	thumbs.columns = 3
	thumbs.add_theme_constant_override("h_separation", 6)
	thumbs.add_theme_constant_override("v_separation", 6)
	left.add_child(thumbs)
	viewer_note = _rich(15)
	left.add_child(viewer_note)
	# Middle: big plate + info.
	var mid := VBoxContainer.new()
	mid.custom_minimum_size = Vector2(470, 0)
	h.add_child(mid)
	big_plate = TextureRect.new()
	big_plate.custom_minimum_size = Vector2(460, 460)
	big_plate.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	big_plate.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	mid.add_child(big_plate)
	plate_info = _rich(18)
	mid.add_child(plate_info)
	include_box = CheckBox.new()
	include_box.text = "納入量測"
	include_box.add_theme_font_size_override("font_size", 20)
	include_box.add_theme_color_override("font_color", PAPER)
	include_box.focus_mode = Control.FOCUS_NONE
	include_box.toggled.connect(func(on): if _viewer_sel >= 0: plate_toggled.emit(_viewer_sel, on))
	mid.add_child(include_box)
	# Right: chart + actions.
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 10)
	h.add_child(right)
	right.add_child(_label("星光偏折（太陽邊緣，角秒）", 22, ACCENT))
	chart = preload("res://scripts/chart.gd").new()
	chart.custom_minimum_size = Vector2(560, 420)
	right.add_child(chart)
	var btns := HBoxContainer.new()
	btns.add_theme_constant_override("separation", 10)
	right.add_child(btns)
	measure_btn = _button("量測所選底片")
	measure_btn.pressed.connect(func(): measure_pressed.emit())
	btns.add_child(measure_btn)
	reselect_btn = _button("重新選片")
	reselect_btn.pressed.connect(func(): reselect_pressed.emit())
	btns.add_child(reselect_btn)
	report_btn = _button("向 Eddington 報告 →")
	report_btn.pressed.connect(func(): report_pressed.emit())
	btns.add_child(report_btn)
	var close := _button("離開桌子")
	close.pressed.connect(func(): viewer_closed.emit())
	btns.add_child(close)
	right.add_child(_label("示意模擬資料：數值為遊戲模型，不是 1919 年的實際量測。", 15, DIM))


func open_viewer(plates: Array, comparison_tex: Texture2D, textures: Array, locked: bool) -> void:
	viewer.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_viewer_plates = plates
	for c in thumbs.get_children():
		c.queue_free()
	var comp := _thumb(comparison_tex, "牛津比對片")
	comp.pressed.connect(_select_plate.bind(-2, comparison_tex))
	thumbs.add_child(comp)
	for i in plates.size():
		var b := _thumb(textures[i], "第 %d 號%s" % [plates[i].number, " ✓" if plates[i].included else ""])
		b.pressed.connect(_select_plate.bind(i, textures[i]))
		thumbs.add_child(b)
	set_viewer_locked(locked)
	if plates.size() > 0:
		_select_plate(0, textures[0])
	else:
		_select_plate(-2, comparison_tex)


func _thumb(tex: Texture2D, text: String) -> Button:
	var b := Button.new()
	b.icon = tex
	b.expand_icon = true
	b.custom_minimum_size = Vector2(100, 122)
	b.text = text
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	b.add_theme_font_size_override("font_size", 14)
	b.focus_mode = Control.FOCUS_NONE
	return b


func refresh_thumbs() -> void:
	var kids := thumbs.get_children()
	for i in _viewer_plates.size():
		if i + 1 < kids.size():
			kids[i + 1].text = "第 %d 號%s" % [_viewer_plates[i].number, " ✓" if _viewer_plates[i].included else ""]


func _select_plate(i: int, tex: Texture2D) -> void:
	_viewer_sel = i
	big_plate.texture = tex
	if i == -2:
		plate_info.text = "[b]牛津比對底片[/b]（1919 年 1 月，同一具望遠鏡、同一片星場，夜間拍攝）\n沒有太陽的星位置。日食底片上的星若被太陽重力偏折，會相對這裡向外移。"
		include_box.visible = false
		return
	include_box.visible = true
	var p: Dictionary = _viewer_plates[i]
	include_box.set_pressed_no_signal(p.included)
	include_box.disabled = _viewer_locked
	var lines := []
	lines.append("[b]第 %d 號底片[/b]　曝光 %.1f 秒（全食第 %d 秒開始）" % [p.number, p.duration, int(p.start)])
	if p.sunlit:
		lines.append("[color=#e88]第三接觸時快門仍開著——陽光回來，整張過曝。[/color]")
	if p.duration < 0.5:
		lines.append("[color=#e88]幾乎沒有曝光。[/color]")
	if p.has("value") and _viewer_locked and p.included and p.usable:
		lines.append("量得偏折：[b]%.2f″ ± %.2f″[/b]" % [p.value, p.sigma])
	elif _viewer_locked and p.included and not p.usable:
		lines.append("[color=#e88]可辨識的星不足五顆，無法同時解出比例尺與偏折。[/color]")
	plate_info.text = "\n".join(lines)


func set_viewer_locked(locked: bool) -> void:
	_viewer_locked = locked
	measure_btn.disabled = locked
	reselect_btn.disabled = not locked
	report_btn.disabled = not locked
	include_box.disabled = locked
	if _viewer_sel >= 0 and _viewer_sel < _viewer_plates.size():
		_select_plate(_viewer_sel, big_plate.texture)


func set_viewer_note(bb: String) -> void:
	viewer_note.text = bb


func close_viewer() -> void:
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
		+ "兩年後，在赤道的雲層底下，你只有 302 秒。[/center]\n\n"
		+ "[color=#b8ad98]WASD 移動 · 滑鼠／方向鍵 觀看 · Shift 跑 · E 互動 · Tab 對話紀錄\n"
		+ "全食時：空白鍵／E／左鍵 開始與停 · Esc 暫停[/color]\n\n"
		+ "[color=#8f8676][font_size=15]Dyson、Eddington、Cottingham 與 1919 年的日食遠征為史實；你、Kit、Ashby 先生、劍橋的那一夜與所有對白為虛構（姓名暫定），場景為推測重建。[/font_size][/color]")
	v.add_child(body)
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 20)
	v.add_child(hb)
	prologue_btn = _button("序章　劍橋，1917")
	prologue_btn.pressed.connect(func(): prologue_pressed.emit())
	hb.add_child(prologue_btn)
	start_btn = _button("普林西比，1919")
	start_btn.pressed.connect(func(): start_pressed.emit())
	hb.add_child(start_btn)
	var q := _button("　離開　")
	q.pressed.connect(func(): quit_pressed.emit())
	hb.add_child(q)


func hide_title() -> void:
	title_panel.visible = false


func _build_ending(root: Control) -> void:
	ending_panel = ColorRect.new()
	(ending_panel as ColorRect).color = Color(0.03, 0.03, 0.04, 0.93)
	ending_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	ending_panel.visible = false
	root.add_child(ending_panel)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 200
	scroll.offset_right = -200
	scroll.offset_top = 50
	scroll.offset_bottom = -110
	ending_panel.add_child(scroll)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 12)
	scroll.add_child(v)
	ending_title = _label("", 44, PAPER)
	ending_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(ending_title)
	ending_text = _rich(19)
	ending_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(ending_text)
	ending_history_toggle = _button("歷史上發生了什麼")
	ending_history_toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ending_history_toggle.pressed.connect(_toggle_ending_history)
	v.add_child(ending_history_toggle)
	ending_history = _rich(17)
	ending_history.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ending_history.visible = false
	v.add_child(ending_history)
	var hb := HBoxContainer.new()
	hb.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hb.position = Vector2(-430, -90)
	hb.custom_minimum_size = Vector2(860, 0)
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 16)
	ending_panel.add_child(hb)
	var same := _button("同一片雲，再試一次")
	same.pressed.connect(func(): restart_pressed.emit(true))
	hb.add_child(same)
	var fresh := _button("新的天空")
	fresh.pressed.connect(func(): restart_pressed.emit(false))
	hb.add_child(fresh)
	var q := _button("離開")
	q.pressed.connect(func(): quit_pressed.emit())
	hb.add_child(q)


func show_ending(title: String, bb: String, history_bb := "") -> void:
	ending_title.text = title
	ending_text.text = bb
	ending_history.text = history_bb
	ending_history.visible = false
	ending_history_toggle.visible = not history_bb.is_empty()
	ending_history_toggle.text = "歷史上發生了什麼"
	ending_panel.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


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
	var v := VBoxContainer.new()
	v.set_anchors_preset(Control.PRESET_CENTER)
	v.position = Vector2(-150, -120)
	v.custom_minimum_size = Vector2(300, 0)
	v.add_theme_constant_override("separation", 12)
	pause_panel.add_child(v)
	var t := _label("暫停", 36)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)
	var r := _button("繼續")
	r.pressed.connect(func(): toggle_pause())
	v.add_child(r)
	var music_ready := Time.get_ticks_usec()
	ScorePlayer.load_settings()
	var music := _button("音樂：開" if ScorePlayer.music_enabled() else "音樂：關")
	music.pressed.connect(func():
		ScorePlayer.set_music_enabled(not ScorePlayer.music_enabled())
		music.text = "音樂：開" if ScorePlayer.music_enabled() else "音樂：關")
	v.add_child(music)
	music_ready_usec = Time.get_ticks_usec() - music_ready
	var rs := _button("從頭開始")
	rs.pressed.connect(func():
		get_tree().paused = false
		restart_pressed.emit(true))
	v.add_child(rs)
	var q := _button("離開遊戲")
	q.pressed.connect(func(): quit_pressed.emit())
	v.add_child(q)


func toggle_pause() -> void:
	var p := not get_tree().paused
	get_tree().paused = p
	pause_panel.visible = p
	if p:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
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
	v.add_child(_label("對話紀錄　［Tab 關閉］", 28, ACCENT))
	log_text = RichTextLabel.new()
	log_text.bbcode_enabled = true
	log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	log_text.add_theme_color_override("default_color", PAPER)
	log_text.scroll_following = true
	v.add_child(log_text)
	var close := _button("返回　Tab")
	close.pressed.connect(toggle_log)
	v.add_child(close)


func log_open() -> bool:
	return log_panel.visible


func toggle_log() -> void:
	log_panel.visible = not log_panel.visible
	# The dialogue panel's bottom edge sits below the log; its input hint is inert while reading.
	hint_label.visible = not log_panel.visible
	if log_panel.visible:
		_log_mouse_mode = Input.mouse_mode
		log_text.text = "\n\n".join(history)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = _log_mouse_mode
	log_toggled.emit(log_panel.visible)


func _input(event: InputEvent) -> void:
	if log_panel.visible and pause_enabled and event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_TAB and not get_tree().paused:
		toggle_log()
		get_viewport().set_input_as_handled()
	elif log_panel.visible and event is InputEventKey:
		get_viewport().set_input_as_handled()
