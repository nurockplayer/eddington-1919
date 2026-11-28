extends Control
## The assistant's copy of the joint meeting. The run and the published rows are read-only.

signal completed

const Content := preload("res://scripts/cambridge/content_london.gd")
const October := preload("res://scripts/cambridge/content_epilogue.gd")
const Tribunal := preload("res://scripts/cambridge/content_tribunal.gd")
const Predictions := preload("res://scripts/content.gd")
const Paper := preload("res://scripts/cambridge/interlude_paper.gd")
const Chart := preload("res://scripts/cambridge/london_chart.gd")
const Portrait := preload("res://scripts/cambridge/dialogue_portrait.gd")
const Report := preload("res://scripts/cambridge/report_sheet.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")

var paper: Control
var historical_chart: Control
var page_id := ""
var committed_line := ""
var _text := Content.strings()
var _speakers: Dictionary
var _notes := {}
var _step := 0
var _selected := ""
var _preview := ""
var _prediction_pick: int


func open(run: Dictionary, prediction: Dictionary, bond_tone: String) -> void:
	var case_id := October.ledger_case(run)
	var combined: Dictionary = run.combined
	_prediction_pick = int(prediction.get("pick", -1))
	_text.L05 %= Predictions.bet_pick_text(_prediction_pick)
	_text.bet %= Predictions.bet_pick_text(int(run.bet_oct))
	_text.L06 %= L.t(str(run.final_reason_text))
	_text.weight %= October.weight()[0].choices[run.astro_weight]
	_text.reaction = _text[Content.REACTIONS[case_id]]
	_text.personal = _text.L16 % [combined.value, combined.sigma] if combined.n > 0 else _text.L17
	_text.tone = _text.L91 if bond_tone == "close" else _text.L90
	if case_id != "conceded":
		_text.reason = _text.evidence
	_speakers = {"kit": _text.kit, "ashby": L.t(Cast.MENTOR), "assistant": L.t(Cast.YOU),
		"rook": Tribunal.strings().T76}

	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop := ColorRect.new()
	backdrop.color = Color("30271d")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(backdrop)
	paper = Paper.new()
	add_child(paper)
	paper.action.connect(_action)
	_show_page()


func refresh_fonts() -> void:
	if is_instance_valid(historical_chart):
		historical_chart.refresh_fonts()


func _show_page() -> void:
	var page: Dictionary = Content.PAGES[_step]
	page_id = page.id
	paper.begin(page.has("chart") or page_id == "proceedings")
	var scroll: ScrollContainer = paper.body.get_parent()
	var layout: VBoxContainer = scroll.get_parent()
	if page.has("chart"):
		_show_chart(layout, scroll, page.chart)
	elif page_id == "proceedings":
		_show_title_plate()
	else:
		paper.label(layout, _text.L01, 32)
		layout.move_child(layout.get_child(-1), 0)
	_show_lines(page.lines)
	if page.has("choices") and not _notes.has(page_id):
		_show_choices(page, scroll)
	else:
		paper.advance(_text[page.get("advance", "L14")])
	if page_id == "principal":
		var advance: Button = paper.actions.get_child(0)
		advance.disabled = true
		historical_chart.beat_started.connect(_show_report)
		historical_chart.arrived.connect(func():
			advance.disabled = false
			if get_viewport().gui_get_focus_owner() == null:
				advance.grab_focus())
	if _notes.has(page_id):
		_show_lines(_notes[page_id])
	for key in _notes:
		if key == page_id:
			continue
		paper.rule(paper.body)
		_show_lines(["L42" if key == "precision" else "L64"])
		_show_lines(_notes[key])


func _show_title_plate() -> void:
	var separator := " · " if _text.L18.contains(" · ") else "・"
	var split_at: int = _text.L18.rfind(separator)
	paper.label(paper.body, _text.L01, 20, true)
	paper.label(paper.body, _text.L18.left(split_at), 54, true)
	paper.label(paper.body, _text.L18.substr(split_at + separator.length()), 38, true)
	paper.rule(paper.body)
	paper.label(paper.body, _text.L19, 27, true)
	paper.label(paper.body, _text.L20, 24, true)
	paper.label(paper.body, _text.L21, 20, true)


func _show_chart(layout: VBoxContainer, scroll: ScrollContainer, row_count: int) -> void:
	var rows := [
		{"label": _text.L30, "value": 1.98, "sigma": 0.12},
		{"label": _text.L31, "value": 1.61, "sigma": 0.30},
	]
	if row_count == 3:
		rows.append({"label": _text.L50, "value": 0.93, "other_value": 1.52})
	historical_chart = Chart.new()
	historical_chart.rows = rows
	historical_chart.labels = _text
	historical_chart.pick = _prediction_pick
	historical_chart.custom_minimum_size.y = 450 if page_id == "principal" else 304
	layout.add_child(historical_chart)
	layout.move_child(historical_chart, scroll.get_index())


func _show_report(beat: int) -> void:
	if beat == 1:
		_show_lines(["L22"])
		return
	var row: HBoxContainer = paper.columns(paper.body)
	var portrait := Portrait.new()
	row.add_child(portrait)
	portrait.setup(Report.INK)
	portrait.image.custom_minimum_size = Vector2(76, 94)
	portrait.disclosure.hide()
	portrait.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	portrait.prints_override[Cast.EDDINGTON] = "res://assets/portraits/eddington_engraving.jpg"
	portrait.show_entry({"s": Cast.EDDINGTON})
	paper.label(paper.column(row), _text.L23, 24)


func _show_lines(ids: Array) -> void:
	for id in ids:
		if Content.SPEAKERS.has(id):
			paper.label(paper.body, _speakers[Content.SPEAKERS[id]], 16)
		paper.label(paper.body, committed_line if id == "line" else _text[id], 24)


func _show_choices(page: Dictionary, scroll: ScrollContainer) -> void:
	if page_id == "reply" and not _selected.is_empty():
		_show_lines(["L81"])
		paper.label(paper.body, _preview, 24)
		paper.actions.show()
		paper.button(paper.actions, _text.L80, "revise")
		paper.button(paper.actions, _text.L79, "commit").grab_focus()
		scroll.ensure_control_visible.call_deferred(paper.body.get_child(-1))
		return
	var first: Button
	for id in page.choices:
		var choice: Button = paper.button(paper.body, _text[id], id)
		if first == null:
			first = choice
		if id == _selected:
			choice.toggle_mode = true
			choice.set_pressed_no_signal(true)
			paper.label(paper.body, _text[page.choices[id][0]], 22)
			scroll.ensure_control_visible.call_deferred(paper.body.get_child(-1))
	if _selected.is_empty():
		first.grab_focus()
	else:
		paper.actions.show()
		paper.button(paper.actions, _text.L53, "commit").grab_focus()


func _action(id: String) -> void:
	match id:
		"advance":
			if _step == Content.PAGES.size() - 1:
				completed.emit()
				return
			_step += 1
		"revise":
			_selected = ""
		"commit":
			if page_id == "reply":
				committed_line = _preview
				_step += 1
			else:
				_notes[page_id] = Content.PAGES[_step].choices[_selected]
			_selected = ""
		_:
			_selected = id
			if page_id == "reply":
				_preview = _text[id]
	_show_page()
