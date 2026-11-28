extends Node
## Sundy setup and drive rehearsals, with the paired cables played after the coda.

const Content := preload("res://scripts/cambridge/content_sundy.gd")
const Madeira := preload("res://scripts/cambridge/content_madeira.gd")
const Paper := preload("res://scripts/cambridge/interlude_paper.gd")
const Ink := preload("res://scripts/cambridge/sundy_ink.gd")
const RouteInk := preload("res://scripts/cambridge/madeira_ink.gd")
const Plate := preload("res://scripts/cambridge/sundy_plate.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")
const Settings := preload("res://scripts/settings.gd")
const KIT_PRINT := "res://assets/portraits/kit_neutral.jpg"

const SETUP := [
	["S02", ["S03", "S04", "S05"], "S06", ""],
	["S07", ["S08", "S02", "S09"], "M09", "map", 2],
	["S07", ["S08", "S02", "S09", "S10", "S11"], "M09", "map", 3],
	["S07", ["S08", "S02", "S09", "S10", "S11", "S12"], "S13", "map", 4],
	["S14", ["S15", "S16", "S17"], "M09", ""],
	["S14", ["S18", "S19"], "S20", "delivery"],
	["S21", ["S03", "S22", "S23", "S24", "S25"], "S26", "delivery"],
	["S27", ["S28"], "M09", ""],
]
const PAIRS := [
	{"label": "S57", "shift": 0.07, "clear": [0, 1, 2, 3], "marks": [0, 1, 2, 3],
		"judgment": "S64", "reason": "S67", "log": "S70", "next": "S73"},
	{"label": "S58", "shift": 0.01, "clear": [0, 1, 2, 3], "marks": [0, 1, 2, 3],
		"judgment": "S63", "reason": "S68", "log": "S71", "next": "S74"},
	{"label": "S59", "shift": 0.01, "clear": [0, 2], "marks": [0, -1, 2, -1],
		"judgment": "S65", "reason": "S69", "log": "S72", "next": "S75"},
]
const CABLES := {"I3-04": "Through cloud, hopeful", "I3-06": "Eclipse splendid. Crommelin"}

var paper: Control
var page_id := ""
var plate: Control
var accepted_log: Array[String] = []
var _text: Dictionary
var _ui: CanvasLayer
var _story: Node
var _scroll: ScrollContainer
var _layout: VBoxContainer
var _switch: Button
var _rings: Array[Button] = []
var _judgments: Array[Button] = []
var _blank: Button
var _exposure: Label
var _feedback: Label
var _seen_b := false
var _accepted := false


func _open_paper(ui: CanvasLayer, parent: Node) -> ColorRect:
	_text = Content.strings()
	_story = get_node("/root/Story")
	var madeira := Madeira.strings()
	_text["M09"] = madeira.M09
	_text["M50"] = madeira.M50
	_text["M85"] = madeira.M85
	_ui = ui
	var backdrop := ColorRect.new()
	backdrop.color = Color("30271d")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(backdrop)
	paper = Paper.new()
	paper.theme = _ui.theme_res
	backdrop.add_child(paper)
	return backdrop


func play(director: Node) -> void:
	var backdrop := _open_paper(director.ui, director.checklist.get_parent())
	page_id = "plate"
	paper.begin_plate(preload("res://assets/journey/santo-antonio-v1.png"), _text.S02)
	await _ui.fade_to(0.0, _motion(0.7)).finished
	await _next("M09")
	_show("S01")
	await _next("M09")
	for setup in SETUP:
		if setup[1][0] == "S15":
			page_id = "plate"
			paper.begin_plate(preload("res://assets/journey/forest-road-v1.png"), L.t("普林西比林間小徑・1919 年 4 月 28 日"))
			await _next("M09")
		_show(setup[0])
		var image := _picture(setup[3]) if not setup[3].is_empty() else null
		if setup.size() == 5:
			image.steps = setup[4]
		for id in setup[1]:
			if id == "S24":
				paper.rule(paper.body)
			_line(paper.body, id, 18 if id in ["S03", "S08", "S24"] else 23)
		if setup[3] == "delivery":
			image.progress = 1.0
		await _next(setup[2])
	await _station()
	_show("S85")
	_lines(paper.body, ["S86", "S87", "S88"])
	paper.rule(paper.body)
	_line(paper.body, "S92", 19)
	await _next("M09")
	_story.sundy_letter_read = true
	await _remember(Cast.MENTOR, ["S47"])
	for pair in PAIRS:
		if pair.label == "S59":
			_show("S59")
			var cloud := _picture("night", 245)
			cloud.progress = float(Settings.reduced_motion)
			if not Settings.reduced_motion:
				await cloud.create_tween().tween_property(cloud, "progress", 1.0, 1.3).finished
			await _next("M09")
		await _rehearse(pair)
	await _sky_page()
	await _ui.fade_to(1.0, _motion(0.7)).finished
	backdrop.queue_free()


func _motion(seconds: float) -> float:
	return 0.0 if Settings.reduced_motion else seconds


func _show(id: String, heading := "") -> void:
	page_id = id
	paper.begin(true)
	_scroll = paper.body.get_parent()
	_layout = _scroll.get_parent()
	paper.label(_layout, _text[id] if heading.is_empty() else heading, 32)
	_layout.move_child(_layout.get_child(-1), 0)


func _line(parent: Container, id: String, font_size := 23) -> void:
	paper.label(parent, _text[id], font_size)


func _lines(parent: Container, ids: Array) -> void:
	for id in ids:
		_line(parent, id)


func _picture(subject: String, height := 165) -> Control:
	var picture := Ink.new()
	picture.subject = subject
	picture.custom_minimum_size.y = height
	picture.clip_contents = true
	paper.body.add_child(picture)
	return picture


func _next(id: String) -> void:
	paper.advance(_text[id])
	await paper.action


func _station() -> void:
	_show("S29")
	Ink.station_print(paper.body)
	_picture("cutaway", 142)
	_lines(paper.body, ["S30", "S31", "S32", "S33", "S34"])
	await _next("S35")

	_show("S36")
	var records: Container = paper.columns(paper.body)
	for ids in [["S37", "S38"], ["S39", "S40"]]:
		var record: VBoxContainer = paper.column(records)
		_line(record, ids[0], 25)
		paper.rule(record)
		_line(record, ids[1])
	_line(paper.body, "S41", 18)
	_line(paper.body, "S42")
	_picture("night", 145)
	await _next("S43")


func _remember(speaker: String, ids: Array) -> void:
	_show("S46")
	_picture("night", 245)
	var lines: Array = []
	var portrait := load(KIT_PRINT) as Texture2D if speaker == Cast.KIT else null
	for id in ids:
		lines.append({"s": speaker, "t": _text[id], "fictional_portrait": portrait})
	_ui.dialogue_sheet = _layout.get_parent()
	_ui.play(lines)
	await _ui.dialogue_done
	_ui.dialogue_sheet = null


func _rehearse(pair: Dictionary) -> void:
	_show("S44")
	page_id = pair.label
	_line(_layout, "S45", 18)
	_layout.move_child(_layout.get_child(-1), 1)

	var row: HBoxContainer = paper.columns(_layout)
	_layout.move_child(row, 2)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_scroll.reparent(row)
	_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	plate = Plate.new()
	plate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(plate)
	row.move_child(plate, 0)
	plate.prepare(pair.shift, pair.clear, paper)
	plate.marks.assign([-2, -2, -2, -2])
	_seen_b = false
	_accepted = false

	_line(paper.body, pair.label, 25)
	_line(paper.body, "S50", 23)
	_exposure = paper.body.get_child(-1)
	_switch = paper.button(paper.body, _text.S52, "switch")
	_line(paper.body, "S48", 20)
	_line(paper.body, "S49", 18)
	_line(paper.body, "S53", 20)
	var rings: HBoxContainer = paper.columns(paper.body)
	rings.add_theme_constant_override("separation", 4)
	_rings.clear()
	for i in plate.RINGS.size():
		var ring: Button = paper.button(rings, _text.S54 % (i + 1), "ring:%d" % i, 17)
		ring.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rings.append(ring)
	_blank = paper.button(paper.body, _text.S55, "blank", 18)
	_blank.hide()
	_line(paper.body, "S56", 20)
	_line(paper.body, "S60", 20)
	_judgments.clear()
	var choices: HBoxContainer = paper.columns(paper.body)
	choices.add_theme_constant_override("separation", 5)
	for id in ["S63", "S64", "S65"]:
		var choice: Button = paper.button(choices, _text[id], id, 18)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_judgments.append(choice)
	paper.label(paper.body, "", 20)
	_feedback = paper.body.get_child(-1)
	paper.rule(paper.body)
	var log := VBoxContainer.new()
	log.add_theme_constant_override("separation", 10)
	paper.body.add_child(log)
	_line(log, "S61", 23)
	for id in accepted_log:
		_line(log, id, 20)
	_line(log, "S62", 19)
	_update_controls()
	_switch.grab_focus()

	while not _accepted:
		var action: String = await paper.action
		match action.get_slice(":", 0):
			"switch":
				plate.exposure_b = not plate.exposure_b
				_seen_b = _seen_b or plate.exposure_b
				_exposure.text = _text.S51 if plate.exposure_b else _text.S50
			"ring":
				plate.selected = int(action.get_slice(":", 1))
				_update_controls()
				plate.targets.values()[0].grab_focus()
				continue
			"centre", "blank":
				var ring: int = plate.selected
				plate.marks[ring] = -1 if action == "blank" else int(action.get_slice(":", 1))
				plate.selected = -1
				_feedback.text = ""
				_update_controls()
				if not plate.marks.has(-2):
					_judgments[0].grab_focus()
				else:
					_rings[plate.marks.find(-2)].grab_focus()
				continue
			"S63", "S64", "S65":
				if plate.marks != pair.marks:
					_feedback.text = _text.S66
				else:
					_feedback.text = _text[pair.reason]
					if action == pair.judgment:
						accepted_log.append(pair.log)
						_accepted = true
						_line(log, pair.log, 20)
						log.move_child(log.get_child(-1), log.get_child_count() - 2)
						paper.body.move_child(_feedback, _exposure.get_index() + 1)
						paper.body.move_child(log, _feedback.get_index() + 1)
						_scroll.set_deferred("scroll_vertical", 0)
						continue
				_scroll.ensure_control_visible.call_deferred(_feedback)
		_update_controls()

	_update_controls()
	paper.advance(_text[pair.next])
	while await paper.action == "switch":
		plate.exposure_b = not plate.exposure_b
		_exposure.text = _text.S51 if plate.exposure_b else _text.S50
		plate.queue_redraw()
	plate = null


func _update_controls() -> void:
	for i in _rings.size():
		var ring := _rings[i]
		var mark: int = plate.marks[i]
		ring.disabled = _accepted or not plate.exposure_b
		ring.text = _text.S54 % (i + 1)
		ring.tooltip_text = _text.S55 if mark == -1 else ""
		if mark >= -1:
			ring.text += "  " + ("—" if mark == -1 else "✓")
	var marking: bool = plate.exposure_b and plate.selected >= 0 and not _accepted
	plate.show_targets(marking)
	_blank.visible = marking
	for judgment in _judgments:
		judgment.disabled = _accepted or not _seen_b or plate.marks.has(-2)


func _input(event: InputEvent) -> void:
	if not is_instance_valid(paper) or get_tree().paused or _ui.blocks_world_input():
		return
	var down := event.is_action_pressed("ui_down", true)
	if not down and not event.is_action_pressed("ui_up", true):
		return
	var focused := get_viewport().gui_get_focus_owner()
	var focus_order: Array = []
	if is_instance_valid(plate) and not _accepted:
		if focused in plate.targets.values() or focused == _blank:
			focus_order = plate.targets.values() + [_blank]
		elif focused != _scroll.get_v_scroll_bar():
			focus_order = [_switch] + _rings + _judgments
			focus_order = focus_order.filter(func(control: Button): return not control.disabled)
	var index := focus_order.find(focused)
	if index >= 0 and index + (1 if down else -1) in range(focus_order.size()):
		focus_order[index + (1 if down else -1)].grab_focus()
	else:
		_scroll.scroll_vertical += 80 if down else -80
	get_viewport().set_input_as_handled()


func _sky_page() -> void:
	_show("S77")
	# The clear field and the 28 May daylight use the same horizon and apparatus.
	_layout.get_child(0).hide()
	_picture("night", 260)
	await _next("S76")
	_show("S77")
	_picture("cloud", 260)
	await _next("S78")
	await _remember(Cast.KIT, ["S79", "S80"])
	_show("S81")
	var spread: HBoxContainer = paper.columns(paper.body)
	var earlier: VBoxContainer = paper.column(spread)
	var eclipse: VBoxContainer = paper.column(spread)
	var warm: bool = _story.bond_tone == "warm"
	_line(earlier, "S93", 19)
	_lines(earlier, ["S82" if warm else "S83", "S89", "S90" if warm else "S91"])
	paper.rule(earlier)
	_line(earlier, "M50", 19)
	paper.label(eclipse, _text.M85, 19, true)
	Ink.workbook_print(eclipse, true)
	await _next("S84")


func play_cables(ui: CanvasLayer, opens_sobral: bool) -> void:
	var parent: Control = ui.pause_panel.get_parent()
	var backdrop := _open_paper(ui, parent)
	parent.move_child(backdrop, ui.pause_panel.get_index())
	_show("I3-01")
	_line(paper.body, "I3-02")
	var narrow := get_window().size.x < 1440
	var telegrams: BoxContainer = VBoxContainer.new() if narrow else HBoxContainer.new()
	telegrams.add_theme_constant_override("separation", 24)
	paper.body.add_child(telegrams)
	for ids in [["I3-03", "I3-04"], ["I3-05", "I3-06"]]:
		var cable: VBoxContainer = paper.column(telegrams)
		paper.rule(cable)
		_line(cable, ids[0], 19)
		if L.current() == "en":
			_line(cable, ids[1], 28)
		else:
			paper.label(cable, CABLES[ids[1]], 28)
			_line(cable, ids[1], 22)
	await _ui.fade_to(0.0, _motion(0.7)).finished
	await _next("M09")
	_show("I3-07")
	_lines(paper.body, ["I3-08", "I3-09"])
	var route := RouteInk.new()
	route.subject = "sobral"
	route.steps = 5
	route.custom_minimum_size.y = 130
	paper.body.add_child(route)
	_lines(paper.body, ["I3-10", "I3-11", "I3-12", "I3-13"])
	await _next("M09")
	_show("I3-15", L.t("檔案剪報・據史料編成"))
	_lines(paper.body, ["I3-15", "I3-16", "I3-17"])
	if opens_sobral:
		var sobral := preload("res://scripts/cambridge/content_sobral.gd").strings()
		paper.advance(sobral.B01)
		await paper.action
	else:
		await _next("I3-14")
	await _ui.fade_to(1.0, _motion(0.7)).finished
	backdrop.queue_free()
