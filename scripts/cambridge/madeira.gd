extends Node
## The Madeira papers and the onward passage, played within the M2 handoff.

const Content := preload("res://scripts/cambridge/content_madeira.gd")
const Paper := preload("res://scripts/cambridge/interlude_paper.gd")
const Ink := preload("res://scripts/cambridge/madeira_ink.gd")
const Checklist := preload("res://scripts/cambridge/departure_checklist.gd")
const Cast := preload("res://scripts/cambridge/cast.gd")
const Settings := preload("res://scripts/settings.gd")
const Kit := preload("res://assets/models/kit.glb")

var paper: Control
var page_id := ""
var filed := {}
var selected := ""
var _last_filed := ""
var _routing := false
var _director: Node
var _story: Node
var _text: Dictionary


func play(director: Node) -> void:
	_director = director
	_story = get_node("/root/Story")
	_text = Content.strings()
	_director.ui.cambridge_portraits = true
	var backdrop := ColorRect.new()
	backdrop.color = Color(0.11, 0.085, 0.063)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_director.checklist.get_parent().add_child(backdrop)
	paper = Paper.new()
	paper.theme = _director.ui.theme_res
	backdrop.add_child(paper)
	await _arrival()
	await _worktable()
	await _dockside()
	_story.departure_done = true
	_story.from_prologue = true
	await _passage()
	await _director.ui.fade_to(1.0, _motion(0.7)).finished
	backdrop.queue_free()


func _motion(seconds: float) -> float:
	return 0.0 if Settings.reduced_motion else seconds


func _show(id: String, label_id := "") -> void:
	page_id = id
	paper.begin(true)
	if not label_id.is_empty():
		paper.heading(_text[label_id], 18)
	paper.heading(_text[id], 36)


func _line(parent: Container, id: String, size := 23) -> void:
	paper.label(parent, _text[id], size)


func _archive(parent: Container, ids: Array) -> void:
	paper.rule(parent)
	paper.label(parent, L.t("檔案剪報・據史料編成"), 18)
	for id in ids:
		_line(parent, id)


func _quote(parent: Container, id: String) -> void:
	_line(parent, id)
	if L.current() != "en":
		paper.label(parent, Content.QUOTES[id], 19)


func _ink(parent: Container, subject: String, steps := 0, trace := false, height := 145) -> Control:
	var image := Ink.new()
	image.subject = subject
	image.steps = steps
	image.custom_minimum_size.y = height
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(image)
	if trace and not Settings.reduced_motion:
		image.last_leg = 0.0
		image.create_tween().tween_property(image, "last_leg", 1.0, 0.65)
	return image


func _advance(id := "M09", reveal_tail := false) -> void:
	paper.advance(_text[id])
	if reveal_tail:
		var scroll: ScrollContainer = paper.body.get_parent()
		scroll.ensure_control_visible.call_deferred(paper.body.get_child(-1))
	await paper.action
	var footer: Container = paper.actions
	for button in footer.get_children():
		footer.remove_child(button)
		button.queue_free()
	footer.hide()


func _arrival() -> void:
	_show("M01")
	await _director.ui.fade_to(0.0, _motion(0.7)).finished
	await _advance()
	for i in Content.ARRIVAL.size():
		var stop: Array = Content.ARRIVAL[i]
		_show("M01", "M02")
		page_id = stop[0]
		_ink(paper.body, "arrival", i + 1, i > 0)
		_line(paper.body, "M03", 18)
		for j in range(i + 1):
			_line(paper.body, Content.ARRIVAL[j][0])
		await _advance()
		for j in stop[1].size():
			_show("M01", "M02")
			page_id = stop[1][j]
			_ink(paper.body, "arrival", i + 1)
			_archive(paper.body, [page_id])
			await _advance()
	_show("M01", "M02")
	page_id = "M07"
	var row: HBoxContainer = paper.columns(paper.body)
	Ink.workbook_print(paper.column(row), false, true)
	var captions: VBoxContainer = paper.column(row)
	_line(captions, "M07")
	_line(captions, "M08", 20)
	await _advance()
	_show("M10", "M03")
	_line(paper.body, "M11")
	await _advance()
	_show("M10", "M02")
	page_id = "M12"
	_ink(paper.body, "split", 3, true)
	_line(paper.body, "M03", 18)
	var branches: HBoxContainer = paper.columns(paper.body)
	for branch in ["M12", "M13"]:
		_line(paper.column(branches), branch)
	await _advance()


func _worktable() -> void:
	_show("M14")
	var table := _ink(paper.body, "hotel", 0, false, 212)
	if not Settings.reduced_motion:
		table.modulate.a = 0.0
		await table.create_tween().tween_property(table, "modulate:a", 1.0, 0.75).finished
	await get_tree().create_timer(0.8, false).timeout
	_line(paper.body, "M15")
	await _advance()
	await _remember(Cast.MENTOR, "M17", "hotel")
	_show("M14")
	_ink(paper.body, "hotel")
	await _advance("M18")
	await _sort_copies()
	_show("M39")
	_ink(paper.body, "sobral", 5)
	_archive(paper.body, Content.SOBRAL)
	await _advance("M44")
	_show("M14")
	_ink(paper.body, "window", 0, false, 212)
	await _advance("M45")
	await _remember(Cast.KIT, "M47", "window")
	var wrote := "M48" if _story.bond_tone == "warm" else "M49"
	var personal := "M75" if _story.bond_tone == "warm" else "M76"
	_show("M46")
	_workbook(wrote)
	await _advance("M51")
	_show("M46")
	var sheets: HBoxContainer = paper.columns(paper.body)
	var draft: VBoxContainer = paper.column(sheets)
	var workbook: VBoxContainer = paper.column(sheets)
	var outgoing: VBoxContainer = paper.column(sheets)
	_line(draft, "M86", 18)
	_line(draft, "M71")
	_line(draft, "M72")
	paper.rule(draft)
	_line(draft, "M73", 20)
	_reply_space(workbook)
	_line(outgoing, "M78", 18)
	for id in [wrote, personal, "M74"]:
		_line(outgoing, id)
	await _advance("M77")
	_story.madeira_letter_sent = true
	_show("M78")
	_line(paper.body, "M79")
	_workbook(wrote)
	await _advance()
	await _wait()


func _workbook(wrote: String) -> void:
	var pages: HBoxContainer = paper.columns(paper.body)
	var march: VBoxContainer = paper.column(pages)
	var may: VBoxContainer = paper.column(pages)
	_line(march, wrote)
	_reply_space(march)
	paper.label(may, _text.M85, 19, true)
	Ink.workbook_print(may, true)


func _reply_space(page: VBoxContainer) -> void:
	_line(page, "M50", 19)
	for i in 3:
		paper.rule(page)


func _remember(speaker: String, id: String, subject: String) -> void:
	_show("M16")
	page_id = id
	_ink(paper.body, subject, 0, false, 212)
	var ui: CanvasLayer = _director.ui
	ui.play([{"s": speaker, "t": _text[id]}])
	if speaker == Cast.KIT:
		var viewport := Ink.print_view(paper.body, Kit.instantiate(), Vector3(0, 1.57, 0),
			Vector3(0.25, 0.08, 2), 0.56)
		ui.dialogue_portrait.image.texture = viewport.get_texture()
		ui.dialogue_portrait.show()
	await ui.dialogue_done


func _sort_copies() -> void:
	var focus: String = Content.LOOSE[0]
	var correction := ""
	_routing = true
	while true:
		_board(focus, correction)
		var action: String = await paper.action
		if action == "advance":
			_routing = false
			return
		if action == "cancel" or action == selected:
			focus = selected
			selected = ""
		elif action in Content.LOOSE:
			focus = action
			selected = action
		else:
			var slots: Array = Content.COPIES[action]
			if selected not in slots:
				correction = Content.CORRECTIONS[selected]
				focus = action
				continue
			filed[selected] = action
			_last_filed = selected
			focus = ""
			var index: int = Content.LOOSE.find(selected)
			for offset in range(1, Content.LOOSE.size()):
				var candidate: String = Content.LOOSE[(index + offset) % Content.LOOSE.size()]
				if not filed.has(candidate):
					focus = candidate
					break
			selected = ""
		correction = ""


func _input(event: InputEvent) -> void:
	if get_tree().paused or _director.ui.blocks_world_input():
		return
	if _routing and not selected.is_empty() and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		paper.action.emit("cancel")
	elif paper.actions.visible:
		var down := event.is_action_pressed("ui_down", true)
		if down or event.is_action_pressed("ui_up", true):
			var scroll: ScrollContainer = paper.body.get_parent()
			scroll.scroll_vertical += 80 if down else -80
			get_viewport().set_input_as_handled()


func _board(focus: String, correction: String) -> void:
	_show("M14")
	page_id = "M20"
	_ink(paper.body, "hotel", 0, false, 126)
	var complete := filed.size() == Content.LOOSE.size()
	var columns: HBoxContainer = paper.columns(paper.body)
	var controls := {}
	if not complete:
		var tray: VBoxContainer = paper.column(columns)
		_line(tray, "M20", 19)
		for id in Content.LOOSE:
			if filed.has(id):
				continue
			var loose: Button = paper.button(tray, _text[id], id, 19)
			loose.alignment = HORIZONTAL_ALIGNMENT_LEFT
			loose.toggle_mode = true
			loose.set_pressed_no_signal(id == selected)
			controls[id] = loose
	for folder in Content.COPIES:
		var copy: VBoxContainer = paper.column(columns)
		_line(copy, "M19", 17)
		if complete:
			_line(copy, folder, 25)
		else:
			var target: Button = paper.button(copy, _text[folder], folder, 23)
			target.disabled = selected.is_empty()
			controls[folder] = target
		var ids: Array = Content.COPIES[folder]
		_line(copy, ids[0], 18)
		for id in ids.slice(1):
			var slot := Checklist.row_panel(32)
			copy.add_child(slot)
			var lines: VBoxContainer = paper.column(slot)
			paper.rule(lines)
			if filed.has(id):
				_line(lines, id, 19)
				if id == _last_filed:
					_line(lines, "M31", 17)
		for id in ["M29", "M30"]:
			_line(copy, id, 18)
	if complete:
		_line(paper.body, "M36", 22)
		_line(paper.body, "M37", 21)
		paper.advance(_text.M38)
	else:
		if not correction.is_empty():
			var layout: VBoxContainer = paper.actions.get_parent()
			_line(layout, correction, 21)
			layout.move_child(layout.get_child(-1), paper.actions.get_index())
		controls[focus].grab_focus()


func _wait() -> void:
	_show("M14")
	_ink(paper.body, "hotel")
	_line(paper.body, "M52", 18)
	_line(paper.body, "M03", 18)
	_line(paper.body, "M53")
	_line(paper.body, "M54")
	_line(paper.body, "M55", 18)
	_quote(paper.body, "M56")
	await _advance()
	_show("M14")
	_ink(paper.body, "hotel")
	_line(paper.body, "M52", 18)
	_line(paper.body, "M03", 18)
	_line(paper.body, "M57")
	await _advance()
	_show("M14", "M03")
	page_id = "M58"
	_ink(paper.body, "wait", 0, false, 212)
	_line(paper.body, "M58")
	await _advance()
	_show("M60", "M03")
	_ink(paper.body, "wait")
	_line(paper.body, "M59", 18)
	_line(paper.body, "M61")
	await _advance()
	_show("M60", "M03")
	page_id = "M62"
	_ink(paper.body, "wait")
	_line(paper.body, "M59", 18)
	_line(paper.body, "M61")
	_line(paper.body, "M62")
	_line(paper.body, "M55", 18)
	_quote(paper.body, "M63")
	await _advance("M64")


func _dockside() -> void:
	_show("M65", "M03")
	var dock := _ink(paper.body, "dock", 0, true, 212)
	_line(paper.body, "M66")
	_line(paper.body, "M67")
	var folders: HBoxContainer = paper.columns(paper.body)
	var recall: VBoxContainer = paper.column(folders)
	var aboard: VBoxContainer = paper.column(folders)
	paper.rule(recall)
	paper.rule(aboard)
	_line(recall, "M21", 19)
	_line(recall, "M68")
	_line(aboard, "M22", 19)
	_line(aboard, "M69")
	if not Settings.reduced_motion:
		await get_tree().create_timer(0.75, false).timeout
	dock.subject = "principe_folder"
	dock.last_leg = 1.0
	if not Settings.reduced_motion:
		dock.last_leg = 0.0
		await dock.create_tween().tween_property(dock, "last_leg", 1.0, 0.7).finished
	await _advance("M70")


func _passage() -> void:
	_show("I01")
	_line(paper.body, "I02", 18)
	var route := _ink(paper.body, "passage", 1, false, 124)
	for id in Content.PASSAGE:
		page_id = id
		if id == "I11":
			_archive(paper.body, [id])
		else:
			_line(paper.body, id)
			if id != "I03":
				route.steps += 1
				route.last_leg = 1.0 if Settings.reduced_motion else 0.0
				if not Settings.reduced_motion:
					route.create_tween().tween_property(route, "last_leg", 1.0, 0.65)
		await _advance("I07" if id == "I06" else "M09", true)
	page_id = "I09"
	paper.rule(paper.body)
	_line(paper.body, "I08", 18)
	_quote(paper.body, "I09")
	await _advance("I10", true)
