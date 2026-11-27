extends Node
## Documented Sobral archive. Its exercise state lives on these sheets, apart from Story.

const Content := preload("res://scripts/cambridge/content_sobral.gd")
const Madeira := preload("res://scripts/cambridge/content_madeira.gd")
const Paper := preload("res://scripts/cambridge/interlude_paper.gd")
const Ink := preload("res://scripts/cambridge/sobral_ink.gd")
const Plate := preload("res://scripts/plate_render.gd")
const Settings := preload("res://scripts/settings.gd")

const SETUP := [
	["B02", "station", ["B03"]],
	["B04", "station", ["B05", "B06", "B07", "B08"]],
	["B09", "", ["B09", "B10"]],
]
const SAMPLES := [
	["B20", "B25", "B27", "may_astro"],
	["B21", "B24", "B28", "may_aux"],
	["B22", "B26", "B29", "cloud"],
]
const TRIALS := [
	["B35", "B38", "other"],
	["B36", "B39", "july_astro"],
	["B37", "B40", "july_aux"],
]
const AUX := [Vector2(0.20, 0.25), Vector2(0.75, 0.19), Vector2(0.34, 0.43),
	Vector2(0.62, 0.56), Vector2(0.82, 0.72), Vector2(0.43, 0.79), Vector2(0.19, 0.66)]
const EXTRA := [Vector2(0.15, 0.33), Vector2(0.38, 0.18), Vector2(0.86, 0.49),
	Vector2(0.61, 0.85), Vector2(0.21, 0.85)]
const OTHER := [Vector2(0.37, 0.19), Vector2(0.47, 0.27), Vector2(0.72, 0.36),
	Vector2(0.83, 0.52), Vector2(0.71, 0.64), Vector2(0.34, 0.72), Vector2(0.22, 0.52)]

var paper: Control
var page_id := ""
var logged: Array[String] = []
var reference := ""
var scale_note := ""
var _text := Content.strings()
var _fields := {}
var _textures := {}
var _ui: CanvasLayer


func play(day: Node) -> void:
	_ui = day.ui
	_text["next"] = Madeira.strings().M09
	_text["inspect"] = L.t("查看底片")
	_text["loupe"] = L.t("放大鏡 ×2")
	_text["close"] = L.t("關閉")
	_text["flip"] = L.t("翻面")
	_text["file"] = _text.FILE
	var backdrop := ColorRect.new()
	backdrop.color = Color("30271d")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var parent: Control = _ui.pause_panel.get_parent()
	parent.add_child(backdrop)
	parent.move_child(backdrop, _ui.pause_panel.get_index())
	paper = Paper.new()
	paper.theme = _ui.theme_res
	backdrop.add_child(paper)

	for setup in SETUP:
		_show(setup[0])
		if not setup[1].is_empty():
			_picture(paper.body, setup[1], 340 if setup[0] == "B02" else 185)
		_lines(paper.body, setup[2])
		if setup[0] == "B09":
			var prints: HBoxContainer = paper.columns(paper.body)
			var corona: VBoxContainer = paper.column(prints)
			var instrument: VBoxContainer = paper.column(prints)
			_picture(corona, "corona", 155)
			_lines(corona, ["DIAGRAM", "B11"], 18)
			_picture(instrument, "mailhat", 155)
			_lines(instrument, ["MAILHAT"], 18)
		if setup[0] == "B02":
			await _ui.fade_to(0.0, 0.0 if Settings.reduced_motion else 0.7).finished
		await _next("next")

	await _sky(day.audio_tick)
	_prepare_plates()
	await _inspection()
	_show("B32")
	_picture(paper.body, "dawn", 230)
	_lines(paper.body, ["B33"])
	await _next("next")
	await _pairing()
	await _scale_check()
	# Insert I4 here, between the completed Sobral file and the existing October handoff.
	await _ui.fade_to(1.0, 0.0 if Settings.reduced_motion else 0.7).finished
	backdrop.queue_free()


func _show(id: String) -> void:
	page_id = id
	paper.begin(true)
	var scroll: ScrollContainer = paper.body.get_parent()
	var layout: VBoxContainer = scroll.get_parent()
	paper.label(layout, _text.B02 if id == "B09" else _text[id], 30)
	layout.move_child(layout.get_child(-1), 0)


func _lines(parent: Container, ids: Array, font_size := 22) -> void:
	for id in ids:
		paper.label(parent, _text[id], font_size)


func _button(parent: Container, id: String, action: String) -> Button:
	return paper.button(parent, _text[id], action, 20)


func _next(id: String) -> void:
	paper.advance(_text[id])
	while await paper.action != "advance":
		pass


func _picture(parent: Container, subject: String, height: int) -> Control:
	var picture := Ink.new()
	picture.subject = subject
	picture.custom_minimum_size.y = height
	picture.clip_contents = true
	parent.add_child(picture)
	return picture


func _sky(tick: AudioStreamPlayer) -> void:
	_show("B12")
	_picture(paper.body, "first_contact", 240)
	await _next("next")

	_show("B13")
	var horizon := _picture(paper.body, "totality", 158)
	_lines(paper.body, ["B14"], 20)
	var strips: Array[Control] = []
	for entry in [["METRONOME", "metronome"], ["B15", "astrograph"], ["B16", "four_inch"]]:
		var row: HBoxContainer = paper.columns(paper.body)
		var caption: VBoxContainer = paper.column(row)
		caption.alignment = BoxContainer.ALIGNMENT_CENTER
		_lines(caption, [entry[0]], 18)
		var strip := _picture(row, entry[1], 24)
		strip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		strips.append(strip)
	await get_tree().create_timer(0.65, false).timeout
	# Show the opening beats and the end of the two programmes in cuts.
	for beat in [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 80, 160, 240, 320]:
		for strip in strips:
			strip.beat = beat
			strip.queue_redraw()
		if beat in [0, 160, 240, 320]:
			horizon.beat = beat
			horizon.queue_redraw()
		tick.play()
		await get_tree().create_timer(0.21 if beat < 10 else 0.52, false).timeout
	await _next("B17")


func _prepare_plates() -> void:
	var astro := PackedVector2Array()
	var shifted := PackedVector2Array()
	for point: Vector2 in AUX:
		astro.append(Vector2(0.52, 0.49) + (point - Vector2(0.5, 0.5)) * 0.70)
		shifted.append(point + (point - Vector2(0.5, 0.5)).normalized() * 0.026)
	for point in EXTRA:
		astro.append(point)
	_fields = {"may_aux": PackedVector2Array(AUX), "may_astro": astro, "july_aux": shifted,
		"july_astro": astro, "other": PackedVector2Array(OTHER)}
	for id in _fields:
		var field: PackedVector2Array = _fields[id]
		var diffuse: bool = id == "may_astro"
		_textures[id] = Plate.render_check(PackedVector2Array() if diffuse else field,
			field if diffuse else PackedVector2Array())


func _glass(parent: Container, id: String, height: int, open := true, zoom := false, flip := false) -> void:
	var image := _picture(parent, "glass", height)
	image.uncovered = open
	image.magnified = zoom
	image.flipped = flip
	image.prominence = id == "cloud"
	if not image.prominence:
		image.texture = _textures[id]
		image.detail = _fields[id][2]


func _inspection() -> void:
	var selected := 0
	var opened := false
	var feedback := false
	while true:
		_show("B18")
		var spread: HBoxContainer = paper.columns(paper.body)
		var sample: VBoxContainer = paper.column(spread)
		var ledger: VBoxContainer = paper.column(spread)
		var data: Array = SAMPLES[selected]
		var views: HBoxContainer = paper.columns(sample)
		_glass(paper.column(views), data[3], 245, opened)
		if opened:
			var loupe: VBoxContainer = paper.column(views)
			_glass(loupe, data[3], 245, true, true)
			_lines(loupe, ["loupe"], 18)
		_lines(sample, [data[0]], 20)
		_lines(ledger, ["B23"])
		if opened or not logged.is_empty():
			_lines(ledger, ["B19"], 20)
		var order: Array[Button] = []
		for i in SAMPLES.size():
			var id: String = SAMPLES[i][0]
			var card := _button(ledger, id, "card%d" % i)
			card.disabled = i > 0 and not logged.has("B25")
			if card.disabled:
				var muted := card.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
				muted.bg_color = Color("d8c9ae")
				card.add_theme_stylebox_override("disabled", muted)
				card.add_theme_color_override("font_disabled_color", Color("594b3d"))
			if logged.has(SAMPLES[i][1]):
				card.text += "\n✓ " + _text[SAMPLES[i][1]]
			order.append(card)
		if opened:
			if not logged.has(data[1]):
				for id in ["B24", "B25", "B26"]:
					order.append(_button(ledger, id, id))
			if feedback:
				_lines(ledger, [data[2]], 20)
			order.append(_button(ledger, "close", "close"))
		else:
			order.append(_button(ledger, "inspect", "inspect"))
		if logged.size() == SAMPLES.size():
			_lines(paper.body, ["B30"])
			paper.advance(_text.B31)
		elif not opened or feedback:
			order.back().grab_focus()
		else:
			order[3].grab_focus()
		var action: String = await paper.action
		if action == "advance":
			return
		if action.begins_with("card"):
			selected = int(action.substr(4))
			opened = true
			feedback = false
		elif action in ["inspect", "close"]:
			opened = action == "inspect"
			feedback = false
		else:
			feedback = true
			if action == data[1]:
				logged.append(action)


func _pairing() -> void:
	var trial := -1
	var left_zoom := false
	var right_zoom := false
	var flipped := false
	while true:
		_show("B34")
		var row: HBoxContainer = paper.columns(paper.body)
		var left: VBoxContainer = paper.column(row)
		var right: VBoxContainer = paper.column(row)
		var trials: VBoxContainer = paper.column(row)
		_glass(left, "may_aux", 224, true, left_zoom)
		_lines(left, ["MAY_AUX"], 18)
		_button(left, "loupe", "left")
		var focus: Button
		if trial >= 0:
			var data: Array = TRIALS[trial]
			_glass(right, data[2], 224, true, right_zoom, (trial == 2) != flipped)
			_lines(right, [data[0]], 18)
			_button(right, "loupe", "right")
			_button(right, "flip", "flip")
			if reference.is_empty():
				_button(right, "close", "close")
			if trial < 2 or not reference.is_empty():
				_lines(trials, [data[1]], 20)
		if reference.is_empty():
			for i in TRIALS.size():
				var choice := _button(trials, TRIALS[i][0], "trial%d" % i)
				if i == maxi(trial, 0):
					focus = choice
			if trial == 2:
				focus = _button(trials, "file", "file")
			focus.grab_focus()
		else:
			_lines(paper.body, ["B41", "B42"], 20)
			paper.advance(_text.B43)
		var action: String = await paper.action
		match action:
			"advance": return
			"left": left_zoom = not left_zoom
			"right": right_zoom = not right_zoom
			"flip": flipped = not flipped
			"close":
				if reference.is_empty():
					trial = -1
			"file": reference = "B37"
			_:
				trial = int(action.substr(5))
				right_zoom = false
				flipped = false


func _scale_check() -> void:
	var feedback := false
	var left_zoom := false
	var right_zoom := false
	while true:
		var filed := not scale_note.is_empty()
		_show("B51" if filed else "B46")
		var row: HBoxContainer = paper.columns(paper.body)
		for i in 2:
			var sheet: VBoxContainer = paper.column(row)
			_glass(sheet, "may_astro" if i == 0 else "july_astro", 224,
				true, left_zoom if i == 0 else right_zoom)
			_lines(sheet, ["B44" if i == 0 else "B45"], 18)
			_button(sheet, "loupe", "left" if i == 0 else "right")
		var note: VBoxContainer = paper.column(row)
		if not filed:
			_button(note, "B47", "B47").grab_focus()
			_button(note, "B48", "B48")
		if feedback:
			_lines(note, ["B49", "B50", "HEATING"], 20)
		if filed:
			paper.rule(paper.body)
			var archive: HBoxContainer = paper.columns(paper.body)
			var auxiliary: VBoxContainer = paper.column(archive)
			_glass(auxiliary, "may_aux", 190)
			_lines(auxiliary, ["MAY_AUX"], 18)
			_lines(paper.column(archive), ["B52", "B53"], 20)
			paper.advance(_text.B54)
		match await paper.action:
			"advance": return
			"left": left_zoom = not left_zoom
			"right": right_zoom = not right_zoom
			"B47": feedback = true
			"B48":
				feedback = true
				scale_note = "B48"


func _input(event: InputEvent) -> void:
	if not is_instance_valid(paper) or get_tree().paused or _ui.blocks_world_input():
		return
	var focus := get_viewport().gui_get_focus_owner()
	if focus == null or not paper.actions.is_ancestor_of(focus):
		return
	var down := event.is_action_pressed("ui_down", true)
	if down or event.is_action_pressed("ui_up", true):
		var scroll: ScrollContainer = paper.body.get_parent()
		scroll.scroll_vertical += 80 if down else -80
		get_viewport().set_input_as_handled()
