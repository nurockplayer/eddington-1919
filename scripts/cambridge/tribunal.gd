extends Node
## Runs the document-led chapter in the existing Cambridge scene.

const Content := preload("res://scripts/cambridge/content_tribunal.gd")
const Paper := preload("res://scripts/cambridge/interlude_paper.gd")
const Settings := preload("res://scripts/settings.gd")

var paper: Control
var page_id := ""
var filed := {}
var _text: Dictionary
var _director: Node


func play(director: Node, prediction: Dictionary) -> void:
	_director = director
	_text = Content.strings()
	_text.T72 = Content.ledger(_text, prediction)
	paper = Paper.new()
	paper.theme = director.ui.theme_res
	director.report_sheet.get_parent().add_child(paper)
	director.ui.hud.hide()
	director.player.position = Vector3(0.0, 0.0, 1.95)
	_bench()
	page_id = "plate"
	paper.begin_plate(preload("res://assets/journey/cambridge-observatory-v2.png"), L.t("劍橋天文台"))
	await _director.ui.fade_to(0.0, 0.0 if Settings.reduced_motion else 0.8).finished
	await _prompt("T22")
	var extracts: Array = []
	for beat in Content.BEATS:
		if beat.has("speaker"):
			await _dialogue(beat)
		elif beat.has("packet"):
			await _packet(extracts)
			extracts.clear()
		elif beat.has("extracts"):
			await _read_extracts(beat)
			extracts.append_array(beat.extracts)
		else:
			await _read_page(beat)
	await _armistice()
	paper.queue_free()


func _bench() -> void:
	_director.player.look_at_point(Vector3(-1.05, 0.85, 0.0))


func _lines(ids: Array) -> Array:
	return ids.map(func(id): return _text[id])


func _show_page(id: String, wide := false) -> void:
	page_id = id
	_bench()
	paper.begin(wide)
	_director._overlay_sound("flip")


func _prompt(action_id: String) -> void:
	paper.advance(_text[action_id])
	await paper.action
	paper.hide()


func _dialogue(beat: Dictionary) -> void:
	page_id = beat.lines[0]
	if page_id == "T78":
		_director.world.mentor.position = Vector3(-1.5, 0.0, -0.95)
		_director.world.mentor.show()
	if beat.has("titles"):
		paper.begin(true, true)
		var row: HBoxContainer = paper.columns(paper.body)
		for title in _lines(beat.titles):
			paper.label(paper.column(row), title, 28)
	var speaker: String = _text.T76 if beat.speaker == "T76" else beat.speaker
	var lines: Array = _lines(beat.lines).map(func(line): return {"s": speaker, "t": line})
	_director._say(lines, "tribunal")
	await _director.ui.dialogue_done
	if page_id == "T78":
		Story.tribunal_packet_seen = true
	paper.hide()


func _read_page(beat: Dictionary) -> void:
	var id: String = beat.paper[0]
	if beat.has("open"):
		_show_page(beat.open)
		paper.label(paper.body, _text[id], 32, true)
		await _prompt(beat.open)
	_show_page(id, id == "T01")
	if id == "T01":
		paper.headpiece()
	var lines := _lines(beat.paper)
	var title: String = lines.pop_front()
	var source := ""
	if beat.has("quote"):
		paper.label(paper.body, _text.T27, 18)
		paper.label(paper.body, _text.T28, 18)
		if L.current() != "en":
			source = beat.quote
	elif beat.has("source"):
		paper.label(paper.body, _text.T08, 18)
		source = _text[beat.source]
	if id == "T72":
		lines.push_front(title)
		title = ""
	paper.section(paper.body, title, lines, source)
	if id == "T72":
		paper.tailpiece()
	await _prompt("T22")


func _extract(parent: Container, card: String, first_part_only := false) -> void:
	var data: Dictionary = Content.EXTRACTS[card]
	var lines := _lines(data.lines)
	var title: String = lines.pop_front()
	if first_part_only:
		lines.pop_back()
	paper.section(parent, title, lines, _text[data.source])


func _read_extracts(beat: Dictionary) -> void:
	var split: bool = beat.extracts.size() > 1
	var first_part: bool = beat.get("last_line_separate", false)
	var id: String = Content.EXTRACTS[beat.extracts[0]].lines[0]
	_show_page(id, split)
	paper.label(paper.body, _text.T08, 18)
	var row: HBoxContainer = paper.columns(paper.body)
	for card in beat.extracts:
		_extract(paper.column(row), card, first_part)
	await _prompt("T22")
	if first_part:
		_show_page("T54")
		paper.label(paper.body, _text.T08, 18)
		paper.section(paper.body, _text[id], [_text.T54], _text.L)
		await _prompt("T22")


func _packet(extracts: Array) -> void:
	var selected: String = extracts[0]
	var filed_feedback := false
	while true:
		var source := _show_packet(extracts, selected, filed_feedback)
		var action: String = await paper.action
		while action in Content.EXTRACTS:
			selected = action
			source.text = _text[Content.EXTRACTS[selected].source]
			action = await paper.action
		paper.hide()
		if action == "close":
			return
		var heading := await _choose_heading(selected)
		filed_feedback = false
		if heading.is_empty():
			continue
		var card: Dictionary = Content.EXTRACTS[selected]
		if heading == card.heading:
			filed[selected] = heading
			filed_feedback = true
		else:
			await _dialogue({"speaker": Content.Cast.KIT, "lines": [card.hint]})


func _show_packet(extracts: Array, selected: String, filed_feedback: bool) -> Label:
	_show_page("packet", true)
	paper.label(paper.body, _text.T07, 32, true)
	paper.label(paper.body, _text.T56, 22, true)
	var tray := GridContainer.new()
	tray.columns = 3
	tray.add_theme_constant_override("h_separation", 10)
	tray.add_theme_constant_override("v_separation", 8)
	paper.body.add_child(tray)
	var buttons := ButtonGroup.new()
	var card_buttons := {}
	for card in extracts:
		if not filed.has(card):
			card_buttons[card] = _card_button(tray, buttons, card, selected)
	paper.rule(paper.body)
	var row: HBoxContainer = paper.columns(paper.body)
	for heading in Content.HEADINGS:
		var slot: VBoxContainer = paper.column(row)
		paper.label(slot, _text[heading], 23)
		for card in filed:
			if filed[card] == heading:
				card_buttons[card] = _card_button(slot, buttons, card, selected)
	if filed_feedback:
		paper.label(paper.body, _text.T60, 21, true)
	# Keep the citation visible while the tray scrolls.
	var layout: Container = paper.actions.get_parent()
	paper.label(layout, _text[Content.EXTRACTS[selected].source], 18, true)
	var source: Label = layout.get_child(-1)
	layout.move_child(source, paper.actions.get_index())
	paper.actions.show()
	paper.button(paper.actions, _text.T57, "read")
	if extracts.all(func(card): return filed.has(card)):
		paper.button(paper.actions, _text.T70, "close")
	card_buttons[selected].grab_focus()
	return source


func _card_button(parent: Container, group: ButtonGroup, card: String, selected: String) -> Button:
	var control: Button = paper.button(parent, _text[Content.EXTRACTS[card].lines[0]], card, 19)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	control.toggle_mode = true
	control.button_group = group
	control.set_pressed_no_signal(card == selected)
	return control


func _choose_heading(card: String) -> String:
	_show_page(card)
	paper.label(paper.body, _text.T08, 18)
	_extract(paper.body, card)
	paper.actions.show()
	var back: Button = paper.button(paper.actions, _text.T58, "back")
	if filed.has(card):
		back.grab_focus()
		await paper.action
		paper.hide()
		return ""
	paper.rule(paper.body)
	var headings: HBoxContainer = paper.columns(paper.body)
	var group := ButtonGroup.new()
	var selected := ""
	var choices: Array[Button] = []
	for heading in Content.HEADINGS:
		var choice: Button = paper.button(headings, _text[heading], heading)
		choice.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choice.toggle_mode = true
		choice.button_group = group
		choices.append(choice)
	choices[0].grab_focus()
	var file: Button = paper.button(paper.actions, _text.T59, "file")
	file.disabled = true
	while true:
		var action: String = await paper.action
		match action:
			"back":
				paper.hide()
				return ""
			"file":
				paper.hide()
				return selected
			_:
				selected = action
				file.disabled = false
	return ""


func _armistice() -> void:
	for i in Content.ARMISTICE.size():
		_show_page("I01" if i == 0 else "I08")
		paper.label(paper.body, _text.I03, 18)
		paper.label(paper.body, _text.I01, 40)
		paper.label(paper.body, _text.I02, 23)
		paper.rule(paper.body)
		for j in Content.ARMISTICE[i].size():
			var lines := _lines(Content.ARMISTICE[i][j])
			if j == 0:
				paper.label(paper.body, lines.pop_front(), 25)
			paper.section(paper.body, "", lines, _text[Content.ARMISTICE_SOURCES[i][j]])
		await _prompt("T22" if i == 0 else "I12")
